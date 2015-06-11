ironic-delete
=============

Removes nodes from Ironic utilizing the os_ironic Ansible module that is installed by Bifrost.

Requirements
------------

This role expects an environment installed with ironic-install role, although the os_ironic ansible module and baremetal_csv_file variable are ultimately required.

Role Variables
--------------

baremetal_csv_file: This is the CSV file of nodes that is enumerated through for operations.

ironic_url: This is the url for the ironic server to connect to.  It is presently defaulted to "http://localhost:6385/".

Dependencies
------------

This role has no direct role dependencies although is expected to be executed as part of Bifrost's test sequence.

Example Playbook
----------------

- hosts: localhost
  connection: local
  name: "Unprovisions the test node"
  sudo: no
  gather_facts: no
  roles:
    - role: ironic-delete

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
