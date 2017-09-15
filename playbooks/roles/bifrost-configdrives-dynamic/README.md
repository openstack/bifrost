bifrost-configdrives
====================

Creates configdrives for nodes being provisioned in bifrost.

Requirements
------------

This playbook is intended to be executed prior to the deployments of nodes
via the bifrost-deploy-nodes-dynamic role, as part of bifrost. It creates a
basic configuration drive containing network configuration and an SSH key
permitting the user to login to the host.

Role Variables
--------------

This role, like the other deployment related bifrost playbooks are expected
to be executed with the bifrost dynamic inventory or a compatible
configuration data source.

Additional key variables are:

addressing_mode: If defined and set to a value of "dhcp", this role sets the
                 primary interface to utilize DHCP.

ipv4_subnet_mask: This is the subnet mask(e.g. 255.255.255.0 or similar) that
                  matches the static addressing which desires to be imprinted
                  into the configuration drive.

ipv4_gateway: This is the IPv4 default router address within the IPv4 subnet
              being utilized for IP addresses for the nodes being deployed.

ipv4_interface_mac: Optional: The MAC address of the network interface to
                    assign the IPv4 address to.

node_default_network_interface: This is the default network interface within
                                the nodes to be deployed which the new IP
                                configuration will be applied to.
                                Note: This is likely to be deprecated and
                                removed in the future as bifrost will likely
                                change methods utilized to include networking
                                configuration into the configuration drive
                                sufficiently that this should no longer be
                                required.

ipv4_nameserver: Defines the IPv4 nameserver to configure the node with
                 initially in order to support name resolution. It accepts
                 a string with a single nameserver, or a list with several
                 ones.

ipv4_address: The IPv4 address of the node to be deployed, if applicable.

ironic_url: Defines URL to ironic API. Defaults to "http://localhost:6385/"

ssh_public_key_path: Defines the path to the SSH public key file to be
                     inserted into the configuration drive.

ssh_public_key: If a user wishes to define an SSH public key as a string,
                this variable can be utilized which overrides the
                ssh_public_key_path setting.

uuid: The UUID value for the node.

http_boot_folder: The folder where to save the configuration drive file to.

write_interfaces_file: Legacy option to write an debian style network
                       interfaces configuration file. This is required for
                       deployment where simple-init cannot be used, in
                       particular when using Cirros.

node_network_data: Optional: If defined, the contents are written out to the
                   network_data.json file, effectively allowing a user to
                   override the network configuration contents based on
                   the inventory data.

cloud_name: Optional: String value defining a clouds.yaml entry for
            the ansible module to leverage.

Customizing
-----------

The attempt with this playbook is to create a very simple and easily
modifiable configuration drive to be loaded to the remote machine.
This is done for each host that the role is run against. If one wishes
to insert additional files, this can be done by editing the tasks/main.yml
file.  As the drives are generated in a stepwise fashion, it is important
to make note of and use the "{{ uuid }}" variable as that is utilized to
delineate the file destinations between different configuration drives
that may be in the process of being created.

Additional detail on the format of configuration drives can be found at:
https://docs.openstack.org/os-client-config/latest/

If one wishes to manually modify a configuration drive after the fact,
the files are base64 encoded, gzip compressed, ISO9660 filesystems.
Ironic will fail the deployment of the configuration drive if the file
is not first found to be base64 encoded, and then gzip compressed.
Alternatively, the configuration drive can be a vfat filesystem,
although this carries with it some risks if the filesystem is always
treated as a source of truth upon system boot.

One final note. The size of the configuration drives is limited to 64MB.
This is not a limit of bifrost, but a limit due to the code utilized to
write the configuration drive out.

Dependencies
------------

This role is expected to be executed on a system that has had the
bifrost-ironic-install role executed upon it, however as the configuration
drive creation step is fairly self contained, it can be executed as a
separate step.

Example Playbook
----------------

- hosts: baremetal
  connection: local
  become: no
  roles:
    - role: bifrost-configdrives-dynamic

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
