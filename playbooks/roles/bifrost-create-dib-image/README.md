bifrost-create-dib-image
========================

This role uses diskimage-builder to create a bootable disk image.

Requirements
------------

This role requires:

- Ansible 1.9

Role Variables
--------------

The dib_env_vars are settings for the diskimage-builder environment variables which allow settings to be passed to elements that are being utilized to build a disk image.  More information on diskimage-builder can be found at http://git.openstack.org/cgit/openstack/diskimage-builder/.  Additionally, an extra_dib_elements setting exists which is a space separated list of elements to incorporate into the image.

dib_env_vars:
  DIB_CLOUD_INIT_DATASOURCES: "ConfigDrive"
  ELEMENTS_PATH: "/opt/stack/diskimage-builder/elements"
extra_dib_elements: ""

http_boot_folder, deploy_image_filename, and deploy_image all control the final destination of the built image.

http_boot_folder: /httpboot
deploy_image_filename: "deployment_image.qcow2"
deploy_image: "{{http_boot_folder}}/{{deploy_image_filename}}"

dib_os_element controls which OS will be used to build the image.

dib_os_element: "ubuntu"

Dependencies
------------

dib-utils must be installed from pip for the image creation to work.

Example Playbook
----------------

- hosts: localhost
  connection: local
  name: "Build DIB image"
  sudo: yes
  gather_facts: yes
  roles:
    - role: bifrost-create-dib-image


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

