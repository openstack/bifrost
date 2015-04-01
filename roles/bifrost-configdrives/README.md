bifrost-configdrives
====================

Creates configdrives for nodes being provisioned in Bifrost.

Requirements
------------

This playbook is intended to be executed prior to the deployments of nodes via the bifrost-setup-nodes role, as part of Bifrost.  It creates a basic configuration drive containing network configuration and an SSH key permitting the user to login to the host.

Role Variables
--------------

This role, like the other deployment related bifrost playbooks are intended to be executed with the "baremetal_csv_file" variable which points to the file used to define the enrolled nodes that wish to be deployed upon.

Additional key variables are:

ipv4_subnet_mask:  This is the subnet mask(e.g. 255.255.255.0 or similar) that matches the static addressing which desires to be imprinted into the configuraiton drive.
ipv4_gateway: This is the IPv4 defaut router address with-in the IPv4 subnet being utilized for IP addresses for the nodes being deployed.
node_default_network_interface: This is the default network interface with-in the nodes to be deployed which the new IP configuration will be applied to.  Note: This is likely to be deprecated and removed in the future as Bifrost will likely change methods utilized to include networking configuration into the configuration drive sufficiently that this should no longer be required.
ipv4_nameserver: Defines the IPv4 Nameserver to configure the node with initially in order to support name resolution.
ssh_public_key_path: Defines the path to the file to be SSH public key to be inserted into the configuraiton drive.
ssh_public_key: If a user wishes to define an SSH public key as a string, this variable can be utilized which overrides ssh_public_key_path.

Customizing
-----------

The attempt with this playbook is to create a very simple and easilly modifable configuraiton drive to be loaded to the remote machine.  This is naturally done each time the role is executed for every node defined in the baremetal_csv_file.  If one wishes to insert additional files, this can be done by editing the tasks/main.yml file.  As the drives are generated in a stepwise fashion, it is important to make note of and use the "{{item.split(',')[9]}}" variable as that is utilized to deliniate the file destinations between different configuration drives.

Additional detail on the format of configuraiton drives can be found at http://docs.openstack.org/user-guide/content/enable_config_drive.html.

If one wishes to manually modify a configuration drive after the fact, the files are base64 encoded, gzip compressed, ISO9660 filesystems.  Ironic will fail the deployment of the configuration drive if the file is not first found to be base64 encoded, and then gzip compressed.  Alternatively, the configuration drive can be a vfat filesystem, although this carries with it some risks if the filesystem is always treated as a source of truth upon system boot.

One final note.  The size of the configuration drives is limited to 64MB.  This is not a limit of Bifrost, but a limit due to the code utilized to write the configuration drive out.

Dependencies
------------

This role is expected to be executed on a system that has had the ironic-install role executed upon it, however as the configuration drive creation step is fairly self contained, it can be executed as a separate step.

Example Playbook
----------------

- hosts: localhost
  connection: local
  sudo: no
  roles:
    - role: bifrost-configdrives

License
-------

Copyright (c) 2015 Hewlett-Packard Development Company, L.P.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express orimplied.
See the License for the specific language governing permissions and
limitations under the License.

Author Information
------------------

Ironic Developers
