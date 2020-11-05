#!/usr/bin/env python3
#
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
import os
import sys

from oslo_config import cfg
from oslo_log import log
import yaml

try:
    import openstack
    SDK_LOADED = True
except ImportError:
    SDK_LOADED = False

DOCUMENTATION = '''
Bifrost Inventory Module
========================

This is a dynamic inventory module intended to provide a platform for
consistent inventory information for Bifrost.

The inventory supplies two distinct groups by default:

    - localhost
    - baremetal

The localhost group is required for Bifrost to perform local actions to
bifrost for local actions such as installing Ironic.

The baremetal group contains the hosts defined by the data source along with
variables extracted from the data source. The variables are defined on a
per-host level which allows explicit actions to be taken based upon the
variables.

It is also possible for users to specify additional per-host groups by
simply setting the host_groups variable in the inventory file. See below for
an example JSON file.

The default group can also be changed by setting the DEFAULT_HOST_GROUPS
variable to contain the desired groups separated by whitespace as follows:

DEFAULT_HOST_GROUPS="foo bar zoo"

In case of provisioning virtual machines, additional per-VM groups can
be set by simply setting the test_vm_groups[$host] variable to a list
of desired groups. Moreover, users can override the default 'baremetal'
group by assigning a list of default groups to the test_vm_default_group
variable.

Presently, the base mode of operation reads a JSON/YAML file in the format
originally utilized by bifrost and returns structured JSON that is
interpreted by Ansible.

Conceivably, this inventory module can be extended to allow for direct
processing of inventory data from other data sources such as a configuration
management database or other inventory data source to provide a consistent
user experience.

How to use?
-----------

    export BIFROST_INVENTORY_SOURCE=/tmp/baremetal.[json|yaml]
    ansible-playbook playbook.yaml -i inventory/bifrost_inventory.py

One can also just directly invoke bifrost_inventory.py in order to see the
resulting JSON output.  This module also has a feature to support the
pass-through of a pre-existing JSON document, which receives updates and
formatting to be supplied to Ansible.  Ultimately the use of JSON will be
far more flexible and should be the preferred path forward.

Example JSON Element:

{
  "node1": {
    "uuid": "a8cb6624-0d9f-c882-affc-046ebb96ec01",
    "host_groups": [
        "nova",
        "neutron"
    ],
    "driver_info": {
      "power": {
        "ipmi_target_channel": "0",
        "ipmi_username": "ADMIN",
        "ipmi_address": "192.168.122.1",
        "ipmi_target_address": "0",
        "ipmi_password": "undefined",
        "ipmi_bridging": "single"
      }
    },
    "nics": [
      {
        "mac": "00:01:02:03:04:05"
      }.
      {
        "mac": "00:01:02:03:04:06"
      }
   ],
   "driver": "ipmi",
   "ipv4_address": "192.168.122.2",
   "properties": {
      "cpu_arch": "x86_64",
      "ram": "3072",
      "disk_size": "10",
      "cpus": "1"
    },
    "name": "node1"
  }
}

Utilizing ironic as the data source
-----------------------------------

The functionality exists to allow a user to query an existing ironic
installation for the inventory data.  This is an advanced feature,
as the node may not have sufficient information to allow for node
deployment or automated testing, unless DHCP reservations are used.

This setting can be invoked by setting the source to "ironic"::

  export BIFROST_INVENTORY_SOURCE=ironic

Known Issues
------------

At present, this module only supports inventory list mode and is not
intended to support specific host queries.
'''

LOG = log.getLogger(__name__)

opts = [
    cfg.BoolOpt('list',
                default=True,
                help='List active hosts'),
]


def _parse_config():
    """
    Parse the options.

    Args:
    """
    config = cfg.ConfigOpts()
    log.register_options(config)
    config.register_cli_opts(opts)
    config(prog='bifrost_inventory.py')
    config.set_override('use_stderr', True)
    log.set_defaults()
    log.setup(config, "bifrost_inventory.py")
    return config


def _prepare_inventory():
    """
    Prepare the inventory dict.

    Args:
    """
    hostvars = {"127.0.0.1": {"ansible_connection": "local"}}
    groups = {}
    groups.update({'baremetal': {'hosts': []}})
    groups.update({'localhost': {'hosts': ["127.0.0.1"]}})
    return (groups, hostvars)


