#!/bin/env python3
import argparse
import matplotlib
import matplotlib.pyplot
import os
import subprocess
import sys
import time


def main(build_dir, *args):
    args = parse_args(args)
    objects = find_objects()
    times, err = build(args, objects)
    if err:
        return err
    if args.verbose > 0:
        for (t, l) in zip(times, objects):
            print(f'{t} {l}', file=sys.stderr)
    plot(times, objects)


def parse_args(args):
    parser = argparse.ArgumentParser()
    parser.add_argument('-v', '--verbose', action='count', default=0)
    parser.add_argument('build_dir', type=str)
    parser.add_argument('make_args', type=str, nargs='*')
    return parser.parse_args(args)


def find_objects():
    return [
        os.path.join(root, f.replace('.cpp', '.o'))
        for root, _, files in os.walk('src')
        for f in files
        if f.endswith('.cpp')]


def build(args, objects):
    n = len(objects)
    ret = []
    for i, x in enumerate(objects):
        start = time.time()
        cmd = ('make', '-C', args.build_dir, *args.make_args, x)
        stdout, stderr = None, None
        if args.verbose > 0:
            print(f'[{i}/{n} {i * 100 // n}%]', ' '.join(cmd), file=sys.stderr)
        if args.verbose < 2:
            stdout = subprocess.PIPE
        proc = subprocess.run(cmd, stdout=stdout, stderr=subprocess.STDOUT)
        if proc.returncode:
            if args.verbose < 2:
                print(proc.stdout, file=sys.stderr)
            return None, proc.returncode
        ret.append(time.time() - start)
    return ret, None


def plot(times, labels):
    n = len(times)
    assert n == len(labels)
    max_len = max(map(len, labels))
    total = sum(times)
    times, labels = zip(
        *sorted(zip(times, labels), reverse=True, key=lambda x: x[0]))
    matplotlib.use('svg')
    matplotlib.pyplot.rcParams.update({'figure.autolayout': True})
    fig = matplotlib.pyplot.figure(figsize=(16, n / 5))
    ax = matplotlib.pyplot.subplot2grid((1, 5), (0, 0), colspan=2)
    ax.barh(labels, times)
    ax.set_xlabel('time (s)')
    ax.margins(x=.01, y=.005)
    ax.yaxis.set_tick_params(pad=max_len * 5)
    for x in ax.yaxis.get_major_ticks():
        x.label1.set_horizontalalignment('left')
    filtered = list(filter(lambda x: x[0] / total > .01, zip(times, labels)))
    if filtered:
        times, labels = zip(*filtered)
    ax = matplotlib.pyplot.subplot2grid((1, 5), (0, 2), colspan=3)
    ax.pie(
        times, labels=labels,
        autopct='%.1f%%', pctdistance=.9, rotatelabels=True)
    matplotlib.pyplot.savefig(sys.stdout)


if __name__ == '__main__':
    sys.exit(main(*sys.argv))
