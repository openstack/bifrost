Role Name
=========

This role installs a standalone ironic deployment with all required substrate in order for it to be utilized, including MySQL, RabbitMQ, dnsmasq, nginx.  Additionally, it utilizes diskimage-builder to create a bootable disk image.

Requirements
------------

This role requires:

- Ansible 1.9
- Internet Access

Role Variables
--------------

A description of the settable variables for this role should go here, including any variables that are in defaults/main.yml, vars/main.yml, and any variables that can/should be set via parameters to the role. Any variables that are read from other roles and/or the global scope (ie. hostvars, group vars, etc.) should be mentioned here as well.

Testing mode is intended to help facilitate testing of the Bifrost roles and Ironic by utilizing virtual machines on the localhost and the agent_ssh driver.  This variable should be set globally for playbooks utilizing the install-ironic role.

testing: false

Node cleaning, which was a feature added to Ironic during the Kilo cycle, removes the previous contents of a node once it has been deleted.  Bifrost sets this to true by default, however if testing mode is enabled,

cleaning: true

The Ironic python client and shade libraries can be installed directly from GIT.  The default is to utilize pip to install the current versions in pypi, however testing may require master branch or custom patches.  

ironicclient_source_install: false
shade_source_install: false

The dib_env_vars are settings for the diskimage-builder environment variables which allow settings to be passed to elements that are being utilized to build a disk image.  More information on diskimage-builder can be found at http://git.openstack.org/cgit/openstack/diskimage-builder/.  Additionally, an extra_dib_elements setting exists which is a space separated list of elements to incorporate into the image.

dib_env_vars:
  DIB_CLOUD_INIT_DATASOURCES: "ConfigDrive"
  ELEMENTS_PATH: "/opt/stack/diskimage-builder/elements"
extra_dib_elements: ""

As for controlling if a partition image is utilized or an image is created with diskimage-builder, the following two settings which are mutually exclusive, can allow a user to choose which logic is utilized.

create_image_via_dib: true
transform_boot_image: false

By default this role installs dnsmasq to act as a DHCP server for provisioning hosts.  In the event this is not required, set the following configuration:

include_dhcp_server: false

In the event of an external DHCP server being used, the user will need to configure their DHCP server such that PXE, and iPXE chain loading occurs.

Additional default variables exist in defaults/main.yml, however these are mainly limited to settings which are unlikely to be modified, unless a user has a custom Ironic Python Agent image, or needs to modify where the httpboot folder is set to.

Dependencies
------------

None at this time.

Example Playbook
----------------

- hosts: localhost
  connection: local
  name: "Install Ironic Locally"
  sudo: yes
  gather_facts: yes
  roles:
    - role: ironic-install
      cleaning: false
      testing: true

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

