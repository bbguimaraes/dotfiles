#!/usr/bin/env python3
import subprocess
import sys

RESOLUTION = "1920x1080"
RATE = "60"

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
    workspaces
""", end='', file=sys.stderr)
    return 1

def cmd_list(*args):
    if args:
        return usage()
    for x in list_displays():
        print(x["name"], end='')
        if x.get("active"):
            print(" active", end='')
        if x["primary"]:
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

def cmd_workspaces():
    primary, secondary, _ = set_common()
    workspaces(primary, secondary)

def list_displays():
    out = subprocess.check_output(("xrandr", "--query"))
    ret, cur = [], {}
    for line in out.splitlines():
        line = line.decode("utf-8")
        f = line.split()
        if f[1] == "connected":
            if cur:
                ret.append(cur)
            cur = {"name": f[0], "primary": f[2] == "primary"}
        elif "*" in line:
            cur["active"] = True
    if cur:
        ret.append(cur)
    return ret

def set_common():
    active, secondary = 0, {}
    for x in list_displays():
        if x.get("active"):
            active += 1
        if x["primary"]:
            primary = x
        else:
            secondary = x
    return primary["name"], secondary.get("name", ""), active

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
    return any(map(exec_cmd, (
        ("i3-msg", "workspace", "1"),
        ("i3-msg", "move", "workspace", "to", "output", primary),
        ("i3-msg", "workspace", "2"),
        ("i3-msg", "move", "workspace", "to", "output", primary),
        ("i3-msg", "workspace", "3"),
        ("i3-msg", "move", "workspace", "to", "output", secondary),
        ("i3-msg", "workspace", "4"),
        ("i3-msg", "move", "workspace", "to", "output", primary),
        ("i3-msg", "workspace", "4"),
        ("i3-msg", "workspace", "1"),
    ))) or None

def exec_cmd(*args):
    out = subprocess.run(*args)
    if out.returncode != 0:
        print(
            f"command {args} failed with status {out.returncode}",
            file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:]))
