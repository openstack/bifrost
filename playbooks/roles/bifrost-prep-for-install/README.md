bifrost-prep-for-install
========================

This role performs the initial file downloads to allow a user to install
bifrost.  It does not require internet access, as new URLs or local
filesystem clones of repositories can be defined.

Requirements
------------

This role requires:

- Ansible 1.9

Internet access was originally a requirement for installation, however access
is no longer required.  See doc/source/offline-install.rst for details on
installing without it.

Role Variables
--------------

git_root: The base location for cloned git repositories.  This defaults to
          "/opt/stack".

ironicclient_git_url: URL for ironicclient, defaults to:
                      https://git.openstack.org/openstack/python-ironicclient

shade_git_url: URL for shade, defaults to:
               https://git.openstack.org/openstack-infra/shade

ironic_git_url: URL for ironic, defaults to:
                https://git.openstack.org/openstack/ironic

ironicclient_git_folder: The folder to clone ironicclient to if missing,
                         defaults to: "{{ git_root}}/ironicclient.git"

ironic_git_folder: The folder to clone ironic to if missing, default to:
                   "{{ git_root}}/ironic.git"

shade_git_folder: The folder to clone shade to if missing, defaults to:
                  "{{ git_root}}/shade.git"

ironicclient_git_branch: Branch to install, defaults to "master".

ironic_git_branch: Branch to install, defaults to "master".

shade_git_branch: Branch to install, defaults to "master".

copy_from_local_path: Boolean value, defaults to false. If set to true,
                      the role will attempt to perform a filesystem copy of
                      locally defined git repositories instead of cloning
                      the local repositories in order to preserve the
                      pre-existing repository state.  This is largely
                      something that is needed in CI testing if dependent
                      changes are pre-staged in the local repositories.

ci_testing_zuul: Boolean value, default false. This value is utilized
                 to tell the preparatory playbook when the prep role
                 is running in a CI system with Zuul, which in such
                 cases the repositories must be copied, not overwritten.
Dependencies
------------

None at this time.

Example Playbook
----------------

- hosts: localhost
  connection: local
  name: "Install Ironic"
  become: yes
  gather_facts: yes
  roles:
    - { role: bifrost-prep-for-install, when: skip_install is not defined }
    - role: bifrost-ironic-install
      cleaning: false
      testing: true

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
