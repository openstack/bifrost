# -*- coding: utf-8 -*-

# Copyright (c) 2015 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import json

import yaml

from bifrost.tests import base
from bifrost.tests import utils


class TestBifrostInventoryFunctional(base.TestCase):

    def setUp(self):
        self.maxDiff = None
        super(TestBifrostInventoryFunctional, self).setUp()

    def test_yaml_to_json_conversion(self):
        # Note(TheJulia) Ultimately this is just ensuring
        # that we get the same output when we pass something
        # in as YAML
        expected_hostvars = """{"hostname1":
 {"uuid": "00000000-0000-0000-0000-000000000002", "driver": "ipmi",
 "name": "hostname1", "ipv4_address": "192.168.1.3", "ansible_ssh_host":
 "192.168.1.3", "provisioning_ipv4_address": "192.168.1.3",
 "driver_info": {"ipmi_address": "192.0.2.3",
 "ipmi_password": "undefined", "ipmi_username": "root",
 "ipmi_target_address": null, "ipmi_target_channel": null,
 "ipmi_transit_address": null, "ipmi_transit_channel": null}, "nics":
 [{"mac": "00:01:02:03:04:06"}], "properties": {"ram": "8192", "cpu_arch":
 "x86_64", "disk_size": "1024", "cpus": "2"}, "host_groups":
 ["baremetal", "nova"]}, "hostname0":
 {"uuid": "00000000-0000-0000-0000-000000000001", "driver": "ipmi",
 "name": "hostname0", "ipv4_address": "192.168.1.2", "ansible_ssh_host":
 "192.168.1.2", "provisioning_ipv4_address": "192.168.1.2",
 "driver_info": {}, "nics":
 [{"mac": "00:01:02:03:04:05"}], "properties": {"ram": "8192",
 "cpu_arch": "x86_64", "disk_size": "512", "cpus": "1"},
 "host_groups": ["baremetal", "nova"]}}""".replace('\n', '')
        (groups, hostvars) = utils.bifrost_data_conversion(
            yaml.safe_dump(json.loads(str(expected_hostvars))))
        del hostvars['127.0.0.1']
        self.assertDictEqual(json.loads(str(expected_hostvars)), hostvars)

    def test_minimal_json(self):
        input_json = """{"h0000-01":{"uuid":
"00000000-0000-0000-0001-bad00000010","name":"h0000-01","driver_info"
:{"ipmi_address":"10.0.0.78","ipmi_username":"ADMIN","
ipmi_password":"ADMIN"},"driver":"ipmi"}}""".replace('\n', '')
        expected_json = """{"h0000-01":{"uuid":
"00000000-0000-0000-0001-bad00000010","name":"h0000-01","driver_info"
:{"ipmi_address":"10.0.0.78","ipmi_username":"ADMIN","
ipmi_password":"ADMIN"},"driver":"ipmi","addressing_mode":
"dhcp","host_groups": ["baremetal"]}}""".replace('\n', '')
        (groups, hostvars) = utils.bifrost_data_conversion(input_json)
        del hostvars['127.0.0.1']
        self.assertDictEqual(json.loads(str(expected_json)), hostvars)
