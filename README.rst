Bifrost
=======

Bifrost is a set of Ansible playbooks that automates the task of deploying a
base image onto a set of known hardware using Ironic. It provides modular
utility for one-off operating system deployment with as few operational requirements
as reasonably possible.

This is split into roughly three steps:

- install:
  prepare the local environment by downloading and/or building machine images,
  and installing and configuring the necessary services.
- enroll:
  take as input a customizable hardware inventory file and enroll the
  listed hardware with Ironic, configuring each appropriately for deployment
  with the previously-downloaded images.
- deploy:
  instruct Ironic to deploy the operating system onto each machine.

Supported Operating Systems:

* Ubuntu
* Red Hat Enterprise Linux (RHEL) 7
* CentOS 7

Pre-install steps
=================

Installing bifrost on RHEL or CentOS requires a few extra pre-install steps.

------------------------------------------
Enable additional repositories (RHEL only)
------------------------------------------

The extras and optional yum repositories must be enabled to satisfy bifrost's dependencies. To check::

   sudo yum repolist | grep 'optional\|extras'

To add the repositories::

   sudo yum repolist all | grep 'optional\|extras'

The output will look like this::

  !rhui-REGION-rhel-server-debug-extras/7Server/x86_64        Red H disabled
  rhui-REGION-rhel-server-debug-optional/7Server/x86_64       Red H disabled
  rhui-REGION-rhel-server-extras/7Server/x86_64               Red H disabled
  rhui-REGION-rhel-server-optional/7Server/x86_64             Red H disabled
  rhui-REGION-rhel-server-source-extras/7Server/x86_64        Red H disabled
  rhui-REGION-rhel-server-source-optional/7Server/x86_64      Red H disabled

Use the names of the repositories (minus the version and architecture) to enable them::

  sudo yum-config-manager --enable rhui-REGION-rhel-server-optional
  sudo yum-config-manager --enable rhui-REGION-rhel-server-extras

---------------------------------
Enable the EPEL repository (RHEL)
---------------------------------

The Extra Packages for Enterprise Linux (EPEL) repository contains some of bifrost's dependencies. To enable it, install the `epel-release` package as follows::

  sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

-----------------------------------
Enable the EPEL repository (CentOS)
-----------------------------------

To enable EPEL on CentOS, run::

  sudo yum install epel-release

Installation
============

The installation is split in to two parts.

The first part is a bash script which lays the basic groundwork of installing
Ansible itself.

Edit ``./playbooks/inventory/group_vars/all`` to match your environment.

- If MySQL is already installed, update mysql_password to match your local installation.
- Change network_interface to match the interface that will need to service DHCP requests.
- Change the ironic_db_password which is set by Ansible in MySQL and in Ironic's configuration file.

Then run::

  bash ./scripts/env-setup.sh
  source /opt/stack/ansible/hacking/env-setup
  cd playbooks

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

  If you have password-less sudo enabled, run:
	 ansible-playbook -vvvv -i inventory/localhost install.yaml
  Otherwise, add -K option to let Ansible prompting for the sudo  password:
	 ansible-playbook -K -vvvv -i inventory/localhost install.yaml

With regards to testing, you may wish to set your installation such
that ironic node cleaning is disabled.  You can achieve this by passing
the option "-e cleaning=false" to the command line or executing the
command below.  This is because cleaning can take a substantial amount
of time while disks are being wiped.::

  ansible-playbook -K -vvvv -i inventory/localhost install.yaml -e cleaning=false

After you have performed an installation, you can edit /etc/ironic/ironic.conf
to enable or disable cleaning as desired.

Manual CLI Use
--------------

If you wish to utilize Ironic's CLI in no-auth mode, you must set two
environment variables:

- IRONIC_URL - A URL to the Ironic API, such as http://localhost:6385/
- OS_AUTH_TOKEN - Any value, such as an empty space, is required to cause the client library to send requests directly to the API.

For your ease of use, `env-vars` can be sourced to allow the CLI to connect
to a local Ironic installation operating in noauth mode.


Hardware Enrollment
===================

The following requirements are installed during the Install step above:

- openstack-infra/shade library
- openstack-infra/os-client-config

In order to enroll hardware, you will naturally need an inventory of your
hardware. When utilizing the dynamic inventory module and accompanying roles
this can be supplied in one of three ways, all of which ultimately translate
to JSON data that Ansible parses.

The original method is to utilize a CSV file.  Its format is below covered in
the `Legacy CSV File Format` section. This has a number of limitations, but
does allow a user to bulk load hardware from an inventory list with minimal
data transformations.

The newer method is to utilize a JSON or YAML document which the inventory
parser will convert and provide to Ansible.

In order to use, you will need to define the environment variable
`BIFROST_INVENTORY_SOURCE` to equal a file, which then allows you to
execute Ansible utilizing the bifrost_inventory.py file as the data source.

Conversion from CSV to JSON formats
-----------------------------------

The inventory/bifrost_inventory.py program additionally features a mode that
allows a user to convert a CSV file to the JSON data format utilizing a
`--convertcsv` command line setting when directly invoked.

