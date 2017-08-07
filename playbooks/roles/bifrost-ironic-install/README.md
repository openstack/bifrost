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
ironic by utilizing virtual machines on the localhost and the agent_ipmitool
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
VM based testing, however if and when you're ready to deploy to a physical
environment, you will need to set the network_interface variable to the
attached network.

network_interface: "virbr0"

By default this role installs dnsmasq to act as a DHCP server for provisioning
hosts.  In the event this is not required, set the following configuration:

include_dhcp_server: false

If you chose to utilize the dhcp server, You may wish to set default ranges:

dhcp_pool_start: 192.168.1.200
dhcp_pool_end: 192.168.1.250

And also set the default dhcp address lease time:

dhcp_lease_time: 12h

Alternatively, a user can choose to perform static DHCP assignments to nodes.
This can be enabled by setting the ``inventory_dhcp`` setting to ``true``.
This will result in the ``dhcp_pool_start`` and ``dhcp_pool_end`` settings
only being used to define the range of valid ips to be accepted, and the
``ipv4_address`` setting being bound to the first listed MAC address for
the node.
If you choose to use the static DHCP assignments, you may need to set
the ``dhcp_static_mask`` setting according to your needs. It defaults to
a /24 range.
In the case of static inventory, please also consider to set the
``dhcp_lease_time`` setting to infinite, to avoid unnecessary refreshes
of ips.

If you want to force all hostnames to resolve to ``ipv4_address`` set on
the inventory, please set the ``inventory_dns`` setting to ``true``.

In case your HW needs a kernel option to boot, set the following variable:

extra_kernel_options: Default undefined.

When testing, the default ironic conductor driver is "agent_ipmitool". When
testing mode has not been engaged, drivers can be set via the enabled_drivers
variable which defaults to: "agent_ipmitool,agent_ilo,agent_ucs"

By default, PXE driver baseline support, in terms of installation of the
iSCSI client and configuration of sudoers and rootwrap configuration is
enabled. If you wish to disable this functionality, set
``enable_pxe_drivers`` to a value of ``false``.

enable_pxe_drivers: false

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
  for example, if a given variable is applicable to all Debian-family
  operating systems, put it in required_defaults_Debian.yml

- Variables specified in the more specific files will be used to override
  values in the more generic defaults files.

- If a given default applies to multiple versions of a distribution, that
  variable needs to be specified for each version which it affects.

If you wish to enable Cross-Origin Resource Sharing (CORS), such as to
connect a javascript based web client, options have been added to allow
a user to enable the integrated support.

By default, this support is disabled, but the configuration options are below:

enable_cors: Boolean value, default false, to enable CORS support.

cors_allowed_origin: A URL string that represents the origin sent by the
                     client web browser. If CORS is enabled, and this is
                     not set, it will default to http://localhost:8000/.

enable_cors_credential_support: Boolean value, default false.  This variable
                                toggles the CORS configuration to expect user
                                authentication.  Since bifrost makes use of
                                noauth mode, this realistically should not
                                be modified.

domain: String value, default to false. If set, domain setting is configured
        in dnsmasq.

remote_syslog_server: String value, default undefined. If set, rsyslog is
                      configured to send logs to this server.

remote_syslog_port: String value, default is 514. If set, custom port is
                    configured for remote syslog server.

ironic_log_dir: String value, default undefined. If set, it specifies a
                a non-default log directory for ironic.

inspector_log_dir: String value, default undefined. If set, it specifies a
                   non-default log directory for inspector.

nginx_log_dir: String value, default /var/log/nginx. It specifies a log
               directory for nginx.

### Hardware Inspection Support

Bifrost also supports the installation of ironic-inspector in standalone
mode, which enables the user to allow for identification of the system
properties via a workflow.

enable_inspector: Boolean value, default true.  Set this value to false to
                  prevent installing ironic-inspector.

inspector_auth: Sets ironic-inspector's authentication method. Possible values
                are `keystone` and `noauth`. `noauth` is recommended since
                bifrost by default installs ironic as standalone without
                keystone. The default value is `noauth`.

