ironic-inspect-node
===================

Invokes ironic node introspection logic using the os_ironic_inspect module.

Requirements
------------

None at this time.  See Dependencies.

Role Variables
--------------

uuid: The UUID of the node to invoke ironic node introspection upon.
      This variable is not required if the node name is supplied as
      ironic requires unique names.

name: A node name to invoke inspection upon.  This variable is not
      required if the node uuid value is supplied.

noauth_mode: Controls if the module is called in noauth mode.
             By default, this is the standard mode of operation,
             however if set to false, the role utilizes os_client_config
             which expects a clouds.yml file.  More information about
             this file format can be found at:
             https://docs.openstack.org/os-client-config/latest/

cloud_name: Optional: String value defining a clouds.yaml entry for
            the ansible module to leverage.
inspection_wait_timeout: Integer value in seconds, defaults to 1800.
                         This value may need to be adjusted if the underlying
                         openstacksdk library's default timeout is insufficient
                         for a node to perform an inspection sequence with.
                         The timeout assumption in the library was
                         based upon there being three phases to complete
                         an inspection sequence, BIOS POST, (i)PXE,
                         and then booting of the ramdisk and IPA.
                         In most cases, each phase should be completed
                         under 300 seconds, although that will vary based
                         upon the hardware configuration.

inventory_dhcp: A boolean value, defaulted to false, which allows dnsmasq
                to configure the IP of the machines, rather than putting
                the IP configuration of the machine in the config drive.
                If set to true, the role will create a file for each machine
                under /etc/dnsmasq.d/bifrost.dhcp-hosts.d containing the mac,
                name of the machine, lease time and optionally the IP address
                that will be offered to the machine by DHCP.
                This optional IP is controlled by the inventory_dhcp_static_ip
                parameter.

inventory_dhcp_static_ip: A boolean value, defaulted to true, which configures
                          the mechanism for setting up the IP of machines when
                          inventory_dhcp is enabled.
                          If set to true, it will read the value of the key
                          'provisioning_ipv4_address' from the inventory section
                          of each machine and dnsmasq will assign that IP to each
                          machine accordingly. Note, that if you don't assign
                          the key 'provisioning_ipv4_address' it will default
                          to the value of 'ipv4_address'.
                          If set to false, dnsmasq will assign IPs
                          automatically from the configured DHCP range.

inventory_dns: A boolean value, defaulted to false, which causes the role
               to update a template file and reload dnsmasq upon each update
               in order to perform static dns addressing utilizing the
               ipv4_address parameter.

Dependencies
------------

This role is dependent upon the os_ironic_inspect module being
available for use.

Example Playbook
----------------

hosts: testvm
  name: "Introspect node"
  become: no
  gather_facts: no
  roles:
    - role: ironic-inspect-node

License
-------

Copyright (c) 2015 Hewlett-Packard Development Company, L.P.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Author Information
------------------

Ironic Developers
