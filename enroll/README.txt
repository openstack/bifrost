Getting Started
===============

Requirements:

- openstack-infra/shade library -> https://review.openstack.org/159609
- openstack-infra/os-client-config ->  https://review.openstack.org/159563
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

Example:
00:11:22:33:44:55,root,undefined,192.168.122.1,1,8192,512,Control,VM

An example file is included called baremetal.csv.example

How this works?
===============

The enroll.yaml playbook, requires a variable be set or passed into the playbook execution of baremetal_csv_file which is the path to the CSV file to be consumed and loaded into ironic.

Example:

ansible-playbook -i localhost -vvvv enroll.yaml -e baremetal_csv_file=./baremetal.csv
