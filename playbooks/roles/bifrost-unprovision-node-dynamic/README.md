bifrost-unprovision-node-dynamic
=================================

This role unprovisions nodes.  Essentially calls
`ironic node-set-provisioned-state <uuid> deleted`

Requirements
------------

An enrolled node, with the node uuid set as a host level variable.

The os_ironic_node module is required.

Role Variables
--------------

uuid: The UUID value for the node, at the host level.

ironic_url: The setting defining the URL to the Ironic API.  Presently
            defaulted to: "http://localhost:6385/"

noauth_mode: Controls if the module is called in noauth mode.
             By default, this is the standard mode of operation,
             however if set to false, the role utilizes os_client_config
             which expects a clouds.yml file.  More information about
             this file format can be found at:
             https://docs.openstack.org/os-client-config/latest/

cloud_name: Optional: String value defining a clouds.yaml entry for
            the ansible module to leverage.

Dependencies
------------

This role has no roles that it is directly dependent upon, but expects that the
environment has been installed with the bifrost-ironic-install role.

Example Playbook
----------------

- hosts: baremetal
  connection: local
  name: "Unprovisions the test node"
  become: no
  gather_facts: no
  roles:
    - role: bifrost-unprovision-node-dynamic

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
