Getting Started
===============

Requirements:

- openstack-infra/shade library -> https://review.openstack.org/159609
- openstack-infra/os-client-config -> https://review.openstack.org/159563
- os_baremetal ansible module under development -> https://github.com/juliakreger/ansible-modules-extras/blob/features/new-openstack/cloud/os_baremetal.py
- Information defining your hardware in a CSV file.

CSV File Format
===============

The CSV file has the following columns:

1. MAC Address
2. Management username
3. Management password
4. Management Address
5. CPU Count
6. Memory size in MB
7. Disk Storage in GB
8. Flavor (Not Used)
9. Type (Not Used)
10. Host UUID
11. Host or Node name
12. Host IP Address to be set
13. ipmi_target_channel - Requires: ipmi_bridging set to single
14. ipmi_target_address - Requires: ipmi_bridging set to single
15. ipmi_transit_channel - Requires: ipmi_bridging set to dual
16. ipmi_transit_address - Requires: ipmi_bridging set to dual

Example:
00:11:22:33:44:55,root,undefined,192.168.122.1,1,8192,512,Control,VM

An example file is included called baremetal.csv.example

How this works?
===============

The enroll.yaml playbook, requires a variable be set or passed into the playbook execution of baremetal_csv_file which is the path to the CSV file to be consumed and loaded into ironic.

Example:

ansible-playbook -i ../inventory/localhost -vvvv enroll.yaml -e baremetal_csv_file=./baremetal.csv
