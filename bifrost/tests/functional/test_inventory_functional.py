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

    def test_csv_file_conversion_multiline_general(self):
        # NOTE(TheJulia): While this is a massive amount of input
        # and resulting output that is parsed as part of this
        # and similar tests, we need to ensure consistency,
        # and that is largely what this test is geared to ensure.
        CSV = """00:01:02:03:04:05,root,undefined,192.0.2.2,1,8192,512,
unused,,00000000-0000-0000-0000-000000000001,hostname0,
192.168.1.2,,,,|
00:01:02:03:04:06,root,undefined,192.0.2.3,2,8192,1024,
unused,,00000000-0000-0000-0000-000000000002,hostname1,
192.168.1.3,,,,,ipmi""".replace('\n', '').replace('|', '\n')
        expected_hostvars = """{"hostname1":
 {"uuid": "00000000-0000-0000-0000-000000000002", "driver": "ipmi",
 "name": "hostname1", "ipv4_address": "192.168.1.3",
 "provisioning_ipv4_address": "192.168.1.3" ,"ansible_ssh_host":
 "192.168.1.3", "driver_info": {"power": {"ipmi_address": "192.0.2.3",
 "ipmi_password": "undefined", "ipmi_username": "root",
 "ipmi_target_address": null, "ipmi_target_channel": null,
 "ipmi_transit_address": null, "ipmi_transit_channel": null}}, "nics":
 [{"mac": "00:01:02:03:04:06"}], "properties": {"ram": "8192", "cpu_arch":
 "x86_64", "disk_size": "1024", "cpus": "2"}, "host_groups": ["baremetal"]},
 "hostname0":
 {"uuid": "00000000-0000-0000-0000-000000000001", "driver": "ipmi",
 "name": "hostname0", "ipv4_address": "192.168.1.2",
 "provisioning_ipv4_address": "192.168.1.2", "ansible_ssh_host":
 "192.168.1.2", "driver_info": {"power": {"ipmi_address": "192.0.2.2",
 "ipmi_password": "undefined", "ipmi_username": "root",
 "ipmi_target_address": null, "ipmi_target_channel": null,
 "ipmi_transit_address": null, "ipmi_transit_channel": null}}, "nics":
 [{"mac": "00:01:02:03:04:05"}], "properties": {"ram": "8192",
 "cpu_arch": "x86_64", "disk_size": "512", "cpus": "1"},
 "host_groups": ["baremetal"]}}""".replace('\n', '')
        expected_groups = """{"baremetal": {"hosts": ["hostname0",
 "hostname1"]}, "localhost": {"hosts": ["127.0.0.1"]}}""".replace('\n', '')

        (groups, hostvars) = utils.bifrost_csv_conversion(CSV)
        self.assertDictEqual(json.loads(str(expected_hostvars)), hostvars)
        self.assertDictEqual(json.loads(expected_groups), groups)

    def test_csv_file_conversion_ipmi_dual_bridging(self):
        CSV = """00:01:02:03:04:06,root,undefined,192.0.2.3,2,8192,1024,
unused,,00000000-0000-0000-0000-000000000002,hostname1,
192.168.1.3,10,20,30,40,ipmi""".replace('\n', '').replace('|', '\n')

        expected_hostvars = """{"hostname1":
 {"uuid": "00000000-0000-0000-0000-000000000002", "driver": "ipmi",
 "name": "hostname1", "ipv4_address": "192.168.1.3",
 "provisioning_ipv4_address": "192.168.1.3", "ansible_ssh_host":
 "192.168.1.3", "driver_info": {"power": {"ipmi_address": "192.0.2.3",
 "ipmi_password": "undefined", "ipmi_username": "root",
 "ipmi_target_address": "20", "ipmi_target_channel": "10",
 "ipmi_transit_address": "40", "ipmi_transit_channel": "30",
 "ipmi_bridging": "dual"}}, "nics":
 [{"mac": "00:01:02:03:04:06"}], "properties": {"ram": "8192", "cpu_arch":
 "x86_64", "disk_size": "1024", "cpus": "2"},
 "host_groups": ["baremetal"]}}""".replace('\n', '')

        expected_groups = """{"baremetal": {"hosts": ["hostname1"]},
 "localhost": {"hosts": ["127.0.0.1"]}}""".replace('\n', '')

        (groups, hostvars) = utils.bifrost_csv_conversion(CSV)
        self.assertDictEqual(json.loads(str(expected_hostvars)), hostvars)
        self.assertDictEqual(json.loads(expected_groups), groups)

    def test_csv_file_conversion_ipmi_single_bridging(self):
        CSV = """00:01:02:03:04:06,root,undefined,192.0.2.3,2,8192,1024,
unused,,00000000-0000-0000-0000-000000000002,hostname1,
192.168.1.3,10,20,,,ipmi""".replace('\n', '').replace('|', '\n')

        expected_hostvars = """{"hostname1":
 {"uuid": "00000000-0000-0000-0000-000000000002", "driver": "ipmi",
 "name": "hostname1", "ipv4_address": "192.168.1.3",
 "provisioning_ipv4_address": "192.168.1.3", "ansible_ssh_host":
 "192.168.1.3", "driver_info": {"power": {"ipmi_address": "192.0.2.3",
 "ipmi_password": "undefined", "ipmi_username": "root",
 "ipmi_target_address": "20", "ipmi_target_channel": "10",
 "ipmi_transit_address": null, "ipmi_transit_channel": null,
 "ipmi_bridging": "single"}}, "nics":
 [{"mac": "00:01:02:03:04:06"}], "properties": {"ram": "8192", "cpu_arch":
 "x86_64", "disk_size": "1024", "cpus": "2"},
 "host_groups": ["baremetal"]}}""".replace('\n', '')

        (groups, hostvars) = utils.bifrost_csv_conversion(CSV)
        self.assertDictEqual(json.loads(str(expected_hostvars)), hostvars)

    def test_csv_file_conversion_dhcp(self):
        CSV = """00:01:02:03:04:06,root,undefined,192.0.2.3,2,8192,1024,
unused,,00000000-0000-0000-0000-000000000002,hostname1
,,,,,,ipmi""".replace('\n', '').replace('|', '\n')

        expected_hostvars = """{"hostname1":
 {"uuid": "00000000-0000-0000-0000-000000000002", "driver": "ipmi",
 "name": "hostname1", "addressing_mode": "dhcp", "ipv4_address": null,
 "provisioning_ipv4_address": null,
 "driver_info": {"power": {"ipmi_address": "192.0.2.3", "ipmi_password":
 "undefined", "ipmi_username": "root", "ipmi_target_address": null,
 "ipmi_target_channel": null, "ipmi_transit_address": null,
 "ipmi_transit_channel": null}}, "nics":
 [{"mac": "00:01:02:03:04:06"}], "properties": {"ram": "8192", "cpu_arch":
 "x86_64", "disk_size": "1024", "cpus": "2"},
 "host_groups": ["baremetal"]}}""".replace('\n', '')

        (groups, hostvars) = utils.bifrost_csv_conversion(CSV)
        self.assertDictEqual(json.loads(str(expected_hostvars)), hostvars)

    def test_csv_json_reconsumability_dhcp(self):
        # Note(TheJulia) This intentionally takes CSV data, converts it
        # and then attempts reconsumption of the same data through the
        # JSON/YAML code path of Bifrost to ensure that the output
        # is identical.
        CSV = """00:01:02:03:04:06,root,undefined,192.0.2.3,2,8192,1024,
unused,,00000000-0000-0000-0000-000000000002,hostname1
,,,,,,ipmi""".replace('\n', '')

        expected_hostvars = """{"hostname1":
 {"uuid": "00000000-0000-0000-0000-000000000002", "driver": "ipmi",
 "name": "hostname1", "addressing_mode": "dhcp", "ipv4_address": null,
 "provisioning_ipv4_address": null,
 "driver_info": {"power": {"ipmi_address": "192.0.2.3", "ipmi_password":
 "undefined", "ipmi_username": "root", "ipmi_target_address": null,
 "ipmi_target_channel": null, "ipmi_transit_address": null,
 "ipmi_transit_channel": null}}, "nics":
 [{"mac": "00:01:02:03:04:06"}], "properties": {"ram": "8192", "cpu_arch":
 "x86_64", "disk_size": "1024", "cpus": "2"},
 "host_groups": ["baremetal"]}}""".replace('\n', '')

        (groups, hostvars) = utils.bifrost_csv_conversion(CSV)
        self.assertDictEqual(json.loads(str(expected_hostvars)), hostvars)
        (groups, hostvars) = utils.bifrost_data_conversion(
            json.dumps(hostvars))
        self.assertDictEqual(json.loads(str(expected_hostvars)), hostvars)

    def test_csv_json_reconsumability_general(self):
        CSV = """00:01:02:03:04:05,root,undefined,192.0.2.2,1,8192,512,
unused,,00000000-0000-0000-0000-000000000001,hostname0,
192.168.1.2,,,,|
00:01:02:03:04:06,root,undefined,192.0.2.3,2,8192,1024,
unused,,00000000-0000-0000-0000-000000000002,hostname1,
192.168.1.3,,,,,ipmi""".replace('\n', '').replace('|', '\n')
        expected_hostvars = """{"hostname1":
 {"uuid": "00000000-0000-0000-0000-000000000002", "driver": "ipmi",
 "name": "hostname1", "ipv4_address": "192.168.1.3", "ansible_ssh_host":
 "192.168.1.3", "provisioning_ipv4_address": "192.168.1.3",
 "driver_info": {"power": {"ipmi_address": "192.0.2.3",
 "ipmi_password": "undefined", "ipmi_username": "root",
 "ipmi_target_address": null, "ipmi_target_channel": null,
 "ipmi_transit_address": null, "ipmi_transit_channel": null}}, "nics":
 [{"mac": "00:01:02:03:04:06"}], "properties": {"ram": "8192", "cpu_arch":
 "x86_64", "disk_size": "1024", "cpus": "2"}, "host_groups": ["baremetal"]},
 "hostname0":
 {"uuid": "00000000-0000-0000-0000-000000000001", "driver": "ipmi",
 "name": "hostname0", "ipv4_address": "192.168.1.2", "ansible_ssh_host":
 "192.168.1.2", "provisioning_ipv4_address": "192.168.1.2",
 "driver_info": {"power": {"ipmi_address": "192.0.2.2",
 "ipmi_password": "undefined", "ipmi_username": "root",
 "ipmi_target_address": null, "ipmi_target_channel": null,
 "ipmi_transit_address": null, "ipmi_transit_channel": null}}, "nics":
 [{"mac": "00:01:02:03:04:05"}], "properties": {"ram": "8192",
 "cpu_arch": "x86_64", "disk_size": "512", "cpus": "1"},
 "host_groups": ["baremetal"]}}""".replace('\n', '')

        (groups, hostvars) = utils.bifrost_csv_conversion(CSV)
        self.assertDictEqual(json.loads(str(expected_hostvars)), hostvars)
        (groups, hostvars) = utils.bifrost_data_conversion(
            json.dumps(hostvars))
        self.assertDictEqual(json.loads(str(expected_hostvars)), hostvars)

    def test_yaml_to_json_conversion(self):
        # Note(TheJulia) Ultimately this is just ensuring
        # that we get the same output when we pass something
        # in as YAML
        expected_hostvars = """{"hostname1":
 {"uuid": "00000000-0000-0000-0000-000000000002", "driver": "ipmi",
 "name": "hostname1", "ipv4_address": "192.168.1.3", "ansible_ssh_host":
 "192.168.1.3", "provisioning_ipv4_address": "192.168.1.3",
 "driver_info": {"power": {"ipmi_address": "192.0.2.3",
 "ipmi_password": "undefined", "ipmi_username": "root",
 "ipmi_target_address": null, "ipmi_target_channel": null,
 "ipmi_transit_address": null, "ipmi_transit_channel": null}}, "nics":
 [{"mac": "00:01:02:03:04:06"}], "properties": {"ram": "8192", "cpu_arch":
 "x86_64", "disk_size": "1024", "cpus": "2"}, "host_groups":
 ["baremetal", "nova"]}, "hostname0":
 {"uuid": "00000000-0000-0000-0000-000000000001", "driver": "ipmi",
 "name": "hostname0", "ipv4_address": "192.168.1.2", "ansible_ssh_host":
 "192.168.1.2", "provisioning_ipv4_address": "192.168.1.2",
 "driver_info": {"power": {}}, "nics":
 [{"mac": "00:01:02:03:04:05"}], "properties": {"ram": "8192",
 "cpu_arch": "x86_64", "disk_size": "512", "cpus": "1"},
 "host_groups": ["baremetal", "nova"]}}""".replace('\n', '')
        (groups, hostvars) = utils.bifrost_data_conversion(
            yaml.safe_dump(json.loads(str(expected_hostvars))))
        self.assertDictEqual(json.loads(str(expected_hostvars)), hostvars)

    def test_minimal_json(self):
        input_json = """{"h0000-01":{"uuid":
"00000000-0000-0000-0001-bad00000010","name":"h0000-01","driver_info"
:{"power":{"ipmi_address":"10.0.0.78","ipmi_username":"ADMIN","
ipmi_password":"ADMIN"}},"driver":"ipmi"}}""".replace('\n', '')
        expected_json = """{"h0000-01":{"uuid":
"00000000-0000-0000-0001-bad00000010","name":"h0000-01","driver_info"
:{"power":{"ipmi_address":"10.0.0.78","ipmi_username":"ADMIN","
ipmi_password":"ADMIN"}},"driver":"ipmi","addressing_mode":
"dhcp","host_groups": ["baremetal"]}}""".replace('\n', '')
        (groups, hostvars) = utils.bifrost_data_conversion(input_json)
        self.assertDictEqual(json.loads(str(expected_json)), hostvars)
