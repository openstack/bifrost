Role Name
=========

Provisions nodes based on the contents of the file designated by baremetal_csv_file utilizing the os_ironic_node installed by Bifrost.

Requirements
------------

This role is expected to be executed on a node that the "ironic-install" node has been executed upon.

As configured, this role requires the "bifrost-configdrives" role be executed prior to this role, utilizing the baremetal_csv_file variable which defines the path to the CSV file which is utilized as the source of information for this role to operate.

Role Variables
--------------

baremetal_csv_file: This is the variable that references the CSV file which is utilized as the source of information for nodes to execute the role upon. This variable does not have a default in this role and expects to receive this information from the calling playbook.

ironic_url: This is the URL to the ironic server.  By default, this is set to "http://localhost:6385/"

network_interface: This is the network interface that the nodes receive DHCP/PXE/iPXE.  This is utilized to generate the url that Ironic is configured with for image retrieval. This variable does not have a default in this role and expects to receive this information from the calling playbook. 

deploy_image_filename: This is the filename of the image to deploy, which is combined with the network_interface variable to generate a URL used to set the Ironic instance image_source. iThis variable does not have a default in this role and expects to receive this informa
tion from the calling playbook.

deploy_image: This is the full path to the image to be deployed to the system.  This is as Ironic requires the MD5 hash of the file to be deployed for validation during the deployment process.  As a result of this requirement, the hash is automatically collected and submitted to Ironic with the node deployment request.  This variable does not have a default in this role and expects to receive this information from the calling playbook.

Dependencies
------------

This role is intended to be executed upon a node that the ironic-install role has been executed upon.  The configuration that is leveraged by this role utilizes a configuration drive to place network configuration and an SSH key on the newly deployed host.  As such, the bifrost-configdrives role is required.

Example Playbook
----------------

- hosts: localhost
  connection: local
  sudo: no
  roles:
    - role: bifrost-configdrives
    - role: bifrost-setup-nodes

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
