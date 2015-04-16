#!/usr/bin/python
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
module: os_ironic_node
short_description: Activate/Deactivate Bare Metal Resources from OpenStack
extends_documentation_fragment: openstack
description:
    - Deploy to nodes controlled by Ironic.
options:
    state:
      description:
        - Indicates desired state of the resource
      choices: ['present', 'absent']
      default: present
    uuid:
      description:
        - globally unique identifier (UUID) to be given to the resource.
      required: false
      default: None
    ironic_url:
      description:
        - If noauth mode is utilized, this is required to be set to the
          endpoint URL for the Ironic API.  Use with "auth" and "auth_type"
          settings set to None.
      required: false
      default: None
    config_drive:
      description:
        - A configdrive file or HTTP(S) URL that will be passed along to the
          node.
      required: false
      default: None
    instance_info:
      description:
        - Definition of the instance information which is used to deploy
          the node.  This information is only required when an instance is
          set to present.
        image_source:
          description:
            - An HTTP(S) URL where the image can be retrieved from.
        image_checksum:
          description:
            - The checksum of image_source.
        image_disk_format:
          description:
            - The type of image that has been requested to be deployed.
    maintenance:
      description:
        - FUTURE: A setting to allow the direct control if a node is in
          maintenance mode.
      required: false
      default: false
    maintenance_reason:
      description:
        - FUTURE: A string expression regarding the reason a node is in a
          maintenance mode.
      required: false
      default: None

requirements: ["shade"]
'''

EXAMPLES = '''
# Activate a node by booting an image with a configdrive attached
os_ironic_node:
  cloud: "openstack"
  uuid: "d44666e1-35b3-4f6b-acb0-88ab7052da69"
  state: present
  config_drive: "http://192.168.1.1/host-configdrive.iso"
  instance_info:
    image_source: "http://192.168.1.1/deploy_image.img"
    image_checksum: "356a6b55ecc511a20c33c946c4e678af"
    image_disk_format: "qcow"
  delegate_to: localhost
