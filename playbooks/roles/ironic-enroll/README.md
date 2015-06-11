ironic-enroll
=============

Enrolls nodes into Ironic utilizing the os_ironic Ansible module that is installed by Bifrost.

Requirements
------------

This role is dependent upon the os-ironic ansible module, which is dependent upon shade (https://git.openstack.org/cgit/openstack-infra/shade), which in this case is presently dependent upon the Ironic Python Client Library (http://git.openstack.org/cgit/openstack/python-ironicclient/).

Role Variables
--------------

baremetal_csv_file: This variable is the path to a CSV file which contains a list of nodes to enroll into Ironic.  This file has a particular format based on columns, which will be listed below, however the base playbooks are easily modifiable to utilize less information as some of the information is not presently required.

The CSV file has the following columns:

0. MAC Address
1. Management username
2. Management password
3. Management Address
4. CPU Count
5. Memory size in MB
6. Disk Storage in GB
7. Flavor (Not Used)
8. Type (Not Used)
9. Host UUID
10. Host or Node name
11. Host IP Address to be set
12. ipmi_target_channel - Requires: ipmi_bridging set to single
13. ipmi_target_address - Requires: ipmi_bridging set to single
14. ipmi_transit_channel - Requires: ipmi_bridging set to dual
15. ipmi_transit_address - Requires: ipmi_bridging set to dual

testing: This setting coupled with the previously mentioned baremetal_csv_file enrolls all nodes defined in the baremetal.csv file utilizing the Ironic agent_ssh driver instead of the agent_ipmitool driver which Bifrost uses by default.  The default setting for this role is false. 

ipmi_bridging:  The setting is by default undefined, and is utilized when access to a host's IPMI interface is bridged, such as a cartridge or blade in a chassis that has a single management address.  It has two options when defined, "single" or "dual", and is utilized to execute the appropriate task in order to feed the appropriate IPMI bridging information based on the CSV file into Ironic.

ironic_url: The setting defining the URL to the Ironic API.  Presently defaulted to: "http://localhost:6385/"

Dependencies
------------

This role is presently dependent upon the ironic-install role which installs the necessary requirements.

Example Playbook
----------------

- hosts: localhost
  connection: local
  gather_facts: yes
  pre_tasks:
    - set_fact: baremetal_csv_file="/tmp/baremetal.csv"
      when: baremetal_csv_file is not defined
  roles:
    - role: ironic-enroll
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
