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

deploy_url_protocol: The protocol to utilize to access config_drive and
                     image_source files. The default is to utilize HTTP in
                     generated HTTP URLs for bifrost, however this setting
                     allows a user to change that default if they have
                     a modified local webserver configuration.

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

noauth_mode: Controls if the module is called in noauth mode.
             By default, this is the standard mode of operation,
             however if set to false, the role utilizes os_client_config
             which expects a clouds.yml file.  More information about
             this file format can be found at:
             http://docs.openstack.org/developer/os-client-config/

cloud_name: Optional: String value defining a clouds.yaml entry for
            the ansible module to leverage.

inventory_dns: A boolean value, defaulted to false, which causes the role
               to update a template file and reload dnsmasq upon each update
               in order to perform static dns addressing utilizing the
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
