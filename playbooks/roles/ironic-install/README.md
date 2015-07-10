ironic-install
=========

This role installs a standalone ironic deployment with all required substrate in order for it to be utilized, including MySQL, RabbitMQ, dnsmasq, nginx.

Requirements
------------

This role requires:

- Ansible 1.9

Internet access was originally a requirement but no longer is.  See doc/source/offline-install.rst for details on installing without it.

Role Variables
--------------

Testing mode is intended to help facilitate testing of the Bifrost roles and Ironic by utilizing virtual machines on the localhost and the agent_ssh driver.  This variable should be set globally for playbooks utilizing the install-ironic role.

testing: false

Node cleaning, which was a feature added to Ironic during the Kilo cycle, removes the previous contents of a node once it has been deleted.  Bifrost sets this to true by default, however if testing mode is enabled,

cleaning: true

The Ironic python client and shade libraries can be installed directly from GIT.  The default is to utilize pip to install the current versions in pypi, however testing may require master branch or custom patches.  

ironicclient_source_install: false
shade_source_install: false

By default this role installs dnsmasq to act as a DHCP server for provisioning hosts.  In the event this is not required, set the following configuration:

include_dhcp_server: false

In the event of an external DHCP server being used, the user will need to configure their DHCP server such that PXE, and iPXE chain loading occurs. For additional information for setting up DHCP in this scenario refer to the Bifrost documentation file doc/source/deploy/dhcp.rst.
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
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Author Information
------------------

Ironic Developers
