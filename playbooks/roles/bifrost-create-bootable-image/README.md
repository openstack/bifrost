bifrost-create-bootable-image
=============================

This role modifies an existing partition image to create a bootable disk image.
This role is now legacy code and will not be supported in future.

Requirements
------------

This role requires:

- Ansible 1.9
- qemu-img
- kpartx
- The partition image must have the grub bootloader installed.

Role Variables
--------------

http_boot_folder, deploy_image_filename, and deploy_image all control the final
destination of the built image.

http_boot_folder: /httpboot
deploy_image_filename: "partition_image.raw"
deploy_image: "{{http_boot_folder}}/{{deploy_image_filename}}"

Dependencies
------------

None at this time.

Example Playbook
----------------

- hosts: localhost
  connection: local
  name: "Create bootable image"
  become: yes
  gather_facts: yes
  roles:
    - role: bifrost-create-bootable-image


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