Example::

  export BIFROST_INVENTORY_SOURCE=/tmp/baremetal.csv
  inventory/bifrost_inventory.py --convertcsv >/tmp/baremetal.json

JSON file format
----------------

The JSON format closely resembles the data structure that Ironic utilizes
internally.  The name, driver_info, nics, driver, and properties fields are
directly mapped through to Ironic.  This means that the data contained within
can vary from host to host, such as drivers and their parameters thus allowing
a mixed hardware environment to be defined in a single file.

Example::

  {
      "testvm1": {
        "uuid": "00000000-0000-0000-0000-000000000001",
        "driver_info": {
          "power": {
            "ssh_port": 22,
            "ssh_username": "ironic",
            "ssh_virt_type": "virsh",
            "ssh_address": "192.168.122.1",
            "ssh_key_filename": "/home/ironic/.ssh/id_rsa"
          }
        },
        "nics": [
          {
            "mac": "52:54:00:f9:32:f6"
          }
        ],
        "driver": "agent_ssh",
        "ansible_ssh_host": "192.168.122.2",
        "ipv4_address": "192.168.122.2",
        "properties": {
          "cpu_arch": "x86_64",
          "ram": "3072",
          "disk_size": "10",
          "cpus": "1"
        },
        "name": "testvm1"
      }
  }

The additional power of this format is easy configuration parameter injection,
which could potentially allow a user to provision different operating system
images onto different hardware chassis by defining the appropriate settings
in an "instance_info" variable.

Legacy CSV File Format
----------------------

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
16. ironic driver

Example definition::


  00:11:22:33:44:55,root,undefined,192.168.122.1,1,8192,512,NA,NA,aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee,hostname_100,192.168.2.100,,,,

This file format is fairly flexible and can be easily modified
although the enrollment and deployment playbooks utilize the model
of a host per line model in order to process through the entire
list, as well as reference the specific field items.

An example file can be found at inventory/baremetal.csv.example.

How this works?
---------------

The enroll.yaml playbook requires a variable (baremetal_csv_file) be set or
passed into the playbook execution. NOTE: This MUST be the full path to the
CSV file to be consumed by the Ansible playbooks and loaded into ironic.

Example::

  ansible-playbook -i inventory/localhost -vvvv enroll.yaml -e baremetal_csv_file=inventory/baremetal.csv

Note that enrollment is a one-time operation. The Ansible module *does not*
synchronize data for existing nodes.  You should use the Ironic CLI to do this
manually at the moment.

Additionally, it is important to note that the playbooks for enrollment are
split into three separate playbooks based up the setting of ipmi_bridging.

Hardware Deployment
===================

Requirements:

- The baremetal.csv file that was utilized for the enrollment process.

How this works?
---------------

The deploy.yaml playbook is intended to create configdrives for servers, and
initiate the node deployments through Ironic.  IPs are injected into the config
drive and are statically assigned.

Example::

  ansible-playbook -i inventory/localhost -vvvv deploy.yaml -e baremetal_csv_file=inventory/baremetal.csv

Testing with a single command
=============================

A simple ``scripts/test-bifrost.sh`` script can be utilized to install pre-requisite software packages, Ansible, and then execute the test-bifrost.yaml playbook in order to provide a single step testing mechanism.

The playbook utilized by the script, ``playbooks/test-bifrost.yaml``, is a single playbook that will create a local virtual machine, save a baremetal.csv file out, and then utilize it to execute the remaining roles.  Two additional roles are invoked by this playbook which enables Ansible to connect to the new nodes by adding them to the inventory, and then logging into the remote machine via the user's ssh host key.  Once that has successfully occurred, additional roles will unprovision the host(s) and delete them from Ironic.

Command::

  scripts/test-bifrost.sh

Note:

- Cleaning mode is explicitly disabled in the test-bifrost.yaml playbook due to the fact that is an IO intensive operation that can take a great deal of time.

Testing with Virtual Machines
=============================

Bifrost supports using virtual machines to emulate the hardware. All of the
steps mentioned above are mostly the same.

It is assumed you have an SSH server running on the host machine. The ``agent_ssh``
driver, used by Ironic with VM testing, will need to use SSH to control the
virtual machines.

An SSH key is generated for the ``ironic`` user when testing. The ironic conductor
will use this key to connect to the host machine and run virsh commands.

#. Set ``testing`` to *true* in the ``playbooks/inventory/group_vars/all`` file.
#. You may need to adjust the value for ``ssh_public_key_path``.
#. Run the install step, as documented above.
#. Run the ``tools/create_vm_nodes.sh`` script. By default, it will create a single VM node. Read the documentation within the script to see how to create more than one.
#. The ``tools/create_vm_nodes.sh`` script will output CSV entries that can be used for the enrollment step. You will need to create a CSV file with this output.
#. Run the enrollment step, as documented above, using the CSV file you created in the previous step.
#. Run the deployment step, as documented above.

Future Support
==============

* Config drive network_info.json - Bifrost will automatically place a json structured file which is intended to replace the direct placement of a ``/etc/network/interfaces`` file.  This will ultimately allow for more complex user defined networking as well as greater compatibility with other Linux distributions.  At present, the diskimage-builder element ``simple-init`` can be used to facilitate this.
