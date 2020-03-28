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

try:
    import shade
    HAS_SHADE = True
except ImportError:
    HAS_SHADE = False

DOCUMENTATION = '''
---
module: os_ironic_facts
short_description: Searches Ironic and returns node facts.
extends_documentation_fragment: openstack
description:
    - Queries Ironic for a requested node and returns facts about
      the node, or fails if the node is not found.  This module actively
      prevents any passwords in the node driver_info from being returned.
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

requirements: ["shade", "six"]
'''

EXAMPLES = '''
# Enroll a node with some basic properties and driver info
- os_ironic_facts:
    name: "testvm1"
'''


def _choose_id_value(module):
    if module.params['uuid']:
        return module.params['uuid']
    if module.params['name']:
        return module.params['name']
    return None


def main():
    argument_spec = openstack_full_argument_spec(  # noqa: F405
        auth_type=dict(required=False),
        uuid=dict(required=False),
        name=dict(required=False),
        mac=dict(required=False),
        ironic_url=dict(required=False),
        skip_items=dict(required=False, type='list'),
    )
    module_kwargs = openstack_module_kwargs()  # noqa: F405
    module = AnsibleModule(argument_spec, **module_kwargs)  # noqa: F405

    if not HAS_SHADE:
        module.fail_json(msg='shade is required for this module')
    if (module.params['auth_type'] in [None, 'None'] and
            module.params['ironic_url'] is None):
        module.fail_json(msg="Authentication appears to be disabled, "
                             "Please define an ironic_url parameter")

    if (module.params['ironic_url'] and
            module.params['auth_type'] in [None, 'None']):
        module.params['auth'] = dict(
            endpoint=module.params['ironic_url']
        )

    try:
        cloud = shade.operator_cloud(**module.params)

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

            module.exit_json(changed=False, ansible_facts=facts)

        else:
            module.fail_json(msg="node not found.")

    except shade.OpenStackCloudException as e:
        module.fail_json(msg=e.message)


# this is magic, see lib/ansible/module_common.py
from ansible.module_utils.basic import *  # noqa: E402
from ansible.module_utils.openstack import *  # noqa: E402
main()
