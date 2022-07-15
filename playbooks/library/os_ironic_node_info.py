#!/usr/bin/env python
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

from ansible_collections.openstack.cloud.plugins.module_utils.ironic import (
    IronicModule,
    ironic_argument_spec,
)
from ansible_collections.openstack.cloud.plugins.module_utils.openstack import (  # noqa: E501
    openstack_module_kwargs,
    openstack_cloud_from_module
)
try:
    import openstack
    HAS_SDK = True
except ImportError:
    HAS_SDK = False

DOCUMENTATION = '''
---
module: os_ironic_node_info
short_description: Searches Ironic and returns node information.
extends_documentation_fragment: openstack
description:
    - Queries Ironic for a requested node and returns "node" variable with
      information about the node, or fails if the node is not found. This
      module actively prevents any passwords in the node driver_info from being
      returned.
options:
    mac:
      description:
        - unique mac address that is used to attempt to identify the host.
      required: false
      default: None
    uuid:
      description:
        - globally unique identifier (UUID) to identify the host.
      required: false
      default: None
    name:
      description:
        - unique name identifier to identify the host in Ironic.
      required: false
      default: None
    ironic_url:
      description:
        - If noauth mode is utilized, this is required to be set to the
          endpoint URL for the Ironic API.  Use with "auth" and "auth_type"
          settings set to None.
      required: false
      default: None

requirements: ["openstacksdk"]
'''

EXAMPLES = '''
# Get information about the node called "testvm1" and store in "node_info.node"
- os_ironic_node_info:
    name: "testvm1"
  register: node_info
'''


def _choose_id_value(module):
    if module.params['uuid']:
        return module.params['uuid']
    if module.params['name']:
        return module.params['name']
    return None


def main():
    argument_spec = ironic_argument_spec(  # noqa: F405
        uuid=dict(required=False),
        name=dict(required=False),
        mac=dict(required=False),
        skip_items=dict(required=False, type='list'),
    )
    module_kwargs = openstack_module_kwargs()  # noqa: F405
    module = IronicModule(argument_spec, **module_kwargs)
    module.deprecate('os_ironic_node_info is deprecated, please use '
                     'openstack.cloud.baremetal_node_info')

    if not HAS_SDK:
        module.fail_json(msg='openstacksdk is required for this module')

    try:
        sdk, cloud = openstack_cloud_from_module(module)
        if module.params['name'] or module.params['uuid']:
            server = cloud.get_machine(_choose_id_value(module))
        elif module.params['mac']:
            server = cloud.get_machine_by_mac(module.params['mac'])
        else:
            module.fail_json(msg="The worlds did not align, "
                                 "the host was not found as "
                                 "no name, uuid, or mac was "
                                 "defined.")
        if server:
            facts = dict(server)
            new_driver_info = dict()
            # Rebuild driver_info to remove any password values
            # as they will be masked.
            for key, value in facts['driver_info'].items():
                if 'password' not in key:
                    new_driver_info[key] = value
            if new_driver_info:
                facts['driver_info'] = new_driver_info

            for item in module.params['skip_items']:
                if item in facts:
                    del facts[item]

            # Remove ports and links as they are useless in the ansible
            # use context.
            if "ports" in facts:
                del facts["ports"]
            if "links" in facts:
                del facts["links"]

            nics = cloud.list_nics_for_machine(server['uuid'])
            facts['nics'] = [{'mac': nic['address']} for nic in nics]

            module.exit_json(changed=False, node=facts)

        else:
            module.fail_json(msg="node not found.")

    except openstack.exceptions.SDKException as e:
        module.fail_json(msg=e.message)


main()
