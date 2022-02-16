ironic-enroll-dynamic
=====================

Enrolls nodes into Ironic utilizing the os_ironic Ansible module that is
installed by Bifrost.

Requirements
------------

This role is dependent upon the os-ironic ansible module, which is dependent
upon openstacksdk (https://opendev.org/openstack/openstacksdk/).

Role Variables
--------------

ironic_url: The setting defining the URL to the Ironic API.  Presently
            defaulted to: "http://localhost:6385/"

ipa_kernel: The kernel url, image id, or file representing the kernel to
            utilize for deploying to this node. This should be the kernel
            used for the Ironic Python Agent.

ipa_ramdisk: The ramdisk url, image id, or file representing the ramdisk
             image to utilize to deploy this node. This should be the ramdisk
             used for the Ironic Python Agent.

ipa_file_protocol: The protocol to utilize to access IPA files. The default is
                   to utilize HTTP in generated HTTP URLs for bifrost, however
                   this setting allows a user to change that default if they
                   they have a modified local webserver configuration.
                   Do note, that a user wishing to utilize HTTPS may wish to
                   review the iPXE documentation: https://ipxe.org/crypto

noauth_mode: Controls if the module is called in noauth mode.
             By default, this is the standard mode of operation,
             however if set to false, the role utilizes os_client_config
             which expects a clouds.yml file.  More information about
             this file format can be found at:
             https://docs.openstack.org/os-client-config/latest/

cloud_name: Optional: String value defining a clouds.yaml entry for
            the ansible module to leverage.

This role expects a data structure similar to the one below, however it should
be understood that the individual entries under `driver_info` can vary based
on the driver.

{
  "node1": {
    "uuid": "00000000-0000-0000-0000-000000000000",
    "driver_info": {
      "ipmi_target_channel": "0",
      "ipmi_username": "ADMIN",
      "ipmi_address": "192.168.122.1",
      "ipmi_target_address": "0",
      "ipmi_password": "undefined",
      "ipmi_bridging": "single"
    },
    "nics": [
      {
        "mac": "00:01:02:03:04:05"
      }.
   ],
   "driver": "ipmi",
   "ip_address": "192.168.122.2",
   "properties": {
      "cpu_arch": "x86_64",
      "ram": "3072",
      "disk_size": "10",
      "cpus": "1"
    },
    "name": "node1"
  }
}

Dependencies
------------

This role is presently dependent upon the bifrost-ironic-install role which
installs the necessary requirements.

Example Playbook
----------------

- hosts: baremetal
  connection: local
  name: "Executes enrollment of nodes into Ironic"
  roles:
    - role: ironic-enroll-dynamic

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
