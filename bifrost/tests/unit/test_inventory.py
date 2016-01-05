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
