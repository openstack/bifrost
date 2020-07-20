bifrost-prep-for-install
========================

This role performs the initial file downloads to allow a user to install
bifrost.  It does not require internet access, as new URLs or local
filesystem clones of repositories can be defined.

Requirements
------------

This role requires:

- Ansible 2.9

Internet access was originally a requirement for installation, however access
is no longer required.  See doc/source/offline-install.rst for details on
installing without it.

Role Variables
--------------

git_root: The base location for cloned git repositories.  This defaults to
          "/opt/stack".

git_url_root: The base URL for remote git repositories. Defaults to
              https://opendev.org

ironicclient_git_url: URL for ironicclient, defaults to:
                      {{ git_url_root }}/openstack/python-ironicclient

openstacksdk_git_url: URL for openstacksdk, defaults to:
                      {{ git_url_root }}/openstack/openstacksdk

ironic_git_url: URL for ironic, defaults to:
                {{ git_url_root }}/openstack/ironic

sushy_git_url: URL for sushy, defaults to:
               {{ git_url_root }}/openstack/sushy

ironicclient_git_folder: The folder to clone ironicclient to if missing,
                         defaults to: "{{ git_root}}/ironicclient.git"

ironic_git_folder: The folder to clone ironic to if missing, default to:
                   "{{ git_root}}/ironic.git"

openstacksdk_git_folder: The folder to clone openstacksdk to if missing,
                         defaults to: "{{ git_root}}/openstacksdk.git"

sushy_git_folder: The folder to clone sushy to if missing, default to:
                  "{{ git_root}}/sushy.git"

git_branch: Default branch to install, defaults to "master".

ironicclient_git_branch: Branch to install, defaults to the value of
                         git_branch.

ironic_git_branch: Branch to install, defaults to the value of git_branch.

openstacksdk_git_branch: Branch to install, defaults to the value of
                         git_branch.

dib_git_branch: Branch to install, defaults to "master".

ironicinspector_git_branch: Branch to install, defaults to the value of
                            git_branch.

ironicinspectorclient_git_branch: Branch to install, defaults to
                                  the value of git_branch.

reqs_git_branch: Branch to install, defaults to the value of git_branch.

staging_drivers_git_branch: Branch to install, defaults to the value of
                            git_branch.

keystone_git_branch: Branch to install, defaults to the value of git_branch.

sushy_git_branch: Branch to install, defaults to the value of git_branch.

copy_from_local_path: Boolean value, defaults to false. If set to true,
                      the role will attempt to perform a filesystem copy of
                      locally defined git repositories instead of cloning
                      the local repositories in order to preserve the
                      pre-existing repository state.  This is largely
                      something that is needed in CI testing if dependent
                      changes are pre-staged in the local repositories.
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
    - role: bifrost-prep-for-install
      when: not (skip_install | default(false) | bool)
    - role: bifrost-ironic-install
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
