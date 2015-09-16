bifrost-ironic-install
======================

This role installs a standalone ironic deployment with all required substrate
in order for it to be utilized, including MySQL, RabbitMQ, dnsmasq, and
nginx.

Requirements
------------

This role requires:

- Ansible 1.9

Internet access was originally a requirement but no longer is. See
doc/source/offline-install.rst for details on installing without it.

Role Variables
--------------

Testing mode is intended to help facilitate testing of the bifrost roles and
ironic by utilizing virtual machines on the localhost and the agent_ssh
driver. This variable should be set globally for playbooks utilizing the
bifrost-ironic-install role.

testing: false

Node cleaning, which was a feature added to ironic during the Kilo cycle,
removes the previous contents of a node once it has been moved from an
active to available state, such as setting the provision state to deleted.
Bifrost disables this by default in order to allow initial users to not be
impacted by node cleaning operations upfront when they are testing and
evaluating bifrost. In the event of a production deployment, cleaning
should be enabled.

cleaning: false

The ironic python client and shade libraries can be installed directly from
Git. The default is to utilize pip to install the current versions in pypi,
however testing may require master branch or custom patches.

ironicclient_source_install: false
shade_source_install: false

Bifrost requires access to the network where nodes are located, in order to
provision the nodes. By default, this setting is set to a value for local
VM based testing, however if and when your ready to deploy to a physical
environment, you will need to set the network_interface variable to the
attached network.

network_interface: "virbr0"

By default this role installs dnsmasq to act as a DHCP server for provisioning
hosts.  In the event this is not required, set the following configuration:

include_dhcp_server: false

If you chose to utilize the dhcp server, You may wish to set default ranges:

dhcp_pool_start: 192.168.1.200
dhcp_pool_end: 192.168.1.250

In case your HW needs a kernel option to boot, set the following variable:

extra_kernel_options: Default undefined.

When testing, the default ironic conductor driver is "agent_ssh". When
testing mode has not been engaged, drivers can be set via the enabled_drivers
variable which defaults to: "agent_ipmitool,pxe_amt,agent_ilo,agent_ucs"

In the event of an external DHCP server being used, the user will need to
configure their DHCP server such that PXE, and iPXE chain loading occurs.
For additional information for setting up DHCP in this scenario refer to
the bifrost documentation file doc/source/deploy/dhcp.rst.

Additional default variables exist in defaults/main.yml, however these are
mainly limited to settings which are unlikely to be modified, unless a user
has a custom Ironic Python Agent image, or needs to modify where the httpboot
folder is set to.

This role has several variables that can vary between OS families,
distributions, and their specific versions. These are specified in the
required_defaults_* files.  They are imported in a particular
order. For example, for Ubuntu 15.04, the role will attempt to import
the following files:

- required_defaults_Debian.yml
- required_defaults_Ubuntu.yml
- required_defaults_Ubuntu_15.04.yml

Not all of the possible files for a given distribution/version combination
need to exist. The recommended approach for adding a new variable is:

- Put the variable in the most generic set of defaults to which it applies:
  for example, if a given variable is applicable to all Debian-family OSes,
  put it in required_defaults_Debian.yml

- Variables specified in the more specific files will be used to override
  values in the more generic defaults files.

- If a given default applies to multiple versions of a distribution, that
  variable needs to be specified for each version which it affects.

Dependencies
------------

None at this time.

Example Playbook
----------------

- hosts: localhost
  connection: local
  name: "Install ironic locally"
  sudo: yes
  gather_facts: yes
  roles:
    - role: bifrost-ironic-install
      cleaning: false
      testing: true
      network_interface: "virbr0"

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
