#!/bin/env python3
import collections
import itertools
import os
import subprocess
import sys
import tempfile
import time
from typing import Dict, List

Check = collections.namedtuple("Check", (
    "name", "configure", "configure_args", "compiler", "linker",
    "target", "cxxflags", "ldflags", "libs", "env", "make_args",
    "setup"))
Result = collections.namedtuple("Result", ("code", "time"))
CHECK_DEFAULT = {k: None for k in Check._fields}
def make_check(d: dict): return Check(**(CHECK_DEFAULT | d))

HOME = os.environ["HOME"]

SANITIZERS = (
    "address", "leak", "undefined",
    "pointer-compare", "pointer-subtract",
)

CXXFLAGS = ("-g3", "-gdwarf-4")
DEBUG_CXXFLAGS=("-O0", "-UNDEBUG", "-Wnull-dereference", "-Wnonnull")
SANITIZERS_CXXFLAGS = (
    *CXXFLAGS,
    "-D_GLIBCXX_SANITIZE_VECTOR",
    "-fsanitize-address-use-after-scope",
    "-fstack-protector",
    "-Wno-stack-protector",
    "-fsanitize=" + ",".join(SANITIZERS),
)
LINUX_LDFLAGS = (
    "-fuse-ld=gold",
    "-Wl,--threads,--preread-archive-symbols",
)

MINGW = "x86_64-w64-mingw32"
def MINGW_SETUP(d: str):
    if not os.path.exists(os.path.join(d, "mingw")):
        subprocess.check_call(
            ("scripts/src_build.sh", "mingw", d),
            env=os.environ | {"CC": f"{MINGW}-cc"})

def WASM_SETUP(d: str):
    if not os.path.lexists("nngn.js"):
        os.symlink(os.path.join(d, "nngn.js"), "nngn.js")
    if not os.path.lexists("nngn.wasm"):
        os.symlink(os.path.join(d, "nngn.wasm"), "nngn.wasm")
    if not os.path.exists(os.path.join(d, "emscripten")):
        subprocess.check_call(("scripts/src_build.sh", "emscripten", d))

ENV = {
    "V": "0",
#    "ASAN_OPTIONS": ",".join((
#        "detect_invalid_pointer_pairs=1",
#        "detect_stack_use_after_return=1",
#    )),
}

CONFIGURE_ARGS = (
    "--enable-tests",
    "--enable-benchmarks",
    "--enable-tools",
    "--enable-lua-alloc",
    "--with-opengl",
    "--with-vulkan",
    "--with-libpng",
    "--with-freetype2",
    # The ICD loader and the sanitizers do not work together.
    #"--with-opencl",
)

