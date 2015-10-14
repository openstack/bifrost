bifrost-create-dib-image
========================

This role uses diskimage-builder to create a bootable disk image or ramdisk.

Requirements
------------

This role requires:

- Ansible 1.9

Role Variables
--------------

The role can use the disk-image-create or ramdisk-image-create scripts. Which
script is used is controlled by the build_ramdisk variable. The default is
false.

build_ramdisk: false

The dib_env_vars are settings for the diskimage-builder environment variables
which allow settings to be passed to elements that are being utilized to build
a disk image.  More information on diskimage-builder can be found at:
http://git.openstack.org/cgit/openstack/diskimage-builder/

dib_env_vars:
  DIB_CLOUD_INIT_DATASOURCES: "ConfigDrive"
  ELEMENTS_PATH: "/opt/stack/diskimage-builder/elements"

The final destination of the image is specified by dib_imagename.

dib_imagename: "/path/to/image.qcow2"

dib_os_element controls which OS will be used to build the image.

dib_os_element: "ubuntu"

dib_elements is a space-separated list of elements that will be
added to the resulting disk image.

dib_elements: "vm serial-console simple-init"

dib_packages is a comma-separated list of packages to be installed
on the resulting disk image.

dib_packages: "traceroute,python-devel"

All the other command-line options to disk-image-create or
ramdisk-image-create can be used by the role. The following is a list
of the command-line options, their corresponding variables, and the type
of the value to supply. Please refer to the help text for disk-image-create
for further information.

| Option              | Variable name    | Value                |
-----------------------------------------------------------------
| -x                  | dib_trace        | boolean              |
| -u                  | dib_uncompressed | boolean              |
| -c                  | dib_clearenv     | boolean              |
| --no-tmpfs          | dib_notmpfs      | boolean              |
| --offline           | dib_offline      | boolean              |
| -n                  | dib_skipbase     | boolean              |
| -a                  | dib_arch         | arch                 |
| -o                  | dib_imagename    | /path/to/image       |
| -t                  | dib_imagetype    | image type           |
| --image-size        | dib_imagesize    | size in GB           |
| --image-cache       | dib_imagecache   | /path/to/cache       |
| --max-online-resize | dib_maxresize    | size in blocks       |
| --min-tmpfs         | dib_mintmpfs     | size in GB           |
| --mkfs-options      | dib_mkfsopts     | mkfs flags           |
| --qemu-img-options  | dib_qemuopts     | comma-separated list |
| --root-label        | dib_rootlabel    | label                |
| --ramdisk-element   | dib_rdelement    | element name         |
| -t                  | dib_installtype  | source or package    |

Dependencies
------------

dib-utils must be installed from pip for the image creation to work.

Example Playbook
----------------

- hosts: localhost
  connection: local
  name: "Build DIB image"
  become: yes
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

Ironic Developers
