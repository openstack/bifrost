bifrost-test-inspection
=======================

Tests nodes that have been inspected by ironic inspector.

Requirements
------------

None at this time.  See Dependencies.

Role Variables
--------------

None at this time.  See Dependencies.

Dependencies
------------

This role is intended to be executed as part of bifrost, after the
ironic-inspect-node role, as part of the test sequence.

Example Playbook
----------------

    hosts: baremetal
    name: "Tests inspection of baremetal nodes"
    connection: local
    become: no
    gather_facts: no
    roles:
      - role: bifrost-test-inspection

License
-------

Copyright (c) 2018 StackHPC Ltd.

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
