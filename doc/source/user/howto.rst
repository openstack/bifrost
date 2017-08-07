======
How-To
======

Use the Ironic CLI
==================

If you wish to utilize ironic's CLI in no-auth mode, you must set two
environment variables:

- ``IRONIC_URL`` - A URL to the ironic API, such as http://localhost:6385/
- ``OS_AUTH_TOKEN`` - Any value except empty space, such as 'fake-token',
  is required to cause the client library to send requests directly to the API.

For your ease of use, ``env-vars`` can be sourced to allow the CLI to connect
to a local ironic installation operating in noauth mode. Run e.g.::

  source env-vars
  ironic node-list
  +------+------+---------------+-------------+--------------------+-------------+
  | UUID | Name | Instance UUID | Power State | Provisioning State | Maintenance |
  +------+------+---------------+-------------+--------------------+-------------+
  +------+------+---------------+-------------+--------------------+-------------+

which should print an empty table if connection to Ironic works as expected.

Enroll Hardware
===============

The following requirements are installed during the install process
as documented in the install documentation.

- openstack-infra/shade library
- openstack-infra/os-client-config

In order to enroll hardware, you will naturally need an inventory of
your hardware. When utilizing the dynamic inventory module and
accompanying roles the inventory can be supplied in one of three ways,
all of which ultimately translate to JSON data that Ansible parses.

The original method is to utilize a CSV file. This format is covered below in
the `Legacy CSV File Format`_ section. This has a number of limitations, but
does allow a user to bulk load hardware from an inventory list with minimal
data transformations.

The newer method is to utilize a JSON or YAML document which the inventory
parser will convert and provide to Ansible.

In order to use, you will need to define the environment variable
``BIFROST_INVENTORY_SOURCE`` to equal a file, which then allows you to
execute Ansible utilizing the ``bifrost_inventory.py`` file as the data
source.

Conversion from CSV to JSON formats
-----------------------------------

The ``inventory/bifrost_inventory.py`` program additionally features a
mode that allows a user to convert a CSV file to the JSON data format
utilizing a ``--convertcsv`` command line setting when directly invoked.

Example::

  export BIFROST_INVENTORY_SOURCE=/tmp/baremetal.csv
  inventory/bifrost_inventory.py --convertcsv >/tmp/baremetal.json

JSON file format
----------------

The JSON format closely resembles the data structure that ironic
utilizes internally.  The ``name``, ``driver_info``, ``nics``,
``driver``, and ``properties`` fields are directly mapped through to
ironic.  This means that the data contained within can vary from host
to host, such as drivers and their parameters thus allowing a mixed
hardware environment to be defined in a single file.

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
        "provisioning_ipv4_address": "10.0.0.9",
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
in an ``instance_info`` variable.

Examples utilizing JSON and YAML formatting, along host specific variable
injection can be found in the ``playbooks/inventory/`` folder.

Legacy CSV file format
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
12. ``ipmi_target_channel`` - Requires: ``ipmi_bridging`` set to single
13. ``ipmi_target_address`` - Requires: ``ipmi_bridging`` set to single
14. ``ipmi_transit_channel`` - Requires: ``ipmi_bridging`` set to dual
15. ``ipmi_transit_address`` - Requires: ``ipmi_bridging`` set to dual
16. ironic driver
17. Host provisioning IP Address

Example definition::

  00:11:22:33:44:55,root,undefined,192.168.122.1,1,8192,512,NA,NA,aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee,hostname_100,192.168.2.100,,,,agent_ipmitool,10.0.0.9

This file format is fairly flexible and can be easily modified
although the enrollment and deployment playbooks utilize the model
of a host per line model in order to process through the entire
list, as well as reference the specific field items.

An example file can be found at: ``playbooks/inventory/baremetal.csv.example``

How this works?
---------------

Utilizing the dynamic inventory module, enrollment is as simple as setting
the ``BIFROST_INVENTORY_SOURCE`` environment variable to your inventory data
source, and then executing the enrollment playbook.::

  export BIFROST_INVENTORY_SOURCE=/tmp/baremetal.json
  ansible-playbook -vvvv -i inventory/bifrost_inventory.py enroll-dynamic.yaml

When ironic is installed on remote server, a regular ansible inventory
with a target server should be added to ansible. This can be achieved by
specifying a directory with files, each file in that directory will be part of
the ansible inventory. Refer to ansible documentation
http://docs.ansible.com/ansible/intro_dynamic_inventory.html#using-inventory-directories-and-multiple-inventory-sources

