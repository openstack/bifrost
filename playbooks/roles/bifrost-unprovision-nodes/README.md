bifrost-unprovision-nodes
=========================

This role unprovisions nodes.  Essentially calls `ironic node-set-provisioned-state <uuid> deleted`


Requirements
------------

An enrolled node, and a baremetal.csv file provided via the environment variable baremetal_csv_file.

The os_ironic_node module is required.

Role Variables
--------------

baremetal_csv_file: This is the path to the CSV file which is enumerated through for nodes to be acted upon.

ironic_url: The setting defining the URL to the Ironic API.  Presently defaulted to: "http://localhost:6385/"

Dependencies
------------

This role has no roles that it is directly dependent upon directly, but expects that the environment has been installed with the ironic-install role.

Example Playbook
----------------

- hosts: localhost
  connection: local
  name: "Unprovisions the test node"
  sudo: no
  gather_facts: no
  roles:
    - role: bifrost-unprovision-nodes

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
