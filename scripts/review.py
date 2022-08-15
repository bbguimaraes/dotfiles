#!/usr/bin/env python3
import argparse
import contextlib
import os
import subprocess
import sys


@contextlib.contextmanager
def chdir(path):
    cur = os.path.abspath(os.curdir)
    os.chdir(path)
    yield
    os.chdir(cur)


@contextlib.contextmanager
def git_worktree(path, ref):
    git('worktree', 'add', path, ref)
    with chdir(path):
        yield
    git('worktree', 'remove', path)


def main():
    args = parse_args()
    args.f(args)


def parse_args():
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(metavar='cmd', required=True)
    pr_parser = sub.add_parser('pr')
    pr_parser.set_defaults(f=cmd_pr)
    pr_parser.add_argument('pr', type=int)
    pull_parser = sub.add_parser('pull')
    pull_parser.set_defaults(f=cmd_pull)
    pull_parser.add_argument('pr', type=int)
    end_parser = sub.add_parser('end')
    end_parser.set_defaults(f=cmd_end)
    end_parser.add_argument('pr', type=int)
    diff_parser = sub.add_parser('diff')
    diff_parser.set_defaults(f=cmd_diff)
    diff_parser.add_argument('git_args', nargs='*')
    return parser.parse_args()


def git(*args):
    subprocess.check_call(('git', *args))
def git_output(*args):
    return subprocess.check_output(('git', *args))
def pull(pr):
    branch = f'pull_{pr}'
    git('fetch', '--force', 'upstream', f'refs/pull/{pr}/merge:{branch}')
    return branch


def cmd_pr(args):
    pr = args.pr
    path = os.path.join(os.environ.get('TMPDIR', '/tmp'), f'pull_{pr}')
    with git_worktree(path, pull(pr)):
        if not cmd_diff(args):
            return False
    return cmd_end(args)


def cmd_pull(args):
    git('checkout', '--quiet', pull(args.pr))
    return True


def cmd_end(args):
    cur = git_output('rev-parse', '--abbrev-ref', 'HEAD') \
        .decode('utf-8').rstrip()
    if cur == f'pull_{args.pr}':
        git('checkout', '--quiet', 'master')
    git('branch', '-D', 'pull_' + str(args.pr))
    return True


def cmd_diff(args):
    return subprocess.call((
        'vim', '-p', '-c',
        'tabdo ' + ' | '.join((
            r'vnew +.!git\ show\ HEAD^:#',
            r'silent file [git] HEAD^:#',
            r'windo set diff scrollbind foldmethod=diff')),
        *git_output(
                'diff', '--name-only', '--diff-filter=ADM', 'HEAD^', '--',
                *getattr(args, 'git_args', ())) \
            .splitlines())) == 0


if __name__ == '__main__':
    sys.exit(main())
