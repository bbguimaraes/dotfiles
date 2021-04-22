#!/bin/env python3
import collections
import itertools
import os
import subprocess
import sys
import tempfile
import time

Test = collections.namedtuple('Test', (
    'name', 'configure', 'compiler', 'linker', 'target', 'flags', 'cxxflags'))
Result = collections.namedtuple('Result', ('code', 'time'))

SANITIZERS = (
    'address', 'leak', 'undefined',
    'pointer-compare', 'pointer-subtract',
)

CXXFLAGS = (
    '-D_GLIBCXX_SANITIZE_VECTOR',
    '-fsanitize-address-use-after-scope',
    '-fstack-protector',
    '-Wno-stack-protector',
    '-fsanitize=' + ','.join(SANITIZERS),
)

DEBUG_FLAGS = ('-O0', '-g', '-UNDEBUG')
RELEASE_FLAGS = ()

ENV = {
    'V': '0',
#    'ASAN_OPTIONS': ','.join((
#        'detect_invalid_pointer_pairs=1',
#        'detect_stack_use_after_return=1',
#    )),
}

# The ICD loader and the sanitizers do not work together.
CONFIGURE_ARGS = ('--', '--without-opencl')
DEBUG_CXXFLAGS=('-O0', '-UNDEBUG', '-Wnull-dereference', )

CHECKS = {
    'gcc': Test(
        name='gcc debug',
        configure=CONFIGURE_ARGS,
        compiler='g++', linker=None, target='check',
        flags=(), cxxflags=DEBUG_CXXFLAGS),
    'clang': Test(
        name='clang debug',
        configure=CONFIGURE_ARGS,
        compiler='clang++', linker=None, target='check',
        flags=(), cxxflags=DEBUG_CXXFLAGS),
    'gcc_32': Test(
        name='gcc debug',
        configure=CONFIGURE_ARGS,
        compiler='g++', linker='true', target='nngn',
        flags=(), cxxflags=(*DEBUG_CXXFLAGS, '-m32')),
    'clang_32': Test(
        name='clang debug',
        configure=CONFIGURE_ARGS,
        compiler='clang++', linker='true', target='nngn',
        flags=(), cxxflags=(*DEBUG_CXXFLAGS, '-m32')),
    'gcc_no_vma': Test(
        name='gcc debug',
        configure=(*CONFIGURE_ARGS, '--without-vma'),
        compiler='g++', linker=None, target='check',
        flags=(), cxxflags=DEBUG_CXXFLAGS),
    'gcc_32_no_vma': Test(
        name='gcc debug',
        configure=(*CONFIGURE_ARGS, '--without-vma'),
        compiler='g++', linker='true', target='nngn',
        flags=(), cxxflags=(*DEBUG_CXXFLAGS, '-m32')),
    'gcc_debug': Test(
        name='gcc debug (no sanitizers)', configure=None,
        compiler='g++', linker=None, target='check',
        flags=(), cxxflags=DEBUG_CXXFLAGS),
    'gcc_release': Test(
        name='gcc release',
        configure=CONFIGURE_ARGS,
        compiler='g++', linker=None, target='check', flags=(), cxxflags=None),
    'distcheck': Test(
        name='distcheck', configure=CONFIGURE_ARGS,
        compiler='g++', linker=None, target='distcheck',
        flags=(
            'DISTCHECK_CONFIGURE_FLAGS=' + ' '.join((
                '--enable-tests', '--enable-benchmarks', '--enable-tools',
                '--with-opengl', '--with-vulkan', '--with-libpng',
                '--with-freetype2', '--with-opencl',
                'CXXFLAGS=' + r'\ '.join(DEBUG_CXXFLAGS))),
        ), cxxflags=None),
    'tidy': Test(
        name='tidy', configure=None,
        compiler=None, linker=None, target='tidy',
        flags=('--keep-going',), cxxflags=None),
    'wasm': Test(
        name='wasm', configure=('wasm', '--'),
        compiler=None, linker=None, target='nngn.js', flags=(), cxxflags=None)
}

def main(*args):
    dir, checks, args = parse_args(args)
    if not dir:
        return usage()
    if not validate_checks(checks):
        return 1
    if not checks:
        checks = list(CHECKS)
    results = exec_checks(dir, checks, args)
    if not print_summary(checks, results):
        return 1

def parse_args(args):
    i = iter(args)
    dir = next(i, None)
    checks = list(itertools.takewhile(lambda x: x != '--', i))
    args = list(i)
    return dir, checks, args

def usage():
    print('Usage:', sys.argv[0], '<dir> [<checks...]', file=sys.stderr)
    return 1

def validate_checks(names):
    invalid = set(names) - set(CHECKS)
    if invalid:
        print('invalid checks:', ','.join(invalid), file=sys.stderr)
        return False
    return True

def exec_checks(dir, names, args):
    ret = []
    with tempfile.TemporaryDirectory() as tmp:
        env = setup_env(tmp)
        for name in names:
            check = CHECKS[name]
            print(check.name)
            test_dir = os.path.join(dir, name)
            os.makedirs(test_dir, exist_ok=True)
            configure(test_dir, check.configure, check.cxxflags)
            cxx = (f'CXX=ccache {check.compiler}',) if check.compiler else ()
            ld = (f'CXXLD={check.linker}',) if check.linker else ()
            ret.append(exec((
                'make', '-C', test_dir, *cxx, *ld,
                check.target, *check.flags, *args,
            ), env=env))
    return ret

def setup_env(tmp):
    lsan = os.path.join(tmp, 'leak_suppressions.txt')
    with open(lsan, 'w') as f:
        f.write('leak:_dri.so\n')
    ret = dict(ENV)
    ret['LSAN_OPTIONS'] = 'suppressions=' + lsan
    ret.update(os.environ)
    return ret

def configure(dir, args, cxxflags):
    if os.path.exists(os.path.join(dir, 'Makefile')):
        return
    args = list(args or [])
    if '--' not in args:
        args.append('--')
    if cxxflags:
        args.append('CXXFLAGS=' + ' '.join(cxxflags))
    subprocess.check_call(('d', 'nngn', 'configure', dir, *args))

def exec(cmd, *args, **kwargs):
    print(*cmd)
    start = time.perf_counter()
    res = subprocess.call(cmd, *args, **kwargs)
    end = time.perf_counter()
    return Result(code=res, time=end - start)

def print_summary(names, results):
    if os.isatty(sys.stdout.fileno()):
        color_red, color_green, color_reset = \
            '\x1b[31m', '\x1b[32m', '\x1b[m\x0f'
    else:
        color_red, color_green, color_reset = '', '', ''
    ret = all(x.code == 0 for x in results)
    name_width = max(map(len, names)) + 1
    result_width = 2 if ret else 6
    assert(len(names) == len(results))
    fmt_result = (
        '{}failed{}'.format(color_red, color_reset),
        '{}ok{}'.format(color_green, color_reset),
    )
    fmt = lambda n, r, t: '{:{}} {:<{}} ({})'.format(
        n + ':', name_width, fmt_result[r], result_width, fmt_time(t))
    print()
    for name, result in zip(names, results):
        print(fmt(name, result.code == 0, result.time))
    print(fmt('all', ret, sum(x.time for x in results)))
    return ret

def fmt_time(t):
    t, s = t / 60, t % 60
    h, m = t / 60, t % 60
    return f'{int(h)}:{int(m):02}:{int(s):02}'

if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))