def _process_baremetal_data(data_source, groups, hostvars):
    """Process data through as pre-formatted data"""
    with open(data_source, 'rb') as file_object:
        try:
            file_data = yaml.safe_load(file_object)
        except Exception as e:
            LOG.error("Failed to parse JSON or YAML: %s", e)
            raise Exception("Failed to parse JSON or YAML")

    node_names = os.environ.get('BIFROST_NODE_NAMES', None)
    if node_names:
        node_names = node_names.split(',')

    for name in file_data:
        if node_names and name not in node_names:
            continue

        host = file_data[name]
        # Perform basic validation
        node_net_data = host.get('node_network_data')
        ipv4_addr = host.get('ipv4_address')
        default_groups = os.environ.get('DEFAULT_HOST_GROUPS',
                                        'baremetal').split()
        host['host_groups'] = sorted(list(set(host.get('host_groups', []) +
                                              default_groups)))

        if not node_net_data and not ipv4_addr:
            host['addressing_mode'] = "dhcp"
        else:
            host['ansible_ssh_host'] = host['ipv4_address']

        if ('provisioning_ipv4_address' not in host and
                'addressing_mode' not in host):
            host['provisioning_ipv4_address'] = host['ipv4_address']
        # Add each host to the values to be returned.
        for group in host['host_groups']:
            if group not in groups:
                groups.update({group: {'hosts': []}})
            groups[group]['hosts'].append(host['name'])
        hostvars.update({host['name']: host})
    return (groups, hostvars)


def _process_sdk(groups, hostvars):
    """Retrieve inventory utilizing OpenStackSDK."""
    # NOTE(dtantsur): backward compatibility
    if os.environ.get('IRONIC_URL'):
        print("WARNING: IRONIC_URL is deprecated, use OS_ENDPOINT")
        os.environ['OS_ENDPOINT'] = os.environ['IRONIC_URL']
    if os.environ.get('OS_ENDPOINT') and not os.environ.get('OS_AUTH_URL'):
        os.environ['OS_AUTH_TYPE'] = None

    cloud = openstack.connect()
    machines = cloud.list_machines()

    node_names = os.environ.get('BIFROST_NODE_NAMES', None)
    if node_names:
        node_names = node_names.split(',')

    for machine in machines:
        if 'properties' not in machine:
            machine = cloud.get_machine(machine['uuid'])
        if machine['name'] is None:
            name = machine['uuid']
        else:
            name = machine['name']

        if node_names and name not in node_names:
            continue

        new_machine = {}
        for key, value in machine.items():
            # NOTE(TheJulia): We don't want to pass infomrational links
            # nor do we want to pass links about the ports since they
            # are API endpoint URLs.
            if key not in ['links', 'ports']:
                new_machine[key] = value

        # NOTE(TheJulia): Collect network information, enumerate through
        # and extract important values, presently MAC address. Once done,
        # return the network information to the inventory.
        nics = cloud.list_nics_for_machine(machine['uuid'])
        new_nics = []
        for nic in nics:
            new_nic = {}
            if 'address' in nic:
                new_nic['mac'] = nic['address']
            new_nics.append(new_nic)
        new_machine['nics'] = new_nics

        new_machine['addressing_mode'] = "dhcp"
        groups['baremetal']['hosts'].append(name)
        hostvars.update({name: new_machine})
    return (groups, hostvars)


def main():
    """Generate a list of hosts."""
    config = _parse_config()

    if not config.list:
        LOG.error("This program must be executed in list mode.")
        sys.exit(1)

    (groups, hostvars) = _prepare_inventory()

    if 'BIFROST_INVENTORY_SOURCE' not in os.environ:
        LOG.error('Please define a BIFROST_INVENTORY_SOURCE environment '
                  'variable with a comma separated list of data sources')
        sys.exit(1)

    try:
        data_source = os.environ['BIFROST_INVENTORY_SOURCE']
        if os.path.isfile(data_source):
            try:
                (groups, hostvars) = _process_baremetal_data(
                    data_source,
                    groups,
                    hostvars)
            except Exception as e:
                LOG.error("BIFROST_INVENTORY_SOURCE does not define "
                          "a file that could be processed: %s."
                          "Tried JSON and YAML formats", e)
                sys.exit(1)
        elif "ironic" in data_source:
            if SDK_LOADED:
                (groups, hostvars) = _process_sdk(groups, hostvars)
            else:
                LOG.error("BIFROST_INVENTORY_SOURCE is set to ironic "
                          "however the openstacksdk library failed to load, "
                          "and may not be present.")
                sys.exit(1)
        else:
            LOG.error('BIFROST_INVENTORY_SOURCE does not define a file')
            sys.exit(1)

    except Exception as error:
        LOG.error('Failed processing: %s' % error)
        sys.exit(1)

    # Drop empty groups. This is usually necessary when
    # the default ["baremetal"] group has been overridden
    # by the user.
    for group in list(groups):
        # Empty groups
        if len(groups[group]['hosts']) == 0:
            del groups[group]

    # General Data Conversion

    inventory = {'_meta': {'hostvars': hostvars}}
    inventory.update(groups)
    print(json.dumps(inventory, indent=2))


if __name__ == '__main__':
    main()
