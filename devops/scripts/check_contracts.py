#!/usr/bin/env python3
"""Check repository boundaries. HCL syntax is checked separately by Terragrunt."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

def check():
    units = json.loads((ROOT / 'devops/contracts/iac-units.json').read_text())['units']
    by_path = {u['path']: u for u in units}
    actual = {str(p.parent.relative_to(ROOT)) for p in (ROOT / 'live').rglob('terragrunt.hcl')
              if '.terragrunt-cache' not in p.parts}
    assert len(by_path) == len(units), 'Duplicate unit'
    assert actual == set(by_path), 'Unit inventory is stale'
    assert len({u['state_key'] for u in units}) == len(units), 'Duplicate state key'
    seen_modules = set()
    for u in units:
        folder = ROOT / u['path']
        text = (folder / 'terragrunt.hcl').read_text()
        assert 'mock_outputs' not in text and 'skip_outputs' not in text, 'Mocks must not enter deployment units'
        source = re.search(r'source\s*=\s*"([^"]+)"', text).group(1)
        module = (folder / source).resolve()
        assert module == (ROOT / u['module']).resolve() and module.is_dir(), u['path']
        seen_modules.add(u['module'])
        deps = {str((folder / d).resolve().relative_to(ROOT))
                for d in re.findall(r'config_path\s*=\s*"([^"]+)"', text)}
        assert deps == set(u['dependencies']) and deps <= set(by_path), u['path']
        assert u['state_key'] == str(folder.relative_to(ROOT / 'live')).replace('\\', '/') + '/terraform.tfstate'
        assert (folder / '.terraform.lock.hcl').is_file(), u['path']
    assert seen_modules == {str(p.relative_to(ROOT)) for p in (ROOT / 'terraform/modules').iterdir() if p.is_dir()}, 'Unvalidated module'
    visiting, done = set(), set()
    def visit(path):
        assert path not in visiting, 'Dependency cycle: ' + path
        if path in done:
            return
        visiting.add(path)
        for dep in by_path[path]['dependencies']:
            visit(dep)
        visiting.remove(path)
        done.add(path)
    for path in by_path:
        visit(path)
    assert by_path['live/dev/rds']['dependencies'] == ['live/dev/vpc'], 'DB must not depend on EKS'
    assert set(by_path['live/dev/eks-database-access']['dependencies']) == {'live/dev/eks', 'live/dev/rds'}
    assert set(by_path['live/dev/pms-irsa']['dependencies']) == {'live/dev/eks', 'live/dev/pms-storage'}
    assert not by_path['live/shared/github-oidc']['dependencies'], 'Account OIDC must be independent'
    assert 'pms_' not in (ROOT / 'terraform/modules/irsa/main.tf').read_text(), 'Test IAM owns PMS resources'
    assert 'aws_iam_openid_connect_provider"' not in (ROOT / 'terraform/modules/github-actions-ecr/main.tf').read_text()
    assert 'eks_node_security_group_id' not in (ROOT / 'terraform/modules/rds-postgres/main.tf').read_text()
    for p in (ROOT / 'terraform/modules').rglob('*.tf'):
        assert 'Environment = "dev"' not in p.read_text(), str(p)
    for p in (ROOT / 'terraform/modules').rglob('*.tftest.hcl'):
        assert not re.search(r'command\s*=\s*apply', p.read_text()), 'Real apply test is forbidden: ' + str(p)
        assert 'mock_provider "aws"' in p.read_text(), 'AWS tests must be mocked'
        assert len(re.findall(r'run\s+"[^"]+"\s*\{', p.read_text())) == len(re.findall(r'command\s*=\s*plan', p.read_text())), 'Every test run must explicitly plan'
    print(f'PASS: {len(units)} units; unique state keys, dependency DAG, lifecycle boundaries')
    return units

if __name__ == '__main__':
    check()
