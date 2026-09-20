#!/usr/bin/env python3
"""Read-only legacy-key guard. Never prints state values or writes state."""
import argparse
import json
import subprocess
import sys


def legacy_keys(keys, canonical_key):
    return [key for key in keys if key != canonical_key and key.replace('\\', '/') == canonical_key]


def managed_instances(state):
    return sum(len(r.get('instances', [])) for r in state.get('resources', []) if r.get('mode') == 'managed')


def aws_json(arguments, region):
    result = subprocess.run(['aws', *arguments, '--region', region, '--output', 'json', '--no-cli-pager'],
                            capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError('AWS read failed; check profile, login and read permissions. No state changes made.')
    return json.loads(result.stdout or '{}')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--bucket', required=True)
    parser.add_argument('--key', required=True)
    parser.add_argument('--region', required=True)
    parser.add_argument('--account', required=True)
    args = parser.parse_args()
    identity = aws_json(['sts', 'get-caller-identity'], args.region)
    if identity.get('Account') != args.account:
        raise RuntimeError('AWS account mismatch; stopping before backend initialization.')
    listing = aws_json(['s3api', 'list-objects-v2', '--bucket', args.bucket], args.region)
    keys = [item['Key'] for item in listing.get('Contents', [])]
    blocked = []
    for key in legacy_keys(keys, args.key):
        # aws s3 cp streams only to captured memory. Nothing is logged or saved.
        result = subprocess.run(['aws', 's3', 'cp', f's3://{args.bucket}/{key}', '-',
                                 '--region', args.region, '--only-show-errors'], capture_output=True, text=True)
        if result.returncode:
            raise RuntimeError('Could not inspect legacy state; refusing to assume it is empty.')
        count = managed_instances(json.loads(result.stdout))
        print(json.dumps({'legacy_key': key, 'managed_instances': count}))
        if count:
            blocked.append(key)
    if blocked:
        raise RuntimeError('Legacy state still owns managed resources. Reconcile ownership before init/plan/apply; see docs/operations/iac-maintenance.md.')
    print('PASS: expected AWS account; no populated legacy alias for ' + args.key)

if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, ValueError, OSError) as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
