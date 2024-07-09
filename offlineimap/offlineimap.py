import subprocess

def exec_pass(s):
    return subprocess.check_output(('pass', 'show', s))