::

  export BIFROST_INVENTORY_SOURCE=/tmp/baremetal.json
  rm inventory/*.example
  ansible-playbook -vvvv -i inventory/ enroll-dynamic.yaml

Note that enrollment is a one-time operation. The Ansible module *does not*
synchronize data for existing nodes.  You should use the ironic CLI to do this
manually at the moment.

Additionally, it is important to note that the playbooks for enrollment are
split into three separate playbooks based on the ``ipmi_bridging`` setting.

Deploy Hardware
===============

How this works?
---------------

After the nodes are enrolled, they can be deployed upon.  Bifrost is geared to
utilize configuration drives to convey basic configuration information to the
each host. This configuration information includes an SSH key to allow a user
to login to the system.

To utilize the newer dynamic inventory based deployment::

  export BIFROST_INVENTORY_SOURCE=/tmp/baremetal.json
  ansible-playbook -vvvv -i inventory/bifrost_inventory.py deploy-dynamic.yaml

When ironic is installed on remote server, a regular ansible inventory
with a target server should be added to ansible. This can be achieved by
specifying a directory with files, each file in that directory will be part of
the ansible inventory. Refer to ansible documentation
http://docs.ansible.com/ansible/intro_dynamic_inventory.html#using-inventory-directories-and-multiple-inventory-sources

::

  export BIFROST_INVENTORY_SOURCE=/tmp/baremetal.json
  rm inventory/*.example
  ansible-playbook -vvvv -i inventory/ deploy-dynamic.yaml

Note::

  Before running the above command, ensure that the value for `ssh_public_key_path` in
  ``./playbooks/inventory/group_vars/baremetal`` refers to a valid public key file,
  or set the ssh_public_key_path option on the ansible-playbook command line by
  setting the variable. Example: "-e ssh_public_key_path=~/.ssh/id_rsa.pub"

If the hosts need to be re-deployed, the dynamic redeploy playbook may be used::

  export BIFROST_INVENTORY_SOURCE=/tmp/baremetal.json
  ansible-playbook -vvvv -i inventory/bifrost_inventory.py redeploy-dynamic.yaml

This playbook will undeploy the hosts, followed by a deployment, allowing
a configurable timeout for the hosts to transition in each step.

Execute local testing
=====================

A simple ``scripts/test-bifrost.sh`` script can be utilized to install
pre-requisite software packages, Ansible, and then execute the
``test-bifrost-create-vm.yaml`` and ``test-bifrost.yaml`` playbooks in order
to provide a single step testing mechanism.

``playbooks/test-bifrost-create-vm.yaml`` creates one or more VMs for
testing and saves out a baremetal.json file which is used by
``playbooks/test-bifrost.yaml`` to execute the remaining roles.  Two
additional roles are invoked by this playbook which enables Ansible to
connect to the new nodes by adding them to the inventory, and then
logging into the remote machine via the user's ssh host key.  Once
that has successfully occurred, additional roles will unprovision the
host(s) and delete them from ironic.

Command::

  scripts/test-bifrost.sh

Note:

- Cleaning mode is explicitly disabled in the ``test-bifrost.yaml``
  playbook due to the fact that is an IO-intensive operation that can
  take a great deal of time.

- In order to cap requirements for installation, an ``upper_constraints_file``
  setting is defined. This is consuming the ``UPPER_CONSTRAINTS_FILE`` env
  var by default, to properly integrate with CI systems, and will default
  to ``/opt/stack/requirements/upper-constraints.txt`` file if not present.

Manually test with Virtual Machines
===================================

Bifrost supports using virtual machines to emulate the hardware.

It is assumed you have an SSH server running on the host machine. The
``agent_ssh`` driver, used by ironic with VM testing, will need to use
SSH to control the virtual machines.

An SSH key is generated for the ``ironic`` user when testing. The
ironic conductor will use this key to connect to the host machine and
run virsh commands.

#. Set ``testing`` to *true* in the
   ``playbooks/inventory/group_vars/target`` file.
#. You may need to adjust the value for ``ssh_public_key_path``.
#. Run the install step, as documented above, however adding ``-e
   testing=true`` to the Ansible command line.
#. Execute the ``ansible-playbook -vvvv -i inventory/target
   test-bifrost-create-vm.yaml`` command to create a test virtual
   machine.
#. Set the environment variable of ``BIFROST_INVENTORY_SOURCE`` to the
   path to the JSON file, which by default has been written to
   /tmp/baremetal.json.
#. Run the enrollment step, as documented above, using the CSV file
   you created in the previous step.
#. Run the deployment step, as documented above.

Deployment and configuration of operating systems
=================================================

By default, Bifrost deploys a configuration drive which includes the user SSH
public key, hostname, and the network configuration in the form of
network_data.json that can be read/parsed by the
`glean <https://github.com/openstack-infra/glean>`_ utility. This allows for
the deployment of Ubuntu, CentOS, or Fedora "tenants" on baremetal.  This file
format is not yet supported by Cloud-Init, however it is on track for
inclusion in cloud-init 2.0.

By default, Bifrost utilizes a utility called simple-init which leverages
the previously noted glean utility to apply network configuration.  This
means that by default, root file systems may not be automatically expanded
to consume the entire disk, which may, or may not be desirable depending
upon operational needs. This is dependent upon what base OS image you
utilize, and if the support is included in that image or not.  At present,
the standard Ubuntu cloud image includes cloud-init which will grow the
root partition, however the ubuntu-minimal image does not include cloud-init
and thus will not automatically grow the root partition.

Due to the nature of the design, it would be relatively easy for a user to
import automatic growth or reconfiguration steps either in the image to be
deployed, or in post-deployment steps via custom Ansible playbooks.

Build Custom Ironic Python Agent (IPA) images
=============================================

Bifrost supports the ability for a user to build a custom IPA ramdisk
utilizing the diskimage-builder element "ironic-agent".  In order to utilize
this feature, the ``download_ipa`` setting must be set to ``false`` and the
create_ipa_image must be set to "true".  By default, the install playbook will
build a Debian jessie based IPA image, if a pre-existing IPA image is not
present on disk.  If you wish to explicitly set a specific release to be
passed to diskimage-create, then the setting ``dib_os_release`` can be set in
addition to ``dib_os_element``.

If you wish to include an extra element into the IPA disk image, such as a
custom hardware manager, you can pass the variable ``ipa_extra_dib_elements``
as a space-separated list of elements. This defaults to an empty string.

.. include:: dhcp.rst

Use Bifrost with Keystone
=========================
.. include:: keystone.rst


