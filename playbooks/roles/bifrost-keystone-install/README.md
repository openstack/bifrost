bifrost-keystone-install
========================

This role installs keystone for a bifrost/stand-alone ironic deployment
with all required substrate to allow for keystone configuration,
including MySQL, dnsmasq, and nginx.

Requirements
------------

This role requires:

- Ansible 2.1

Role Variables
--------------

Due to the required configuration steps, the configuration must be
fairly explicit. The defaults should work for a user without any
issues, however it is highly recommended that the parameters are
reviewed and modified prior to deployment.

The main settings are in a nested data structure under the name
``keystone``.  In order to logically separate the settings in order
to provide the greatest flexibility for change, under ``keystone``
exists three subsections.  ``bootstrap``, ``message_queue``, and
``database``.

The ``keystone.bootstrap`` settings provide the information to access
keystone as it provides the main administrative credentials.
If keystone is being installed, then these credentials will be used
to bootstrap the new keystone installation.
In addition to the bootstrap parameters, we provide the ability to
define the initial ``region_name``, as well as ``admin_url``,
``public_url``, and ``internal_url`` endpoints URLs for keystone.

If the intent is to utilize a pre-existing keystone service that has
already undergone bootstrapping, set the ``keystone.bootstrap.enabled``
setting to false, in order to prevent bifrost from attempting to
bootstrap a new keystone. The ``keystone.bootstrap`` settings are
expected to be available by the ``bifrost-ironic-install`` role,
which has the same datastructure available in it's defaults/main.yml
file. These settings are used by the ``birost-ironic-install`` role
in order to create users, roles, and endpoints for Ironic's operation.

Under the ``message_queue`` and ``database`` structures, variables
are used to define the connection URLs to the message queue,
and database.

Below is the full data structure.

  keystone:
    debug: true
    bootstrap:
      enabled: true
      username: admin
      password: ChangeThisPa55w0rd
      project_name: admin
      admin_url: "http://127.0.0.1:5000/v3/"
      public_url: "http://127.0.0.1:5000/v3/"
      internal_url: "http://127.0.0.1:5000/v3/"
      region_name: "RegionOne"
    message_queue:
      username: keystone
      password: ChangeThisPa55w0rd
      host: 127.0.0.1
      port: 5672
    database:
      name: keystone
      username: keystone
      password: ChangeThisPa55w0rd
      host: 127.0.0.1

Notes
-----

None

Dependencies
------------

The ansible module, os_keystone_session, is required by this module.

The env-setup.sh script should collect this file and place it in the
proper location prior to executing this role.

Example Playbook
----------------

# NOTE: The bifrost-keystone-install playbook
# should be run before the ironic install playbook
# to enable the same variables to be utilized.
- hosts: localhost
  connection: local
  name: "Install ironic locally"
  become: yes
  gather_facts: yes
  roles:
    - role: bifrost-keystone-install
    - role: bifrost-ironic-install

License
-------

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