inspector_debug: Boolean value, default true. Enables debug level logging
                 for inspector. Note that this default may change in
                 future.

inspector_manage_firewall: Boolean value, default false. Controls whether
                           ironic-inspector should manage the firewall
                           rules of the host. Bifrost's installation playbook
                           adds the rule to permit the callback traffic,
                           so you shouldn't need to enable this.

ironic_auth_strategy: Sets the `auth_strategy` ironic-inspector should use
                      with ironic.  Possible values are `noauth` and
                      `keystone`. The default value is `noauth`.

inspector_data_dir: Base path for ironic-inspector's temporary data and log
                    files. The default location is
                    `/opt/stack/ironic-inspector/var`.

inspector_port_addition: Defines which MAC addresses to add as ports during
                         introspection. Possible values are `all`, `active`,
                         and `pxe`. The default value is `pxe`.

inspector_keep_ports: Defines which ports on a node to keep after
                      introspection. Possible values are `all`, `present`,
                      and `added`. The default value is `present`.

inspector_store_ramdisk_logs: Boolean value, default true. Controls if the
                              inspector agent will retain logs from the
                              ramdisk that called the inspector service.

enable_inspector_discovery: Boolean value, default true. This instructs
                            inspector to add new nodes that are discovered
                            via PXE booting on the same network to ironic.

inspector_default_node_driver: The default driver to utilize when adding
                               discovered nodes to ironic.
                               The default value set by bifrost is
                               `agent_ipmitool`. Users should change this
                               setting for their install environment if
                               an alternative default driver is required.

inspector_extra_kernel_options: String value, default undefined. Extra
                                kernel parameters for the inspector default
                                PXE configuration.

inspector_processing_hooks: String value containing a comma-separated list,
                            default undefined. Use this to specify a
                            non-default list of comma-separated processing
                            hooks for inspector.

### Virtual Environment Install

Bifrost can install ironic into a python virtual environment using the
following configuration options:

enable_venv: Enables virtual environment support. Boolean value; the default
             is false. enable_venv is automatically defined as true if VENV
             is set in the user's environment.

bifrost_venv_dir: The full path of the virtual environment directory. The
                  default value is /opt/stack/bifrost. When VENV is set in
                  the user's environment, its contents will be used to set
                  bifrost_venv_dir.

bifrost_venv_env: An environment dictionary that includes the environment
                  variables used to run commands which require the virtual
                  environment. The default values are derived from the
                  standard 'activate' script which virtualenv installs.
                  It is best not to reset this value unless you know you
                  need to.

ssh_private_key_path: Defines the path to the SSH private key file to be
                      placed as default ssh key for ironic user. Can be useful
                      when ironic requires ssh access to another server.

ssh_private_key: If a user wishes to define an SSH private key as a string,
                 this variable can be utilized which overrides the
                 ssh_private_key_path setting.

### Changing Database Configuration

Bifrost utilizes a nested data stucture for the configuration of database.
Simply put:

  - Values cannot be overrriden via set_fact.
  - Values cannot be overrriden via the command line with ``-e``.
  - The entire data structure must be defined if is modified.

Please see defaults/main.yml file for the structure named ``ironic``.

Please note, if the hostname is set to something besides``localhost``,
then the playbook will not attempt to create databases, database users,
and grant privileges.

Similarly, if hardware introspection support is installed, the
nearly identical data structure for inspector can be found in the
same file named ``ironic_inspector``.

Notes
-----

This role, by default, deploys an alternative boot.ipxe file to the one
that ironic deploys, and configures ironic to use this alternative file.
This is because not every boot case can be covered. If you encounter a
case where you find that you need to modify the file, please notify us
by filing a bug in Launchpad, https://bugs.launchpad.net/bifrost/.

Dependencies
------------

None at this time.

Example Playbook
----------------

- hosts: localhost
  connection: local
  name: "Install ironic locally"
  become: yes
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
