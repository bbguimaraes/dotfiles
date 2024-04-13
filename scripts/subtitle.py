#!/usr/bin/env python3
import datetime
import re
import sys

def main(*args):
    if not args:
        return usage()
    cmd, *args = args
    if cmd == "adj":
        return cmd_adj(*args)
    return usage()

def usage():
    print(f"""\
Usage: {sys.argv[0]} CMD ARG...

Commands:

    offset ADJ
""", end='', file=sys.stderr)
    return 1

def cmd_adj(*args):
    if len(args) != 1:
        return usage()
    adj = float(args[0])
    id_re = re.compile(r"^\d+$")
    time_re = re.compile("^{0} --> {0}$".format(r"(\d{2}:\d{2}:\d{2},\d{3})"))
    i = iter(sys.stdin)
    while True:
        copy_id(id_re, i)
        line = next(i)
        m = time_re.match(line)
        if not m:
            print(f"invalid line: {line}", end='', file=sys.stderr)
            return 1
        groups = m.groups()
        print(adj_time(adj, groups[0]), "-->", adj_time(adj, groups[1]))
        if not copy_content(i):
            break

def adj_time(adj, s):
    t = datetime.time.fromisoformat(s)
    t = datetime.datetime(
        year=1, month=1, day=1,
        hour=t.hour, minute=t.minute, second=t.second,
        microsecond=t.microsecond)
    t += datetime.timedelta(seconds=adj)
    return "{:02}:{:02}:{:02},{:03}".format(
        t.hour, t.minute, t.second, int(t.microsecond / 1000))

def copy_id(r, i):
    line = next(i)
    if not r.match(line):
        print(f"invalid line: {line}", end='', file=sys.stderr)
        return 1
    print(line, end='')

def copy_content(i):
    line = next(i, None)
    while line is not None:
        print(line, end='')
        if line == "\n":
            return True
        line = next(i, None)
    return False

if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:]))
