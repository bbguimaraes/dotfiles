#!/bin/env python3
import json, yaml, sys

json.dump(
    yaml.load(sys.stdin, Loader=yaml.SafeLoader),
    sys.stdout, default=str)
