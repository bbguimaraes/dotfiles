#!/usr/bin/env python3
import dataclasses
import json
import os
import socket
import subprocess
import sys
from typing import List

RESOLUTION = "1920x1080"
RATE = "60"

MSG_RUN_COMMAND = 0
MSG_GET_WORKSPACES = 1

@dataclasses.dataclass
class Display:
    name: str = ""
    active: bool = False
    primary: bool = False

def main(*args):
    if not args:
        return usage()
    cmd, *args = args
    if cmd == "list":
        return cmd_list(*args)
    elif cmd == "toggle":
        return cmd_toggle(*args)
    elif cmd == "single":
        return cmd_single(*args)
    elif cmd == "dual":
        return cmd_dual(*args)
    elif cmd == "mirror":
        return cmd_mirror(*args)
    elif cmd == "tv":
        return cmd_tv(*args)
    elif cmd == "120hz":
        return cmd_120hz(*args)
    elif cmd == "4k":
        return cmd_4k(*args)
    elif cmd == "swap":
        return cmd_swap(*args)
    elif cmd == "workspaces":
        return cmd_workspaces(*args)
    else:
        return usage()

def usage():
    print(f"""\
Usage: {sys.argv[0]} CMD ARG...

Commands:

    list
    single|dual|mirror|tv|120hz|4k
    toggle
    swap
    workspaces
""", end='', file=sys.stderr)
    return 1

def create_ipc_socket():
    s = socket.socket(socket.AF_UNIX)
    s.connect(os.environ["I3SOCK"])
    return s

def send_msg(s, t, m=None):
    o = sys.byteorder
    n = len(m) if m is not None else 0
    l = [b"i3-ipc", n.to_bytes(4, o), t.to_bytes(4, o)]
    if m is not None:
        l.append(m)
    s.send(b"".join(l))

def recv_msg(s, t):
    o = sys.byteorder
    m = s.recv(6)
    assert m == b"i3-ipc"
    m = s.recv(4)
    n = int.from_bytes(m, o)
    m = s.recv(4)
    assert int.from_bytes(m, o) == t
    return json.loads(s.recv(n))

def send_cmd(s, m):
    send_msg(s, MSG_RUN_COMMAND, m)
    j = recv_msg(s, MSG_RUN_COMMAND)
    for x in j:
        assert x["success"]

def cmd_list(*args):
    if args:
        return usage()
    for x in list_displays():
        print(x.name, end='')
        if x.active:
            print(" active", end='')
        if x.primary:
            print(" primary", end='')
        print()

def cmd_toggle(*args):
    if args:
        return usage()
    primary, secondary, active = set_common()
    if active == 1:
        dual(secondary, primary, "--mode", RESOLUTION, "--rate", RATE)
        workspaces(secondary, primary)
    else:
        single(secondary, primary)

def cmd_single():
    primary, secondary, _ = set_common()
    single(secondary, primary)

def cmd_dual():
    primary, secondary, _ = set_common()
    dual(secondary, primary, "--mode", RESOLUTION, "--rate", RATE)

def cmd_mirror():
    primary, secondary, active = set_common()
    if active == 2:
        return
    primary, secondary = secondary, primary
    return exec_cmd(
        "xrandr",
        "--output", primary, "--auto", "--primary",
            "--mode", RESOLUTION, "--rate", RATE,
        "--output", secondary, "--auto", "--same-as", primary,
    )

def cmd_tv():
    primary, secondary, active = set_common()
    if active == 2:
        return
    return single(secondary, primary, "--mode", RESOLUTION, "--rate", RATE)

def cmd_120hz():
    primary, secondary, active = set_common()
    if active == 2:
        return
    return single(secondary, primary, "--mode", RESOLUTION, "--rate", "120")

def cmd_4k():
    primary, secondary, active = set_common()
    if active == 2:
        return
    return single(secondary, primary, "--mode", "4096x2160")

def cmd_swap(*args):
    if args:
        return usage()
    s = create_ipc_socket()
    send_msg(s, MSG_GET_WORKSPACES)
    l = recv_msg(s, MSG_GET_WORKSPACES)
    cmd = []
    for w in l:
        cmd.append(f"workspace {w['num']}".encode())
        cmd.append(b"move workspace to output next")
    for w in l:
        if w["visible"]:
            cmd.append(f"workspace {w['num']}".encode())
            break
    send_cmd(s, b"; ".join(cmd))

def cmd_workspaces(*args):
    if args:
        return usage()
    primary, secondary, _ = set_common()
    workspaces(primary, secondary)

def list_displays() -> List[Display]:
    out = subprocess.check_output(("xrandr", "--query"))
    ret, cur = [], Display()
    for line in out.splitlines():
        line = line.decode("utf-8")
        f = line.split()
        if f[1] == "connected":
            if cur.name:
                ret.append(cur)
            cur = Display()
            cur.name = f[0]
            cur.primary = f[2] == "primary"
        elif "*" in line:
            cur.active = True
    if cur:
        ret.append(cur)
    return ret

def set_common():
    active, secondary = 0, {}
    for x in list_displays():
        if x.active:
            active += 1
        if x.primary:
            primary = x
        else:
            secondary = x
    return primary.name, secondary.name, active

def single(primary, secondary, *args):
    return exec_cmd((
        "xrandr",
        "--output", secondary, "--off",
        "--output", primary, "--auto", "--primary",
        *args,
    ))

def dual(primary, secondary, *args):
    return exec_cmd((
        "xrandr",
        "--output", secondary, "--auto",
        "--output", primary, "--auto", "--primary", "--above", secondary,
        *args,
    ))

def workspaces(primary, secondary):
    s = create_ipc_socket()
    send_msg(s, MSG_GET_WORKSPACES)
    l = sorted(
        recv_msg(s, MSG_GET_WORKSPACES),
        key=lambda x: int(x["num"]))
    l.pop()
    cmd = []
    for w in l[:-1]:
        if w["output"] == primary:
            continue
        cmd.append(f"workspace {w['num']}".encode())
        cmd.append(f"move workspace to output {primary}".encode())
    for w in l:
        if w["visible"]:
            cmd.append(f"workspace {w['num']}".encode())
            break
    w = l[-1]
    if w["output"] != secondary:
        cmd.append(f"workspace {w['num']}".encode())
        cmd.append(f"move workspace to output {secondary}".encode())
    send_cmd(s, b"; ".join(cmd))

def exec_cmd(*args):
    out = subprocess.run(*args)
    if out.returncode != 0:
        print(
            f"command {args} failed with status {out.returncode}",
            file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:]))
