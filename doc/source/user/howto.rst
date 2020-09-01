======
How-To
======

Use the baremetal CLI
=====================

If you wish to utilize the baremetal CLI in no-auth mode, there are two options
for configuring the authentication parameters.

clouds.yaml
-----------

During installation, Bifrost creates a ``clouds.yaml`` file with credentials
necessary to access Ironic. A cloud called ``bifrost`` is always available. For
example::

    export OS_CLOUD=bifrost
    baremetal node list
    baremetal introspection list

.. note::
   Previously, a separate cloud ``bifrost-inspector`` was provided for
   introspection commands. It is now deprecated, the main ``bifrost`` cloud
   should always be used.

Environment variables
---------------------

The following two environment variables can be set:

- ``OS_AUTH_TYPE`` - set to ``none`` to bypass authentication.
- ``OS_ENDPOINT`` - A URL to the ironic API, such as http://localhost:6385/

For convenience, an environment file called ``openrc`` is created in the home
directory of the current user that contains default values for these variables
and can be sourced to allow the CLI to connect to a local Ironic installation.
For example::

    . ~/openrc bifrost
    baremetal node list

This should display a table of nodes, or nothing if there are no nodes
registered in Ironic.

Installing OpenStack CLI
------------------------

Starting with the Victoria release, the ``openstack`` command is only installed
when Keystone is enabled. Install the ``python-openstackclient`` Python package
to get this command.

Enroll Hardware
===============

The openstacksdk library is installed during the install process
as documented in the install documentation.

In order to enroll hardware, you will naturally need an inventory of
your hardware. When utilizing the dynamic inventory module and
accompanying roles the inventory can be supplied in one of three ways,
all of which ultimately translate to JSON data that Ansible parses.

The current method is to utilize a JSON or YAML document which the inventory
parser will convert and provide to Ansible.

In order to use, you will need to define the environment variable
``BIFROST_INVENTORY_SOURCE`` to equal a file, which then allows you to
execute Ansible utilizing the ``bifrost_inventory.py`` file as the data
source.

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
            "ipmi_address": "192.168.122.1",
            "ipmi_username": "admin",
            "ipmi_password": "pa$$w0rd"
          }
        },
        "nics": [
          {
            "mac": "52:54:00:f9:32:f6"
          }
        ],
        "driver": "ipmi",
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

.. _enroll:

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

.. _deploy:

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

  Before running the above command, ensure that the value for
  `ssh_public_key_path` in ``./playbooks/inventory/group_vars/baremetal``
  refers to a valid public key file, or set the ssh_public_key_path option
  on the ansible-playbook command line by setting the variable.
  Example: "-e ssh_public_key_path=~/.ssh/id_rsa.pub"

If the hosts need to be re-deployed, the dynamic redeploy playbook may be used::

  export BIFROST_INVENTORY_SOURCE=/tmp/baremetal.json
  ansible-playbook -vvvv -i inventory/bifrost_inventory.py redeploy-dynamic.yaml

This playbook will undeploy the hosts, followed by a deployment, allowing
a configurable timeout for the hosts to transition in each step.

Deployment and configuration of operating systems
=================================================

By default, Bifrost deploys a configuration drive which includes the user SSH
public key, hostname, and the network configuration in the form of
network_data.json that can be read/parsed by the
`glean <https://opendev.org/opendev/glean>`_ utility. This allows for
the deployment of Ubuntu, CentOS, or Fedora "tenants" on baremetal.

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
utilizing diskimage-builder and ironic-python-agent-builder. In order
to utilize this feature, the ``download_ipa`` setting must be set to ``false``
and the create_ipa_image must be set to "true".  By default, the install
playbook will build a Debian Buster based IPA image, if a pre-existing IPA
image is not present on disk. If you wish to explicitly set a specific release
to be passed to diskimage-create, then the setting ``dib_os_release`` can be
set in addition to ``dib_os_element``.

If you wish to include an extra element into the IPA disk image, such as a
custom hardware manager, you can pass the variable ``ipa_extra_dib_elements``
as a space-separated list of elements. This defaults to an empty string.

.. include:: dhcp.rst

Use Bifrost with Keystone
=========================

Content moved, see :doc:`keystone`.
