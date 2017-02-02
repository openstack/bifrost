bifrost-keystone-client-config
==============================

This is a simple role intended for writing out a clouds.yaml
file for Bifrost with the cloud name "bifrost".

Requirements
------------

None

Role Variables
--------------

This role expects to be invoked with two variables:

- user: Username of the user who will own the
         configuration file.
- clouds: a dictionary with keys being names of the clouds to create in
          clouds.yaml, and values are dictionaries of authentication
          parameters for each cloud:
    - config_username
    - config_password
    - config_project_name
    - config_region_name
    - config_auth_url
    - config_project_domain_id (optional, defaults to 'default')
    - config_user_domain_id (optional, defaults to 'default')

Alternatively, for backward compatibility, the role can accept the above
`config_*` variables directly, but this is deprecated.
In this case, a single cloud named 'bifrost' will be written.

The resulting clouds.yaml file will be created at
~{{user}}/.config/openstack/clouds.yaml.
If several sets of cloud settings are written, they will be sorted by
cloud name, in case-insensitive order.

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
      user: joe
      clouds:
        local-cloud-user:
          config_username: username
          config_password: password
          config_project_name: baremetal
          config_region_name: RegionOne
          config_auth_url: http://localhost:5000
        local-cloud-admin:
          config_username: admin
          config_password: verysecretpassword
          config_project_name: admin
          config_region_name: RegionOne
          config_auth_url: http://localhost:5000

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
