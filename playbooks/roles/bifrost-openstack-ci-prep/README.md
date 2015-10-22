bifrost-openstack-ci-prep
=========================

This role is intended to be utilized in order to set the installation
environment and various job settings that are specific to OpenStack CI
such that the bifrost CI job is able to complete successfully.

Requirements
------------

This role requires:

- Ansible 1.9


Role Variables
--------------

ssh_public_key_path: The path to where the SSH public key can be located.
                     If missing, it is created.

ironic_git_folder: The folder where the ironic codebase has been cloned to.

ironicclient_git_folder: The folder where the python-ironicclient code base
                         has been cloned to.

shade_git_folder: The folder where the shade code base has been cloned to.

ansible_env.ZUUL_CHANGES: The list of changes from Zuul that need to be
                          applied to the cloned repositories before testing
                          can proceed.

Dependencies
------------

None at this time.

Example Playbook
----------------

In this example below, specific facts based on environment variables are
utilized to engage the role, which first calls bifrost-prep-for-install
which clones the repositories and resets their state to a known state.

The ci_testing_zuul fact is set in the pre_tasks below to allow for activation
of the logic to properly handle an OpenStack CI environment node.

- hosts: localhost
  connection: local
  name: "Prepare for installation"
  become: no
  gather_facts: yes
  pre_tasks:
    - name: "Set ci_testing_zuul if it appears we are running in upstream OpenStack CI"
      set_fact:
         ci_testing: true
         ci_testing_zuul: true
         ironic_git_url: /opt/git/openstack/ironic
         ironicclient_git_url: /opt/git/openstack/python-ironicclient
         shade_git_url: /opt/git/openstack-infra/shade
      when: lookup('env', 'ZUUL_BRANCH') != ""
    - name: "Set ci_testing_zuul_changes if ZUUL_CHANGES is set"
      set_fact:
         ci_testing_zuul_changes: true
      when: lookup('env', 'ZUUL_CHANGES') != ""
  roles:
    - { role: bifrost-prep-for-install, when: skip_install is not defined }
    - { role: bifrost-openstack-ci-prep, when: ci_testing_zuul is defined }


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
