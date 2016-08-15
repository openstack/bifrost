bifrost-create-vm-nodes
=======================

This role creates virtual machines for testing bifrost.

Requirements
------------

The following packages are required and ensured to be present:
- libvirt-bin
- qemu-utils
- qemu-kvm
- sgabios


Role Variables
--------------

baremetal_csv_file: "/tmp/baremetal.csv"

test_vm_memory_size: Tunable setting to allow a user to define a specific
                     amount of RAM in MB to allocate to guest/test VMs.
                     Defaults to "3072". Note: if this setting is modified
                     between test runs, you may need to undefine the test
                     virtual machine(s) that were previously created.

test_vm_domain_type: Tunable setting to allow a user to chosee the domain
                     type of the created VMs. The default is "qemu" and can
                     be set to kvm to enable kvm acceleration.

test_vm_num_nodes: Tunable setting to allow a user to define the number of
                   test VMs that will be created. They will all be created
                   with same settings.

Dependencies
------------

None at this time.

Example Playbook
----------------

- hosts: localhost
  connection: local
  become: yes
  gather_facts: yes
  roles:
    - role: bifrost-create-vm-nodes

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