'''


def _choose_id_value(module):
    if module.params['uuid']:
        return module.params['uuid']
    if module.params['name']:
        return module.params['name']
    return None


# TODO(TheJulia): Change this over to use the machine patch method
# in shade once it is available.
def _prepare_instance_info_patch(instance_info):
    patch = []
    patch.append({
        'op': 'replace',
        'path': '/instance_info',
        'value': instance_info
    })
    return patch


def _is_true(value):
    true_values = [True, 'yes', 'Yes', 'True', 'true', 'present', 'on']
    if value in true_values:
        return True
    return False


def _is_false(value):
    false_values = [False, None, 'no', 'No', 'False', 'false', 'absent', 'off']
    if value in false_values:
        return True
    return False


def _check_set_maintenance(module, cloud, node):
    if _is_true(module.params['maintenance']):
        if node['maintenance'] is False:
            cloud.set_machine_maintenance_state(
                node['uuid'],
                True,
                reason=module.params['maintenance_reason'])
            return True
        else:
            # User has requested maintenance state, node is already in the
            # desired state, checking to see if the reason has changed.
            if (node['maintenance_reason'] is not
                    module.params['maintenance_reason']):
                cloud.set_machine_maintenance_state(
                    node['uuid'],
                    True,
                    reason=module.params['maintenance_reason'])
                return True
    elif _is_false(module.params['maintenance']):
        if node['maintenance'] is True:
            cloud.set_machine_maintenance_state(
                node['uuid'],
                True,
                reason=module.params['maintenance_reason'])
            return True
    else:
        module.fail_json(msg="maintenance parameter was set but a valid "
                             "the value was not recognized.")
    return False


def _check_set_power_state(module, cloud, node):
    if (node['power_state'] is 'active' and module.params['state'] is 'off'):
        # User has requested the node be powered off.
        cloud.set_machine_power_off(node_id)
        return True
    if (node['power_state'] is 'power off' and
            node['provision_state'] is not 'available'):
        # Node is powered down when it is not awaiting to be provisioned
        cloud.set_machine_power_on(node_id)
        return True
    # Default False if no action has been taken.
    return False


def main():
    argument_spec = openstack_full_argument_spec(
        uuid=dict(required=False),
        name=dict(required=False),
        instance_info=dict(type='dict', required=False),
        config_drive=dict(required=False),
        ironic_url=dict(required=False),
        state=dict(required=False, default='present'),
        maintenance=dict(required=False),
        maintenance_reason=dict(required=False),
    )
    module_kwargs = openstack_module_kwargs()
    module = AnsibleModule(argument_spec, **module_kwargs)
    if not HAS_SHADE:
        module.fail_json(msg='shade is required for this module')
    if (module.params['auth_type'] in [None, 'None'] and
            module.params['ironic_url'] is None):
        module.fail_json(msg="Authentication appears disabled, Please "
                             "define an ironic_url parameter")

    if (module.params['ironic_url'] and
            module.params['auth_type'] in [None, 'None']):
        module.params['auth'] = dict(
            endpoint=module.params['ironic_url']
        )

    node_id = _choose_id_value(module)

    if not node_id:
        module.fail_json(msg="A uuid or name value must be defined "
                             "to use this module.")
    try:
        cloud = shade.operator_cloud(**module.params)
        node = cloud.get_machine(node_id)

        if node is None:
            module.fail_json(msg="node not found")

        uuid = node['uuid']
        instance_info = module.params['instance_info']
        changed = False

        # User has reqeusted desired state to be in maintenance state.
        if module.params['state'] is 'maintenance':
            module.params['maintenance'] = True

        if node['provision_state'] in [
                'cleaning',
                'deleting',
                'wait call-back']:
            module.fail_json(msg="Node is in %s state, cannot act upon the "
                                 "request as the node is in a transition "
                                 "state" % node['provision_state'])
        # TODO(TheJulia) This is in-development code, that requires
        # code in the shade library that is still in development.
        #
        # if _check_set_maintenance(module, cloud, node):
        #    if node['provision_state'] is 'active':
        #        module.exit_json(changed=True,
        #                         result="Maintenance state changed")
        #    changed = True
        #    node = cloud.get_machine(node_id)
        # if _check_set_power_state(module, cloud, node):
        #    if node['provision_state'] is 'active':
        #        module.exit_json(changed=True, result="Power state changed")
        #    else:
        #        changed = True
        #        node = cloud.get_machine(node_id)

        if _is_true(module.params['state']):
            if instance_info is None:
                module.fail_json(msg="When setting an instance to present, "
                                     "instance_info is a required variable.")
                # TODO(TheJulia): Update instance info, however info is
                # deployment specific. Perhaps consider adding rebuild
                # support, although there is a known desire to remove
                # rebuild support from Ironic at some point in the future.
            if node['provision_state'] is 'active':
                module.exit_json(
                    changed=changed,
                    result="Node already in an active state"
                )

            patch = _prepare_instance_info_patch(instance_info)
            cloud.set_node_instance_info(uuid, patch)
            cloud.validate_node(uuid)
            cloud.activate_node(uuid, module.params['config_drive'])
            # TODO(TheJulia): Add more error checking and a wait option.
            # We will need to loop, or just add the logic to shade,
            # although this could be a very long running process as
            # baremetal deployments are not a "quick" task.
            module.exit_json(changed=changed, result="node activated")

        elif _is_false(module.params['state']):
            if node['provision_state'] is not "deleted":
                cloud.purge_node_instance_info(uuid)
                cloud.deactivate_node(uuid)
                module.exit_json(changed=True, result="deleted")
            else:
                module.exit_json(changed=False, result="node not found")
        else:
            module.fail_json(msg="State must be present, absent, "
                                 "maintenance, off")

    except shade.OpenStackCloudException as e:
        module.fail_json(msg=e.message)


# this is magic, see lib/ansible/module_common.py
from ansible.module_utils.basic import *
from ansible.module_utils.openstack import *
main()
