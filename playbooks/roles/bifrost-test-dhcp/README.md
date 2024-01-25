bifrost-test-dhcp
=================

Perform checks on dnsmasq generated files to ensure that it
behaves as expected on bifrost.

Requirements
------------

None at this time.  See Dependencies.

Role Variables
--------------

None at this time.  See Dependencies.

Dependencies
------------

This role is intended to be executed as part of bifrost, as part
of bifrost-test-dhcp scripts.

Example Playbook
----------------

hosts: localhost
  name: "Tests DHCP settings"
  become: no
  gather_facts: yes
  remote_user: root
  roles:
    - role: bifrost-test-dhcp

License
-------

Copyright (c) 2016 Hewlett-Packard Enterprise Development Company LP

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

Infra-cloud Developers
