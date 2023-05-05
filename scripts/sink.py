#!/usr/bin/env python3
import itertools
import json
import operator
import subprocess
import sys

class card(object):
    __slots__ = ("index", "description", "profiles", "ports")
    def __init__(self, index, description, profiles, ports):
        self.index, self.description, self.profiles, self.ports = \
            index, description, profiles, ports

class port(object):
    __slots__ = ("name", "description", "profiles")
    def __init__(self, name, description, profiles):
        self.name, self.description, self.profiles = name, description, profiles

class sink(object):
    __slots__ = ("index", "name", "description", "ports")
    def __init__(self, index, name, description, ports):
        self.index, self.name, self.description, self.ports = \
            index, name, description, ports

def main(*args):
    if not args:
        return usage()
    cmd, *args = args
    if cmd == "menu":
        return cmd_menu(*args)
    elif cmd == "set":
        return cmd_set(*args)
    else:
        return usage()

def usage():
    print(f"""\
Usage: {sys.argv[0]} CMD [ARGS...]

Commands:

    menu
    set NAME
""", end='', file=sys.stderr)
    return 1

def cmd_menu(*args):
    if args:
        return usage()
    info = list_all()
    card, profile = select_card(info["cards"])
    if not card:
        return
    pactl("set-card-profile", card.index, profile)
    info = list_all()
    sink, port = select_sink(info, card, profile)
    if not sink:
        return
    pactl("set-sink-port", sink, port)
    set_sink(sink, port, info["sink_inputs"])

def cmd_set(*args):
    if len(args) != 1:
        return usage
    name = args[0]
    info = list_all()
    for sink in info["sinks"]:
        if name in sink.name:
            set_sink(sink.index, info["sink_inputs"])
            return
    print(f'sink "{name}" not found', file=sys.stderr)

def list_all():
    j = json.loads(pactl("--format", "json", "list"))
    return {
        "cards": load_cards(j["cards"]),
        "sinks": load_sinks(j["sinks"]),
        "sink_inputs": load_sink_inputs(j["sink_inputs"]),
    }

def load_cards(j):
    return [
        card(
            index=j["index"],
            description=j["properties"]["device.description"],
            profiles=tuple(j["profiles"].keys()),
            ports=load_ports(j),
        )
        for j in j
    ]

def load_ports(j):
    profiles = set(j["profiles"].keys())
    ports = []
    for k, v in j["ports"].items():
        if v["availability"] == "not available":
            continue
        if p := {x for x in v["profiles"] if x in profiles}:
            ports.append(port(
                name=k,
                description=v["description"],
                profiles=list(sorted(p))))
    return ports

def load_sinks(j):
    return [
        sink(
            index=j["index"],
            name=j["name"],
            description=j["description"],
            ports=load_sink_ports(j["ports"]),
        )
        for j in j
    ]

def load_sink_ports(j):
    return [
        port(name=j["name"], description=j["description"], profiles=None)
        for j in j
    ]

def load_sink_inputs(j):
    return [j["index"] for j in j]

def select_card(cards):
    out = dmenu([
        " | ".join((str(card.index), card.description, profile))
        for card in cards for profile in card.profiles
    ])
    if not out:
        return None, None
    card, _, profile = out.rstrip().split(" | ")
    card = int(card)
    card = next(x for x in cards if x.index == card)
    return card, profile

def select_sink(info, card, profile):
    out = dmenu([
        " | ".join((str(sink.index), port.name, sink.description))
        for sink, port in itertools.product(info["sinks"], card.ports)
        if profile in port.profiles
            and any(x.name == port.name for x in sink.ports)
    ])
    if not out:
        return None, None
    sink, port, _ = out.rstrip().split(" | ")
    return sink, port

def set_sink(sink, inputs):
    pactl("set-default-sink", sink)
    for x in inputs:
        pactl("move-sink-input", x, sink)

def pactl(*args):
    return subprocess.check_output(("pactl", *map(str, args)))

def dmenu(lines):
    cmd = ("dmenu", "-l", str(len(lines)))
    out = subprocess.run(
        cmd,
        input="\n".join(lines),
        text=True,
        capture_output=True)
    if c := out.returncode:
        if stderr := out.stderr:
            raise subprocess.CalledProcessError(c, cmd, out.stdout, out.stderr)
    else:
        return out.stdout

if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:]))