CHECKS = {
    "gcc": {
        "name": "GCC debug",
        "compiler": "g++",
        "target": "check",
        "cxxflags": (*SANITIZERS_CXXFLAGS, *DEBUG_CXXFLAGS),
        "ldflags": LINUX_LDFLAGS,
    },
    "clang": {
        "name": "Clang debug",
        "compiler": "clang++",
        "target": "check",
        "cxxflags": (*SANITIZERS_CXXFLAGS, *DEBUG_CXXFLAGS),
        "ldflags": LINUX_LDFLAGS,
    },
    "gcc_32": {
        "name": "GCC debug (32-bit)",
        "compiler": "g++",
        "linker": "true",
        "cxxflags": (*(*SANITIZERS_CXXFLAGS, *DEBUG_CXXFLAGS), "-m32"),
        "ldflags": LINUX_LDFLAGS,
    },
    "clang_32": {
        "name": "Clang debug (32-bit)",
        "compiler": "clang++",
        "linker": "true",
        "cxxflags": (*SANITIZERS_CXXFLAGS, *DEBUG_CXXFLAGS, "-m32"),
        "ldflags": LINUX_LDFLAGS,
    },
    "gcc_no_vma": {
        "name": "GCC debug (no VMA)",
        "configure_args": ("--without-vma",),
        "compiler": "g++",
        "target": "check",
        "cxxflags": (*SANITIZERS_CXXFLAGS, *DEBUG_CXXFLAGS),
        "ldflags": LINUX_LDFLAGS,
    },
    "gcc_32_no_vma": {
        "name": "GCC debug (32-bit, no VMA)",
        "configure_args": ("--without-vma",),
        "compiler": "g++",
        "linker": "true",
        "cxxflags": (*SANITIZERS_CXXFLAGS, *DEBUG_CXXFLAGS, "-m32"),
        "ldflags": LINUX_LDFLAGS,
    },
    "gcc_debug": {
        "name": "GCC debug (no sanitizers)",
        "configure_args": (*CONFIGURE_ARGS, "--with-opencl"),
        "compiler": "g++",
        "target": "check",
        "cxxflags": (*CXXFLAGS, *DEBUG_CXXFLAGS),
        "ldflags": LINUX_LDFLAGS,
    },
    "gcc_release": {
        "name": "GCC release",
        "compiler": "g++",
        "target": "check",
        "ldflags": LINUX_LDFLAGS,
    },
    "elysian": {
        "name": "GCC (ElysianLua)",
        "cxxflags": (
            *SANITIZERS_CXXFLAGS, *DEBUG_CXXFLAGS,
            "-isystem", f"{HOME}/src/es/ElysianLua/lib/api"),
        "ldflags": (
            *LINUX_LDFLAGS,
            "-L", f"{HOME}/src/es/ElysianLua/build/lib",
        ),
        "libs": ("-llibElysianLua",),
    },
    "mingw": {
        "name": "MinGW",
        "setup": MINGW_SETUP,
        "configure_args": ("--build=x86_64-pc-linux-gnu", f"--host={MINGW}"),
        "cxxflags": (*DEBUG_CXXFLAGS, "-isystem", "mingw/include"),
        "ldflags": ("-L", "mingw/lib"),
    },
    "mingw_release": {
        "name": "MinGW release",
        "setup": MINGW_SETUP,
        "configure_args": ("--build=x86_64-pc-linux-gnu", f"--host={MINGW}"),
        "cxxflags": (*DEBUG_CXXFLAGS, "-isystem", "mingw/include"),
        "ldflags": ("-L", "mingw/lib"),
    },
    "distcheck": {
        "name": "distcheck",
        "compiler": "g++",
        "target": "distcheck",
        "make_args": (
            "DISTCHECK_CONFIGURE_FLAGS=" + " ".join((
                "--enable-tests", "--enable-benchmarks", "--enable-tools",
                "--with-opengl", "--with-vulkan", "--with-libpng",
                "--with-freetype2", "--with-opencl",
            )),
        ),
    },
    "tidy": {
        "name": "tidy",
        "target": "tidy",
        "make_args": ("--keep-going",),
    },
    "wasm": {
        "name": "Web Assembly",
        "setup": WASM_SETUP,
        "configure": ("emconfigure",),
        "configure_args": (
            "--disable-benchmarks",
            "--disable-tools",
            "--disable-tests",
            "--without-opencl",
            "--without-vulkan",
            "PKG_CONFIG_LIBDIR=" + os.path.join(
                os.path.abspath(os.curdir),
                "scripts/emscripten/pkgconfig"),
        ),
        "cxxflags": (
            "-g0", "-isystem emscripten/include", "-Wno-old-style-cast"),
        "ldflags": ("-L", "emscripten/lib"),
    },
}

def main(*args):
    args = parse_args(args)
    if not args:
        return usage()
    cmd, dir, *args = args
    return cmd(dir, *args)

def parse_args(args):
    if not args:
        return
    i = iter(args)
    cmd = next(i)
    if cmd == "configure":
        dir = next(i, None)
        checks = list(itertools.takewhile(lambda x: x != "--", i))
        return cmd_configure, dir, checks, list(i)
    if cmd == "check":
        dir = next(i, None)
        checks = list(itertools.takewhile(lambda x: x != "--", i))
        return cmd_check, dir, checks, list(i)

def usage():
    print("Usage:", sys.argv[0], "<dir> [<checks...]", file=sys.stderr)
    return 1

def validate_checks(names):
    invalid = set(names) - set(CHECKS)
    if invalid:
        print("invalid checks:", ",".join(invalid), file=sys.stderr)
        return False
    return True

def cmd_configure(dir, names, args):
    if not names:
        names = list(CHECKS)
    elif not validate_checks(names):
        return 1
    for i, name in enumerate(names):
        if i != 0:
            print()
        check = make_check(CHECKS[name])
        print("===", check.name, "===\n")
        configure(os.path.join(dir, name), name, check, args)

