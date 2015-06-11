bifrost-validate-host-for-deploy
================================

Preforms basic sanity checks of an Ironic node as part of Bifrost host before nodes are provisioned.

Requirements
------------

This role performs basic validation of an Ironic installation resulting from the execution of the ironic-install role.  As such, that role is required to have been previously executed, however is not required to be executed as part of the same playbook.

Role Variables
--------------

Along the lines of most of the other Bifrost roles, this playbook requires a variable "baremetal_csv_file".  This role does _not_ automatically set or assume the location of this file for the reason that this file must be defined by the user.  This variable is utilized to validate that the file defined is, in fact, a file.

The other variable of note is "deploy_image" which is the image to be deployed to the end host.  If executed in concert with other roles for node deployment, this should be defined as a common variable for all of the roles.

Dependencies
------------

This role is dependent upon the results of the install-ironic role having been previously applied to the host.

The bifrost-setup-nodes role is dependent upon this role for node validation.

Example Playbook
----------------

- hosts: localhost
  connection: local
  sudo: no
  vars:
    baremetal_csv_file: "/path/to/baremetal.csv"
    deploy_image: "/httpboot/deployment_image.qcow2"
  roles:
    - role: bifrost-validate-host-for-deploy
    - role: bifrost-configdrives
    - role: bifrost-setup-nodes

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
