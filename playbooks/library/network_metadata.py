#!/usr/bin/env python
# coding: utf-8 -*-

# (c) 2015, Hewlett-Packard Development Company, L.P.
#
# This module is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this software.  If not, see <http://www.gnu.org/licenses/>.

DOCUMENTATION = '''
---
module: network_metadata
short_description: Returns a config-drive network-metadata dictionary
extends_documentation_fragment: openstack
'''


def main():
    argument_spec = dict(
        ipv4_address=dict(required=False),
        ipv4_gateway=dict(required=False),
        ipv4_interface_mac=dict(required=False),
        ipv4_nameserver=dict(required=False, type='list'),
        ipv4_subnet_mask=dict(required=False),
        vlan_id=dict(required=False),
        network_mtu=dict(required=False),
        nics=dict(required=False, type='list'),
        node_network_data=dict(required=False, type='dict')
    )

    module = AnsibleModule(argument_spec)  # noqa: F405

    network_metadata = module.params['node_network_data']
    if not network_metadata:
        links = []
        networks = []

        if module.params['ipv4_interface_mac']:
            nic_id = module.params['ipv4_interface_mac']

            if module.params['vlan_id']:
                nic_id = 'vlan-%s' % module.params['ipv4_interface_mac']

                links.append({
                    'id': nic_id,
                    'type': 'vlan',
                    'vlan_id': module.params['vlan_id'],
                    'vlan_link': module.params['ipv4_interface_mac'],
                    'vlan_mac_address': module.params['ipv4_interface_mac'],
                })

            links.append({
                'id': module.params['ipv4_interface_mac'],
                'type': 'phy',
                'ethernet_mac_address': module.params['ipv4_interface_mac'],
                'mtu': module.params['network_mtu']
            })

            for nic in module.params['nics']:
                if nic['mac'] == module.params['ipv4_interface_mac']:
                    networks.append({
                        'id': 'ipv4-%s' % nic_id,
                        'link': nic_id,
                        'type': 'ipv4',
                        'ip_address': module.params['ipv4_address'],
                        'netmask': module.params['ipv4_subnet_mask'],
                        'dns_nameservers': module.params['ipv4_nameserver'],
                        'routes': [{
                            'network': '0.0.0.0',
                            'netmask': '0.0.0.0',
                            'gateway': module.params['ipv4_gateway']
                        }]
                    })
        else:
            for i, nic in enumerate(module.params['nics']):
                nic_id = nic['mac']
                if module.params['vlan_id']:
                    nic_id = 'vlan-%s' % nic['mac']

                    links.append({
                        'id': nic_id,
                        'type': 'vlan',
                        'vlan_id': module.params['vlan_id'],
                        'vlan_link': nic['mac'],
                        'vlan_mac_address': nic['mac']
                    })

                links.append({
                    'id': nic['mac'],
                    'type': 'phy',
                    'ethernet_mac_address': nic['mac'],
                    'mtu': module.params['network_mtu']
                })

                if i == 0:
                    networks.append({
                        'id': 'ipv4-%s' % nic_id,
                        'link': nic_id,
                        'type': 'ipv4',
                        'ip_address': module.params['ipv4_address'],
                        'netmask': module.params['ipv4_subnet_mask'],
                        'dns_nameservers': module.params['ipv4_nameserver'],
                        'routes': [{
                            'network': '0.0.0.0',
                            'netmask': '0.0.0.0',
                            'gateway': module.params['ipv4_gateway']
                        }]
                    })
                else:
                    networks.append({
                        'id': 'ipv4-dhcp-%s' % nic_id,
                        'link': nic_id,
                        'type': 'ipv4_dhcp',
                    })

        services = []
        if module.params['ipv4_nameserver']:
            for item in module.params['ipv4_nameserver']:
                services.append({
                    'type': 'dns',
                    'address': item
                })

        network_metadata = {
            'links': links,
            'networks': networks,
            'services': services
        }
    facts = {'network_metadata': network_metadata}

    module.exit_json(changed=False, ansible_facts=facts)


# this is magic, see lib/ansible/module_common.py
from ansible.module_utils.basic import *  # noqa: E402

if __name__ == '__main__':
    main()
