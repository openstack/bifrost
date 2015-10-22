bifrost-prepare-for-test-dynamic
================================

Removes and re-adds the nodes to the SSH known_hosts file when the
variable ipv4_address is defined.

Requirements
------------

Role Variables
--------------

ipv4_address: The host IPv4 address defined on each host to perform
              the action to.

node_ssh_pause: The amount of time, defaulted to 4 seconds, to pause
                before attempting to connect to the node.  This is
                useful if the test image has a tendency to have
                networking restart after sshd has started.

wait_timeout: The number of seconds to wait for SSH connectivity to
              the test machine to be established before proceeding.

Dependencies
------------

As this role is purely for testing, dependencies are not hard
coded into the role.  The role expects to be executed after
bifrost-deploy-nodes-dynamic where a node ipv4_address is defined
on the host level.

Example Playbook
----------------

- hosts: baremetal
  connection: local
  name: "Adds and removes a .ssh/known_hosts entry"
  become: no
  gather_facts: no
  roles:
    - role: bifrost-prepare-for-test-dynamic

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
