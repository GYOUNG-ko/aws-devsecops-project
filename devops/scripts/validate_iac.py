#!/usr/bin/env python3
"""Credential-free validation in disposable directories; never initializes a backend."""
import argparse
import os
import shutil
import subprocess
import tempfile
from pathlib import Path
from check_contracts import ROOT, check
from render_contracts import render
import json

parser = argparse.ArgumentParser()
parser.add_argument('--unit', help='Optional live/... unit; default validates every consumer')
args = parser.parse_args()
units = check()
if args.unit:
    units = [u for u in units if u['path'] == args.unit]
    if not units:
        parser.error('Unknown unit')
subprocess.run(['tofu', 'fmt', '-check', '-recursive', 'terraform'], cwd=ROOT, check=True)
subprocess.run(['terragrunt', 'hcl', 'validate', '--working-dir', 'live', '--no-color'], cwd=ROOT, check=True)
rendered = render(units)
# No AWS credentials are needed by init/validate or mock-only tests.
env = {k: v for k, v in os.environ.items() if not k.startswith('AWS_')}
env.update(AWS_EC2_METADATA_DISABLED='true', AWS_CONFIG_FILE=os.devnull,
           AWS_SHARED_CREDENTIALS_FILE=os.devnull, TF_IN_AUTOMATION='true')
with tempfile.TemporaryDirectory(prefix='pms-iac-') as temp:
    for unit in units:
        directory = Path(temp) / unit['path'].replace('/', '_')
        shutil.copytree(ROOT / unit['module'], directory,
                        ignore=shutil.ignore_patterns('.terraform', '*.tfstate*'))
        shutil.copy2(ROOT / unit['path'] / '.terraform.lock.hcl', directory / '.terraform.lock.hcl')
        config = rendered[unit['path']]
        (directory / 'provider.tf').write_text(config['generate']['provider']['contents'])
        (directory / 'validation.auto.tfvars.json').write_text(json.dumps(config['inputs']))
        print('\nValidating ' + unit['path'], flush=True)
        for command in [
            ['init', '-backend=false', '-input=false', '-lockfile=readonly', '-no-color'],
            ['validate', '-no-color'],
        ]:
            subprocess.run(['tofu', '-chdir=' + str(directory)] + command, env=env, check=True)
        if list((directory / 'tests').glob('*.tftest.hcl')):
            subprocess.run(['tofu', '-chdir=' + str(directory), 'test', '-no-color'], env=env, check=True)
print('PASS: all selected modules validated; no live AWS or backend validation performed')