def cmd_check(dir, names, args):
    if not dir:
        for x in CHECKS.keys():
            print(x)
        return
    if not names:
        names = list(CHECKS)
    elif not validate_checks(names):
        return 1
    checks = list(map(make_check, map(CHECKS.get, names)))
    for name, check in zip(names, checks):
        sub_dir = os.path.join(dir, name)
        if not os.path.exists(os.path.join(sub_dir, "Makefile")):
            configure(sub_dir, name, check, (), ccache=False)
    results = []
    with tempfile.TemporaryDirectory() as tmp:
        env = setup_env(tmp)
        try:
            for i, (name, check) in enumerate(zip(names, checks)):
                if i != 0:
                    print()
                results.append(
                    exec_test(os.path.join(dir, name), check, args, env))
        except KeyboardInterrupt:
            pass
    if not print_summary(names, results):
        return 1

def configure(dir: str, name: str, check: Check, args: List[str], ccache=True):
    os.makedirs(dir, exist_ok=True)
    if check.setup:
        check.setup(dir)
    cmd = []
    if check.configure:
        cmd.extend(check.configure)
    cmd.append(os.path.join(os.path.abspath(os.curdir), "configure"))
    cmd.extend(check.configure_args or CONFIGURE_ARGS)
    if c := check.compiler:
        cmd.append("CXX={}{}".format("ccache " if ccache else "", c))
    cmd.append("CXXFLAGS={}".format(" ".join(check.cxxflags or CXXFLAGS)))
    if l := check.ldflags:
        cmd.append(f"LDFLAGS={' '.join(l)}")
    if l := check.libs:
        cmd.append(f"LIBS={' '.join(l)}")
    cmd.extend(args)
    env = {}
    if check.env:
        env.update(check.env)
    print("cmd:\n")
    for x in cmd:
        print("-", x)
    if e := check.env:
        print("\nenv:\n")
        for x in e.items():
            print("=".join(x))
    print("\n")
    subprocess.check_call(cmd, cwd=dir, env=os.environ | env)

def setup_env(tmp: str) -> Dict:
    lsan = os.path.join(tmp, "leak_suppressions.txt")
    with open(lsan, "w") as f:
        f.write("leak:_dri.so\n")
    ret = dict(ENV)
    ret["LSAN_OPTIONS"] = "suppressions=" + lsan
    return ret

def exec_test(dir: str, check: Check, args: List[str], env: Dict) -> Result:
    cmd = ["make"]
    if check.target:
        cmd.append(check.target)
    if check.make_args:
        cmd.extend(check.make_args)
    if l := check.linker:
        cmd.append(f"CXXLD={l}")
    cmd.extend(args)
    print("===", check.name, "===\n")
    print("cmd:\n")
    for c in cmd:
        print("-", c)
    print("\nenv:\n")
    for e in env.items():
        print("=".join(e))
    print("\n")
    t0 = time.perf_counter()
    res = subprocess.call(cmd, cwd=dir, env=os.environ | env)
    t1 = time.perf_counter()
    return Result(code=res, time=t1 - t0)

def print_summary(names: List[str], results: List[Result]) -> bool:
    if os.isatty(sys.stdout.fileno()):
        color_red, color_green, color_reset = \
            "\x1b[31m", "\x1b[32m", "\x1b[m\x0f"
    else:
        color_red, color_green, color_reset = "", "", ""
    ret = all(x.code == 0 for x in results)
    name_width = max(map(len, names)) + 1
    result_width = 2 if ret else 6
    assert(len(names) == len(results))
    fmt_result = (
        "{}failed{}".format(color_red, color_reset),
        "{}ok{}".format(color_green, color_reset),
    )
    fmt = lambda n, r, t: "{:{}} {:<{}} ({})".format(
        n + ":", name_width, fmt_result[r], result_width, fmt_time(t))
    print()
    for name, result in zip(names, results):
        print(fmt(name, result.code == 0, result.time))
    print(fmt("all", ret, sum(x.time for x in results)))
    return ret

def fmt_time(t: float) -> str:
    t, s = t / 60, t % 60
    h, m = t / 60, t % 60
    return f"{int(h)}:{int(m):02}:{int(s):02}"

if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:]))
