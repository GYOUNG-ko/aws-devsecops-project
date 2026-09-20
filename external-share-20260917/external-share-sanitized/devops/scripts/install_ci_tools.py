#!/usr/bin/env python3
"""Install reviewed Linux/amd64 release bytes into a supplied CI-local directory."""
import argparse
import hashlib
import io
import platform
import urllib.request
import zipfile
from pathlib import Path

TOOLS = {
    'tofu': ('1.12.6', 'https://github.com/opentofu/opentofu/releases/download/v1.12.6/tofu_1.12.6_linux_amd64.zip',
             '5dc43da4f750f33873dc25e94587128709e819e544b7be9016b255316153c3a8'),
    'terragrunt': ('1.1.4', 'https://github.com/gruntwork-io/terragrunt/releases/download/v1.1.4/terragrunt_linux_amd64',
                   'a2640da8455fa5f3671167e6373832b0907b9dc972dd01c2093cc7808934e158'),
}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true', help='Check version manifest without downloading')
    parser.add_argument('--destination', type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    versions = dict(line.split() for line in (root / '.tool-versions').read_text().splitlines())
    assert versions == {'opentofu': TOOLS['tofu'][0], 'terragrunt': TOOLS['terragrunt'][0]}, 'Tool version manifests disagree'
    if args.check:
        print('PASS: CI and local tool versions agree')
        return
    if not args.destination or platform.system() != 'Linux' or platform.machine() != 'x86_64':
        parser.error('Installation requires Linux/amd64 and --destination')
    args.destination.mkdir(parents=True, exist_ok=True)
    for name, (_, url, expected) in TOOLS.items():
        with urllib.request.urlopen(url, timeout=120) as response:
            data = response.read()
        if hashlib.sha256(data).hexdigest() != expected:
            raise RuntimeError('Checksum mismatch: ' + name)
        if name == 'tofu':
            with zipfile.ZipFile(io.BytesIO(data)) as archive:
                data = archive.read('tofu')
        output = args.destination / name
        output.write_bytes(data)
        output.chmod(0o755)

if __name__ == '__main__':
    main()
