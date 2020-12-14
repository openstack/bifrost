bifrost-cloud-config
====================

This role generate authentication parameters suitable for bare metal ansible
modules. It is designed to be included from other roles and is of little use
otherwise.

Requirements
------------

None

Role Variables
--------------

This role supports one variable:

`noauth_mode`

Whether bifrost has been installed in no-authentication mode.
Defaults to `false`.

This role sets several facts:

`openstack`

OpenStack configuration as returned by the `openstack.cloud.config`
module. May be missing in no-auth mode.

`openstack_cloud`

The cloud to use for authentication. May be missing in no-auth mode.

`auth`

An object with authentication information. If the fact is already defined,
it is only overridden in no-auth mode.

`auth_type`

Authentication plugin to use. If `auth` is already defined, it is only
overridden in no-auth mode.

`ironic_url`

Ironic endpoint to use. If the fact is already defined, it is not overridden.

`tls_certificate_path`

Path to the TLS certificate. Only set if TLS is used.

Notes
-----

None

Dependencies
------------

None at this time.

Example Playbook
----------------

```
- hosts: localhost
  connection: local
  become: no
  gather_facts: no
  roles:
    - role: bifrost-cloud-config
      noauth_mode: false
```

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
