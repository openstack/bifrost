# -*- coding: utf-8 -*-

# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

"""
test_inventory
----------------------------------

Tests for `inventory` module.
"""

from unittest import mock

from bifrost import inventory

from bifrost.tests import base


class TestBifrostInventoryUnit(base.TestCase):

    def test_inventory_preparation(self):
        (groups, hostvars) = inventory._prepare_inventory()
        self.assertIn("baremetal", groups)
        self.assertIn("localhost", groups)
        self.assertDictEqual(hostvars, {})
        localhost_value = dict(hosts=["127.0.0.1"])
        self.assertDictEqual(localhost_value, groups['localhost'])

    def test__val_or_none(self):
        array = ['no', '', 'yes']
        self.assertEqual('no', inventory._val_or_none(array, 0))
        self.assertIsNone(inventory._val_or_none(array, 1))
        self.assertEqual('yes', inventory._val_or_none(array, 2))
        self.assertIsNone(inventory._val_or_none(array, 4))

    def test__process_shade(self):
        inventory.shade = mock_shade = mock.Mock()
        inventory.SHADE_LOADED = True
        (groups, hostvars) = inventory._prepare_inventory()
        mock_cloud = mock_shade.operator_cloud.return_value
        mock_cloud.list_machines.return_value = [
            {
                'driver_info': {
                    'ipmi_address': '1.2.3.4',
                },
                'links': [],
                'name': 'node1',
                'ports': [],
                'properties': {
                    'cpus': 42,
                },
                'uuid': 'f3fbf7c6-b4e9-4dd2-8ca0-c74a50f8be45',
            },
        ]
        mock_cloud.list_nics_for_machine.return_value = [
            {
                'address': '00:11:22:33:44:55',
                'uuid': 'e2be93b5-a8f6-46a2-bec7-571b8ecf2938',
            },
        ]
        (groups, hostvars) = inventory._process_shade(groups, hostvars)
        mock_shade.operator_cloud.assert_called_once_with(
            auth_type='None', auth={'endpoint': 'http://localhost:6385/'})
        mock_cloud.list_machines.assert_called_once_with()
        mock_cloud.list_nics_for_machine.assert_called_once_with(
            'f3fbf7c6-b4e9-4dd2-8ca0-c74a50f8be45')
        self.assertIn('baremetal', groups)
        self.assertIn('hosts', groups['baremetal'])
        self.assertEqual(groups['baremetal'], {'hosts': ['node1']})
        self.assertIn('node1', hostvars)
        expected_machine = {
            'addressing_mode': 'dhcp',
            'driver_info': {
                'ipmi_address': '1.2.3.4',
            },
            'name': 'node1',
            'nics': [
                {
                    'mac': '00:11:22:33:44:55',
                },
            ],
            'properties': {
                'cpus': 42,
            },
            'uuid': 'f3fbf7c6-b4e9-4dd2-8ca0-c74a50f8be45',
        }
        self.assertEqual(hostvars['node1'], expected_machine)

    def test__process_shade_multiple_nics(self):
        inventory.shade = mock_shade = mock.Mock()
        inventory.SHADE_LOADED = True
        (groups, hostvars) = inventory._prepare_inventory()
        mock_cloud = mock_shade.operator_cloud.return_value
        mock_cloud.list_machines.return_value = [
            {
                'driver_info': {
                    'ipmi_address': '1.2.3.4',
                },
                'links': [],
                'name': 'node1',
                'ports': [],
                'properties': {
                    'cpus': 42,
                },
                'uuid': 'f3fbf7c6-b4e9-4dd2-8ca0-c74a50f8be45',
            },
        ]
        mock_cloud.list_nics_for_machine.return_value = [
            {
                'address': '00:11:22:33:44:55',
                'uuid': 'e2be93b5-a8f6-46a2-bec7-571b8ecf2938',
            },
            {
                'address': '00:11:22:33:44:56',
                'uuid': '59e8cd37-4f71-4ca1-a264-93c2ca7de0f7',
            },
        ]
        (groups, hostvars) = inventory._process_shade(groups, hostvars)
        mock_shade.operator_cloud.assert_called_once_with(
            auth_type='None', auth={'endpoint': 'http://localhost:6385/'})
        mock_cloud.list_machines.assert_called_once_with()
        mock_cloud.list_nics_for_machine.assert_called_once_with(
            'f3fbf7c6-b4e9-4dd2-8ca0-c74a50f8be45')
        self.assertIn('baremetal', groups)
        self.assertIn('hosts', groups['baremetal'])
        self.assertEqual(groups['baremetal'], {'hosts': ['node1']})
        self.assertIn('node1', hostvars)
        expected_machine = {
            'addressing_mode': 'dhcp',
            'driver_info': {
                'ipmi_address': '1.2.3.4',
            },
            'name': 'node1',
            'nics': [
                {
                    'mac': '00:11:22:33:44:55',
                },
                {
                    'mac': '00:11:22:33:44:56',
                },
            ],
            'properties': {
                'cpus': 42,
            },
            'uuid': 'f3fbf7c6-b4e9-4dd2-8ca0-c74a50f8be45',
        }
        self.assertEqual(hostvars['node1'], expected_machine)
