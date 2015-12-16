ironic-inspect-node
===================

Invokes ironic node introspection logic using the os_ironic_inspect module.

Requirements
------------

None at this time.  See Dependencies.

Role Variables
--------------

uuid: The UUID of the node to invoke ironic node introspection upon.
      This variable is not required if the node name is supplied as
      ironic requires unique names.

name: A node name to invoke inspection upon.  This variable is not
      required if the node uuid value is supplied.

noauth_mode: Controls if the module is called in noauth mode.
             By default, this is the standard mode of operation,
             however if set to false, the role utilizes os_client_config
             which expects a clouds.yml file.  More information about
             this file format can be found at:
             http://docs.openstack.org/developer/os-client-config/

Dependencies
------------

This role is dependent upon the os_ironic_inspect module being
available for use.

Example Playbook
----------------

hosts: testvm
  name: "Introspect node"
  become: no
  gather_facts: no
  roles:
    - role: ironic-inspect-node

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
