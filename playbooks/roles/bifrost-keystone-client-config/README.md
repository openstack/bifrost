bifrost-keystone-client-config
==============================

This is a simple role intended for writing out a clouds.yaml
file for Bifrost with the cloud name "bifrost".

Requirements
------------

None

Role Variables
--------------

This role expects to be invoked with seven variables:

- config_username
- config_password
- config_project_name
- config_region_name
- config_auth_url
- user: Username of the user who will own the
         configuration file.

Additionally, two optional variables exist, which when not defined
default to "default":

- config_project_domain_id
- config_user_domain_id

The resulting clouds.yaml file, will be created at
~{{user}}/.config/openstack/clouds.yaml.

Notes
-----

None

Dependencies
------------

None at this time.

Example Playbook
----------------

- hosts: localhost
  connection: local
  name: "Create clouds.yaml file""
  become: no
  gather_facts: no
  roles:
    - role: bifrost-keystone-client-config
      config_username: username
      config_password: password
      config_project_name: baremetal
      config_region_name: RegionOne
      config_auth_url: http://localhost:5000/v2.0/
      user: joe

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
