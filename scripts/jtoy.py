#!/bin/env python3
import yaml, sys

yaml.dump(
    yaml.safe_load(sys.stdin),
    sys.stdout, default_flow_style=False)
