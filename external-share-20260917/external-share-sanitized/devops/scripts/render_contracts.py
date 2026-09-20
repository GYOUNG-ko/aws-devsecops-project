#!/usr/bin/env python3
"""Evaluate real Terragrunt wiring with dependency outputs mocked in a disposable copy only."""
import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path
from check_contracts import ROOT, check


def render(units):
    outputs = json.loads((ROOT / 'devops/contracts/mock-outputs.json').read_text())
    rendered = {}
    with tempfile.TemporaryDirectory(prefix='pms-render-') as temp:
        root = Path(temp)
        shutil.copytree(ROOT / 'live', root / 'live', ignore=shutil.ignore_patterns('.terragrunt-cache', '.terraform'))
        for unit in units:
            p = root / unit['path'] / 'terragrunt.hcl'
            text = p.read_text()
            # Every dependency block uses a literal config_path; HCL syntax validated separately.
            def inject(match):
                body = match.group(0)
                fixtures = dict(outputs)
                if 'shared/github-oidc' in body:
                    fixtures['oidc_provider_arn'] = 'arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com'
                return body[:-1] + '\n skip_outputs = true\n mock_outputs = ' + json.dumps(fixtures) + '\n}'
            text = re.sub(r'dependency\s+"[^"]+"\s*\{[^{}]*\}', inject, text)
            p.write_text(text)
        for unit in units:
            result = subprocess.run(['terragrunt', 'render', '--working-dir', str(root / unit['path']),
                                     '--format', 'json', '--no-color'], capture_output=True, text=True)
            if result.returncode:
                raise RuntimeError(unit['path'] + '\n' + result.stderr)
            config = json.loads(result.stdout)
            assert config['remote_state']['config']['key'] == unit['state_key'], unit['path']
            assert config['remote_state']['config']['encrypt'] and config['remote_state']['config']['use_lockfile']
            assert 'allowed_account_ids' in config['generate']['provider']['contents']
            hook = config['terraform']['before_hook']['state_ownership_preflight']
            assert {'init', 'plan', 'apply'} <= set(hook['commands'])
            assert hook['execute'][1] == str(root / 'live') + '/../devops/scripts/state_preflight.py'
            assert not any(u in config['inputs'] for u in ['mock_outputs', 'skip_outputs'])
            rendered[unit['path']] = config
    print(f'PASS: {len(units)} Terragrunt configurations evaluated with isolated fixtures')
    return rendered

if __name__ == '__main__':
    render(check())
