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

import os.path

from bifrost.tests import base


# NOTE(dtantsur): the module is not importable, hence all the troubles
get_network_data = None  # make pep8 happy
FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                    '..', '..', '..', 'playbooks', 'library',
                    'network_metadata.py')
with open(FILE) as fp:
    # Not going to test the ansible bits, strip the imports away to avoid
    # depending on it.
    script = [line for line in fp if not line.startswith('from ansible.')]
    exec(''.join(script))


TEST_MAC = '12:34:56:78:9a:bc'


class TestBifrostNetworkMetadata(base.TestCase):

    def test_simple(self):
        params = {
            'nics': [{'address': TEST_MAC}],
            'ipv4_address': '1.2.3.4',
            'ipv4_subnet_mask': '255.255.0.0',
        }
        result = get_network_data(params)
        self.assertEqual({
            'links': [
                {'id': TEST_MAC,
                 'ethernet_mac_address': TEST_MAC,
                 'type': 'phy'},
            ],
            'networks': [
                {'id': f'ipv4-{TEST_MAC}',
                 'link': TEST_MAC,
                 'type': 'ipv4',
                 'ip_address': '1.2.3.4',
                 'netmask': '255.255.0.0',
                 'routes': []}
            ],
            'services': [],
        }, result)

    def test_everything(self):
        another_mac = 'aa:aa:aa:bb:cc:dd'
        params = {
            'nics': [{'address': another_mac}, {'address': TEST_MAC}],
            'ipv4_address': '1.2.3.4',
            'ipv4_subnet_mask': '255.255.0.0',
            'ipv4_interface_mac': TEST_MAC,
            'ipv4_gateway': '1.2.1.1',
            'ipv4_nameserver': ['1.1.1.1'],
        }
        result = get_network_data(params)
        self.assertEqual({
            'links': [
                {'id': TEST_MAC,
                 'ethernet_mac_address': TEST_MAC,
                 'type': 'phy'},
            ],
            'networks': [
                {'id': f'ipv4-{TEST_MAC}',
                 'link': TEST_MAC,
                 'type': 'ipv4',
                 'ip_address': '1.2.3.4',
                 'netmask': '255.255.0.0',
                 'dns_nameservers': ['1.1.1.1'],
                 'routes': [{
                     'network': '0.0.0.0',
                     'netmask': '0.0.0.0',
                     'gateway': '1.2.1.1',
                 }]}
            ],
            'services': [{
                'type': 'dns',
                'address': '1.1.1.1',
            }],
        }, result)
