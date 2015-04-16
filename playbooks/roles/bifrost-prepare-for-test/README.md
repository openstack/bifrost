bifrost-prepare-for-test
========================

Enrolls nodes that have been stood up by the deployment module in Bifrost, into the in-memory inventory for basic testing as hosts in the testvm group.

Requirements
------------

This role requires the baremetal_csv_file variable which is utilized to add entries to the in-memory inventory.

Role Variables
--------------

baremetal_csv_file: This is the CSV file that defines the list of nodes to enroll and deploy as part of Bifrost.

Dependencies
------------

This role is dependent upon an environment having been installed with the install-ironic role, as well as by the bifrost-config-drives and bifrost-setup-nodes roles.

As this role is purely for testing, dependencies are not hard coded into the role.

Example Playbook
----------------

- hosts: localhost
  connection: local
  name: "Executes install, enrollment, and testing in one playbook"
  sudo: no
  gather_facts: yes
  roles:
    - role: bifrost-configdrives
    - role: bifrost-setup-nodes
    - role: bifrost-prepare-for-test

License
-------

Copyright (c) 2015 Hewlett-Packard Development Company, L.P.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express orimplied.
See the License for the specific language governing permissions and
limitations under the License.

Author Information
------------------

Ironic Developers
