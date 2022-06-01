#!/usr/bin/env python3
import csv
import html
import sys
import urllib.parse

def main(*args):
    if next(iter(args), None) not in ("csv", "html", "unicode", "url"):
        return usage()
    cmd, *args = args
    if args == []:
        return globals()[cmd + "_escape"]()
    elif args == ["-u"]:
        return globals()[cmd + "_unescape"]()
    return usage()

def csv_escape():
    csv.writer(sys.stdout).writerows(map(str.split, sys.stdin))

def csv_unescape():
    with open("/dev/stdin", newline='') as f:
        for _ in map(print, map(" ".join, csv.reader(f))): pass

def html_escape():
    sys.stdout.write(html.escape(sys.stdin.read()))

def html_unescape():
    sys.stdout.write(html.unescape(sys.stdin.read()))

def unicode_escape():
    sys.stdout.buffer.write(sys.stdin.read().encode("unicode_escape"))

def unicode_unescape():
    sys.stdout.writelines(x.decode("unicode_escape") for x in sys.stdin.buffer)

def url_escape():
    sys.stdout.write(urllib.parse.quote(sys.stdin.buffer.read()))

def url_unescape():
    sys.stdout.write(urllib.parse.unquote(sys.stdin.buffer.read()))

def usage():
    print("Usage:", sys.argv[0], "CMD [-u]", file=sys.stderr)
    print("""
Commands:
    csv
    html
    unicode
    url\
""", file=sys.stderr)
    return 1

if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:]))
