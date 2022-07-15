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


def get_network_data(params):
    links = []
    networks = []

    if params.get('ipv4_interface_mac'):
        nic_id = params['ipv4_interface_mac']

        if params.get('vlan_id'):
            nic_id = 'vlan-%s' % params['ipv4_interface_mac']

            links.append({
                'id': nic_id,
                'type': 'vlan',
                'vlan_id': params['vlan_id'],
                'vlan_link': params['ipv4_interface_mac'],
                'vlan_mac_address': params['ipv4_interface_mac'],
            })

        link = {
            'id': params['ipv4_interface_mac'],
            'type': 'phy',
            'ethernet_mac_address': params['ipv4_interface_mac'],
        }
        if params.get('network_mtu'):
            link['mtu'] = params['network_mtu']
        links.append(link)

        for nic in params['nics']:
            if nic['address'] == params['ipv4_interface_mac']:
                network = {
                    'id': 'ipv4-%s' % nic_id,
                    'link': nic_id,
                    'type': 'ipv4',
                    'ip_address': params['ipv4_address'],
                    'netmask': params['ipv4_subnet_mask'],
                    'routes': []
                }
                if params.get('ipv4_nameserver'):
                    network['dns_nameservers'] = \
                        params['ipv4_nameserver']
                if params.get('ipv4_gateway'):
                    network['routes'].append({
                        'network': '0.0.0.0',
                        'netmask': '0.0.0.0',
                        'gateway': params['ipv4_gateway']
                    })
                networks.append(network)
    else:
        for i, nic in enumerate(params['nics']):
            nic_id = nic['address']
            if params.get('vlan_id'):
                nic_id = 'vlan-%s' % nic['address']

                links.append({
                    'id': nic_id,
                    'type': 'vlan',
                    'vlan_id': params['vlan_id'],
                    'vlan_link': nic['address'],
                    'vlan_mac_address': nic['address']
                })

            link = {
                'id': nic['address'],
                'type': 'phy',
                'ethernet_mac_address': nic['address'],
            }
            if params.get('network_mtu'):
                link['mtu'] = params['network_mtu']
            links.append(link)

            if i == 0:
                network = {
                    'id': 'ipv4-%s' % nic_id,
                    'link': nic_id,
                    'type': 'ipv4',
                    'ip_address': params['ipv4_address'],
                    'netmask': params['ipv4_subnet_mask'],
                    'routes': []
                }
                if params.get('ipv4_nameserver'):
                    network['dns_nameservers'] = \
                        params['ipv4_nameserver']
                if params.get('ipv4_gateway'):
                    network['routes'].append({
                        'network': '0.0.0.0',
                        'netmask': '0.0.0.0',
                        'gateway': params['ipv4_gateway']
                    })
                networks.append(network)
            else:
                networks.append({
                    'id': 'ipv4-dhcp-%s' % nic_id,
                    'link': nic_id,
                    'type': 'ipv4_dhcp',
                })

    services = []
    if params.get('ipv4_nameserver'):
        for item in params['ipv4_nameserver']:
            services.append({
                'type': 'dns',
                'address': item
            })

    return {
        'links': links,
        'networks': networks,
        'services': services
    }


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
        network_metadata = get_network_data(module.params)
    facts = {'network_metadata': network_metadata}

    module.exit_json(changed=False, ansible_facts=facts)


# this is magic, see lib/ansible/module_common.py
from ansible.module_utils.basic import *  # noqa: E402

if __name__ == '__main__':
    main()
