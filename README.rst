Repo for collaborating on a minimal ironic-based installer.

Deets on the etherpad for now:
    https://etherpad.openstack.org/p/OJYjW3fU9Q

Installation
============

The installation is split in to two parts.

The first part is a bash script which lays the basic groundwork of installing Ansible, while the second part is an Ansible playbook that installs Ironic and puts in place a basic noauth configuration.  This means that keystone is NOT required to use this deployment.

The re-execution of the playbook will cause states to be re-asserted.  If not already present, a number of software packages including MySQL and RabbitMQ will be installed on the host.  Python code will be re-installed regardless if it has changed, RabbitMQ user passwords will be reset, and services will be restarted.


Install Steps:

    1. Edit ./inventory/group_vars/all.yml to match your environment.
        - If MySQL is already installed, update mysql_password to match your local installation.
        - Change network_interface to match the interface that will need to service DHCP requests.
        - Change the ironic_db_password which is set by Ansible in MySQL and in Ironic's configuration file.
        - N.B. The testing option toggles the ironic driver.  At the time this document was written disabling testing sets the driver to iLO.
    2. cd setup
    3. bash ./env-setup.sh
    4. source /opt/stack/ansible/hacking/env-setup
    5. ansible-playbook -vvvv -i ../inventory/localhost ./install.yaml

Manual CLI Use
==============

If you wish to utilize the CLI in no-auth mode, you must set two environment variables:

    - IRONIC_URL - A URL to the Ironic API, such as http://localhost:6385/
    - OS_AUTH_TOKEN - Any value, such as an empty space, is required to cause the client library to send requests directly to the API.

For your ease of use, setup/env-vars can be sourced to allow the CLI to connect to a local Ironic installation operating in noauth mode.

Hardware Enrollment
===================
Enrollment is covered by a README.rst file located in the enroll folder.

