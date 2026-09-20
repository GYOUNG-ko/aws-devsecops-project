import sys
import unittest
from unittest.mock import patch
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from state_preflight import legacy_keys, managed_instances, main

class StatePreflightTests(unittest.TestCase):
    def test_windows_alias_is_not_a_separate_environment(self):
        keys = ['dev/vpc/terraform.tfstate', 'dev\\vpc/terraform.tfstate', 'prod/vpc/terraform.tfstate']
        self.assertEqual(legacy_keys(keys, keys[0]), [keys[1]])
    def test_empty_destroyed_state_does_not_block_new_deployment(self):
        self.assertEqual(managed_instances({'resources': [{'mode': 'data', 'instances': [{}]}]}), 0)
    def test_state_with_empty_resource_records_is_not_populated(self):
        self.assertEqual(managed_instances({'resources': [{'mode': 'managed', 'instances': []}]}), 0)
    def test_managed_network_blocks_even_when_outputs_are_empty(self):
        self.assertEqual(managed_instances({'outputs': {}, 'resources': [{'mode': 'managed', 'instances': [{}, {}]}]}), 2)

    def test_wrong_account_stops_before_any_state_read(self):
        argv = ['state_preflight.py', '--bucket', 'test', '--key', 'dev/vpc/terraform.tfstate', '--region', 'ap-northeast-2', '--account', '<AWS_ACCOUNT_ID>']
        with patch('sys.argv', argv), patch('state_preflight.aws_json', return_value={'Account': '<AWS_ACCOUNT_ID>'}) as aws:
            with self.assertRaisesRegex(RuntimeError, 'account mismatch'):
                main()
            self.assertEqual(aws.call_count, 1)

if __name__ == '__main__':
    unittest.main()
