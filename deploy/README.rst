Getting Started
===============

Requirements:

- The baremetal.csv file that was utilized for the enrollment process.

How this works?
===============

The deploy.yaml playbook is intended to create configdrives for servers, and initiate the node deployments through ironic.

Example:

ansible-playbook -i ../inventory/localhost -vvvv deploy.yaml -e baremetal_csv_file=../enroll/baremetal.csv
