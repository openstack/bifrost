bifrost-deploy-nodes-dynamic
============================

Provisions nodes based on inventory utilizing the os_ironic_node module
installed by Bifrost.

Requirements
------------

This role is expected to be executed on a node that the
"bifrost-ironic-install" node has been executed upon.

This role expects to be executed in a sequence with
bifrost-configdrives-dynamic, however that is unnecessary IF the host has a
dictionary named instance_info defined as that will be used as overriding
values.

Role Variables
--------------

ironic_url: This is the URL to the ironic server.  By default, this is set to
            "http://localhost:6385/"

network_interface: This is the network interface that the nodes receive
                   DHCP/PXE/iPXE.  This is utilized to generate the url that
                   Ironic is configured with for image retrieval. This 
                   variable does not have a default in this role and expects to
                   receive this information from the calling playbook.

deploy_image_filename: This is the filename of the image to deploy, which is
                       combined with the network_interface variable to generate
                       a URL used to set the ironic instance image_source. This
                       variable does not have a default in this role and
                       expects to receive this information from the calling
                       playbook.

deploy_image: This is the full path to the image to be deployed to the system.
              This is as ironic requires the MD5 hash of the file to be
              deployed for validation during the deployment process.  As a
              result of this requirement, the hash is automatically collected
              and submitted to ironic with the node deployment request. This
              variable does not have a default in this role and expects to
              receive this information from the calling playbook.

instance_info: A dictionary containing the information to define an instance.
               By default, this is NOT expected to be defined, however if
               defined it is passed in whole to the deployment step.  This
               value will override deploy_image_filename, deploy_image, and
               network_interface variables. Key-value pairs that are generally
               expected are image_source, image_checksum, root_gb, however,
               any supported key/value can be submitted to the API.

inventory_dhcp: A boolean value, defaulted to false, which causes the role
                to update a template file and reload dhsmasq upon each update
                in order to perform static dhcp assignments utilizing the
                ipv4_address parameter.
Dependencies
------------

This role is intended to be executed upon a node that the
bifrost-ironic-install role has been executed upon.  The configuration that
is leveraged by this role utilizes a configuration drive to place network
configuration and an SSH key on the newly deployed host.  As such, the
bifrost-configdrives role is required.

Example Playbook
----------------

NOTE: The example below assumes bifrost's default and that an instance_info
      variable is not defined.

      - hosts: baremetal
        connection: local
        become: no
        roles:
          - role: bifrost-configdrives
          - role: bifrost-deploy-nodes-dynamic

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
