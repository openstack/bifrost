Bifrost
=======

Bifrost is a set of ansible playbooks that automates the task of deploying a
base image onto a set of known hardware using Ironic. It provides modular
utility for one-off operating system deployment with as few operational requirements
as reasonably possible.

This is split into roughly three steps:

- install:
  prepare the local environment by downloading and/or building machine images,
  and installing and configuring the necessary services.
- enroll:
  take as input a hardware inventory file and enroll the listed hardware with
  Ironic, configuring each appropriately for deployment with the
  previously-downloaded images.
- deploy:
  instruct Ironic to deploy the operating system onto each machine.


Installation
============

The installation is split in to two parts.

The first part is a bash script which lays the basic groundwork of installing
Ansible itself.

Edit ./inventory/group_vars/all.yaml to match your environment.

- If MySQL is already installed, update mysql_password to match your local installation.
- Change network_interface to match the interface that will need to service DHCP requests.
- Change the ironic_db_password which is set by Ansible in MySQL and in Ironic's configuration file.

Then run::

  cd setup
  bash ./env-setup.sh
  source /opt/stack/ansible/hacking/env-setup
  cd ..

The second part is an Ansible playbook that installs and configures Ironic
in a stand-alone fashion.

* Keystone is NOT installed, and Ironic's API is accessible without
  authentication.  It is possible to put basic password auth on Ironic's API by
  changing the nginx configuration accordingly.
* Neutron is NOT installed. Ironic performs static IP injection via
  config-drive.
* dnsmasq is configured statically and responds to all PXE boot requests by
  chain-loading to iPXE, which then fetches the ironic-python-agent ramdisk
  from Nginx.
* standard ipmitool is used.
  TODO: make optional support for other hardware drivers

The re-execution of the playbook will cause states to be re-asserted.  If not
already present, a number of software packages including MySQL and RabbitMQ
will be installed on the host.  Python code will be re-installed regardless if
it has changed, RabbitMQ user passwords will be reset, and services will be
restarted.

Run::

  ansible-playbook -vvvv -i inventory/localhost install/install.yaml


Manual CLI Use
--------------

If you wish to utilize Ironic's CLI in no-auth mode, you must set two
environment variables:

- IRONIC_URL - A URL to the Ironic API, such as http://localhost:6385/
- OS_AUTH_TOKEN - Any value, such as an empty space, is required to cause the client library to send requests directly to the API.

For your ease of use, setup/env-vars can be sourced to allow the CLI to connect
to a local Ironic installation operating in noauth mode.


Hardware Enrollment
===================

The following requirements are installed during the Install step above:

- openstack-infra/shade library -> https://review.openstack.org/159609
- openstack-infra/os-client-config -> https://review.openstack.org/159563
- os_baremetal ansible module under development -> https://github.com/juliakreger/ansible-modules-extras/blob/features/new-openstack/cloud/os_baremetal.py

You will also need a CSV file containing information about the hardware you are enrolling.

CSV File Format
---------------

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

Example definition::

  00:11:22:33:44:55,root,undefined,192.168.122.1,1,8192,512,NA,NA,aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee,hostname_100,192.168.2.100,,,,

How this works?
---------------

The enroll.yaml playbook requires a variable (baremetal_csv_file) be set or
passed into the playbook execution. This is the path to the CSV file to be
consumed and loaded into ironic.

Example::

  ansible-playbook -i inventory/localhost -vvvv enroll/enroll.yaml -e baremetal_csv_file=inventory/baremetal.csv

Note that enrollment is a one-time operation. This module *does not*
synchronize data for existing nodes.  You should use the Ironic CLI to do this
manually at the moment.

Hardware Deployment
===================

Requirements:

- The baremetal.csv file that was utilized for the enrollment process.

How this works?
---------------

The deploy.yaml playbook is intended to create configdrives for servers, and
initiate the node deployments through Ironic.  IPs are injected into the config
drive and statically assigned. 

Example::

  ansible-playbook -i inventory/localhost -vvvv deploy/deploy.yaml -e baremetal_csv_file=inventory/baremetal.csv

