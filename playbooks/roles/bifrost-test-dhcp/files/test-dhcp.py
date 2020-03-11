# Copyright (c) 2016 Hewlett-Packard Enterprise Development Company LP
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

from __future__ import print_function
import csv
import json
import os
import sys


def _load_data_from_csv(path):
    with open(path) as csvfile:
        csvdata = [row for row in csv.reader(csvfile)]
    inventory = {}
    # NOTE(pas-ha) convert to structure similar to JSON inventory
    for entry in csvdata:
        mac = entry[0]
        hostname = entry[10]
        ip = entry[11]
        inventory[hostname] = {
            'nics': [{'mac': mac}],
            'name': hostname,
            'ipv4_address': ip
        }
    return inventory


def _load_data_from_json(path):
    with open(path) as jsonfile:
        inventory = json.load(jsonfile)
    return inventory


def main(argv):
    # first item is the inventory_dhcp setting
    # second item is the inventory_dhcp_static_ip setting
    inventory_dhcp = (argv[0] == 'True' or argv[0] == 'true')
    inventory_dhcp_static_ip = (argv[1] == 'True' or argv[1] == 'true')

    if not inventory_dhcp:
        # nothing to validate
        sys.exit(0)

    # load data from json file
    if os.path.exists('/tmp/baremetal.json'):
        inventory = _load_data_from_json('/tmp/baremetal.json')
    # load data from csv file
    elif os.path.exists('/tmp/baremetal.csv'):
        try:
            inventory = _load_data_from_csv('/tmp/baremetal.csv')
        except Exception:
            # try load *.csv as json for backward compatibility
            inventory = _load_data_from_json('/tmp/baremetal.csv')
    else:
        print('ERROR: Inventory file has not been generated')
        sys.exit(1)

    # now check that we only have these entries in leases file
    leases = []
    if not os.path.exists('/var/lib/misc/dnsmasq.leases'):
        if not os.path.exists('/var/lib/dnsmasq/dnsmasq.leases'):
            print('ERROR: dnsmasq leases file has not been generated')
            sys.exit(1)
        else:
            dns_path = '/var/lib/dnsmasq/dnsmasq.leases'
    else:
        dns_path = '/var/lib/misc/dnsmasq.leases'

    with open(dns_path) as csvfile:
        leases_reader = csv.reader(csvfile, delimiter=' ')
        for row in leases_reader:
            leases.append(row)

    # first we test number of entries
    if len(leases) != len(inventory):
        print('ERROR: Number of entries do not match with inventory')
        sys.exit(1)

    # then we check that all macs and hostnames are present
    for value in inventory.values():
        # NOTE(pas-ha) supporting only single nic
        mac = value['nics'][0]['mac']
        hostname = value['name']
        ip = value['ipv4_address']

        # mac check
        for lease_entry in leases:
            if lease_entry[1] == mac:
                break
        else:
            print('ERROR: No mac found in leases')
            sys.exit(1)

        # hostname check
        for lease_entry in leases:
            if lease_entry[3] == hostname:
                # if we use static ip, we need to check that ip matches
                # with hostname in leases
                if inventory_dhcp_static_ip:
                    if lease_entry[2] != ip:
                        print('ERROR: IP does not match with inventory')
                        sys.exit(1)
                break
        else:
            print('ERROR: No hostname found in leases')
            sys.exit(1)

    sys.exit(0)


if __name__ == "__main__":
    main(sys.argv[1:])
