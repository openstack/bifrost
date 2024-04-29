======
How-To
======

.. _baremetal-cli:

Use the baremetal CLI
=====================

If you wish to utilize the baremetal CLI in no-auth mode, there are two options
for configuring the authentication parameters.

clouds.yaml
-----------

During installation, Bifrost creates a ``clouds.yaml`` file with credentials
necessary to access Ironic. A cloud called ``bifrost`` is always available. For
example:

.. code-block:: bash

    export OS_CLOUD=bifrost
    baremetal node list
    baremetal introspection list

.. note::
   Previously, a separate cloud ``bifrost-inspector`` was provided for
   introspection commands. It is now deprecated, the main ``bifrost`` cloud
   should always be used.

Environment variables
---------------------

For convenience, an environment file called ``openrc`` is created in the home
directory of the current user that contains default values for these variables
and can be sourced to allow the CLI to connect to a local Ironic installation.
For example:

.. code-block:: bash

    . ~/openrc bifrost
    baremetal node list

This should display a table of nodes, or nothing if there are no nodes
registered in Ironic.

Installing OpenStack CLI
------------------------

Starting with the Victoria release, the ``openstack`` command is only installed
when Keystone is enabled. Install the ``python-openstackclient`` Python package
to get this command.

Inventory file format
=====================

In order to enroll hardware, you will naturally need an inventory of
your hardware. When utilizing the dynamic inventory module and
accompanying roles the inventory can be supplied in one of three ways,
all of which ultimately translate to JSON data that Ansible parses.

The current method is to utilize a JSON or YAML document which the inventory
parser will convert and provide to Ansible.

The JSON format resembles the data structure that ironic utilizes internally.

* The ``name``, ``uuid``, ``driver``, and ``properties`` fields are directly
  mapped through to ironic. Only the ``driver`` is required.

  .. note::
     Most properties are automatically populated during inspection, if it is
     enabled. However, it is recommended to set the `root device
     <https://docs.openstack.org/ironic/latest/install/advanced.html#specifying-the-disk-for-deployment-root-device-hints>`_
     for nodes with multiple disks.

* The ``driver_info`` field format matches one of the OpenStack Ansible
  collection and for legacy reasons can use nested structures ``power``,
  ``deploy``, ``management`` and ``console``.

  .. note::
     With newer versions of the collection you should just put all fields under
     ``driver_info`` directly).

* The ``nics`` field is a list of ports to create. The required field is
  ``mac`` - MAC address of the port.

Example:

.. code-block:: json

  {
      "testvm1": {
        "name": "testvm1",
        "driver": "ipmi",
        "driver_info": {
          "ipmi_address": "192.168.122.1",
          "ipmi_username": "admin",
          "ipmi_password": "pa$$w0rd"
        },
        "nics": [
          {
            "mac": "52:54:00:f9:32:f6"
          }
        ],
        "properties": {
          "cpu_arch": "x86_64",
          "root_device": {"wwn": "0x4000cca77fc4dba1"}
        }
      }
  }

Overriding instance information
-------------------------------

The additional power of this format is easy configuration parameter injection,
which could potentially allow a user to provision different operating system
images onto different hardware chassis by defining the appropriate settings
in an ``instance_info`` variable, for example:

.. code-block:: json

  {
      "testvm1": {
        "uuid": "00000000-0000-0000-0000-000000000001",
        "name": "testvm1",
        "driver": "redfish",
        "driver_info": {
          "redfish_address": "https://bmc.myhost.com",
          "redfish_system_id": "/redfish/v1/Systems/11",
          "redfish_username": "admin",
          "redfish_password": "pa$$w0rd",
        },
        "nics": [
          {
            "mac": "52:54:00:f9:32:f6"
          }
        ],
        "properties": {
          "cpu_arch": "x86_64",
          "root_device": {"wwn": "0x4000cca77fc4dba1"}
        },
        "instance_info": {
          "image_source": "http://image.server/image.qcow2",
          "image_checksum": "<md5/sha256/sha512 checksum>",
          "configdrive": {
            "meta_data": {
              "public_keys": {"0": "ssh-rsa ..."},
              "hostname": "vm1.example.com"
            }
          }
        }
      }
  }

The ``instance_info`` format is documented in the `Ironic deploy guide
<https://docs.openstack.org/ironic/latest/user/deploy.html#populating-instance-information>`_.
The ability to populate ``configdrive`` this way is a Bifrost-specific feature,
but the ``configdrive`` itself follows the Ironic format.

Examples utilizing JSON and YAML formatting, along host specific variable
injection can be found in the ``playbooks/inventory/`` folder.

Static network configuration
----------------------------

When building a configdrive, Bifrost can embed static networking configuration
in it. This configuration will be applied by the first-boot service, such
as cloud-init_ or glean_. The following fields can be set:

``ipv4_address``
    The IPv4 address of the node. If missing, the configuration is not
    provided in the configdrive.

    When ``ipv4_address`` is set, it's also used as the default for
    ``ansible_ssh_host``. Because of this, you can run SSH commands against
    deployed hosts, as long as you use the Bifrost's inventory plugin.

    This parameter can also used for :doc:`DHCP configuration <dhcp>`.
``ipv4_subnet_mask``
    The subnet mask of the IP address. Defaults to `255.255.255.0`.
``ipv4_interface_mac``
    MAC address of the interface to configure. If missing, the MAC address of
    the first NIC defined in the inventory is used.
``ipv4_gateway``
    IPv4 address of the default router. A default value is only provided
    for testing case.
``ipv4_nameserver``
    The server to use for name resolution (a string or a list).
``network_mtu``
    MTU to use for the link.

For example:

.. code-block:: json

  {
      "testvm1": {
        "name": "testvm1",
        "driver": "redfish",
        "driver_info": {
          "redfish_address": "https://bmc.myhost.com",
          "redfish_system_id": "/redfish/v1/Systems/11",
          "redfish_username": "admin",
          "redfish_password": "pa$$w0rd",
        },
        "ipv4_address": "192.168.122.42",
        "ipv4_subnet_mask": "255.255.255.0",
        "ipv4_gateway": "192.168.122.1",
        "ipv4_nameserver": "8.8.8.8",
        "nics": [
          {
            "mac": "52:54:00:f9:32:f6"
          }
        ],
        "properties": {
          "cpu_arch": "x86_64",
          "root_device": {"wwn": "0x4000cca77fc4dba1"}
        }
      }
  }

.. warning::
   Static network configuration only works this way if you let Bifrost generate
   the configdrive.

.. _enroll:

Enroll Hardware
===============

Starting with the Wallaby cycle, you can use ``bifrost-cli`` for enrolling:

.. code-block:: bash

    ./bifrost-cli enroll /tmp/baremetal.json

Note that enrollment is a one-time operation. The Ansible module *does not*
synchronize data for existing nodes.  You should use the ironic CLI to do this
manually at the moment.

Additionally, it is important to note that the playbooks for enrollment are
split into three separate playbooks based on the ``ipmi_bridging`` setting.

.. _deploy:

Deploy Hardware
===============

After the nodes are enrolled, they can be deployed upon.  Bifrost is geared to
utilize configuration drives to convey basic configuration information to the
each host. This configuration information includes an SSH key to allow a user
to login to the system.

Starting with the Yoga cycle, you can use ``bifrost-cli`` for deploying. If
you used ``bifrost-cli`` for installation, you should pass its environment
variables, as well as the inventory file (see `Inventory file format`_):

.. code-block:: bash

    ./bifrost-cli deploy /tmp/baremetal.json \
        -e @baremetal-install-env.json

.. note::
   By default, the playbook will return once the deploy has started. Pass
   the ``--wait`` flag to wait for completion.

The inventory file may override some deploy settings, such as images or even
the complete ``instance_info``, per node.  If you omit it, all nodes from
Ironic will be deployed using the Bifrost defaults:

.. code-block:: bash

    ./bifrost-cli deploy -e @baremetal-install-env.json

Command line parameters
-----------------------

By default the playbooks use the image, downloaded or built during
installation. You can also use a custom image:

.. code-block:: bash

    ./bifrost-cli deploy -e @baremetal-install-env.json \
        --image http://example.com/images/my-image.qcow2 \
        --image-checksum 91ebfb80743bb98c59f787c9dc1f3cef \

.. note::
   Please see the `OpenStack Image Guide
   <https://docs.openstack.org/image-guide/obtain-images.html>`_ for options
   and locations for obtaining guest images.

You can also provide a custom configdrive URL (or its content) instead of
the one Bifrost builds for you:

.. code-block:: bash

    ./bifrost-cli deploy -e @baremetal-install-env.json \
        --config-drive '{"meta_data": {"public_keys": {"0": "'"$(cat ~/.ssh/id_rsa.pub)"'"}}}' \

File images do not require a checksum:

.. code-block:: bash

    ./bifrost-cli deploy -e @baremetal-install-env.json \
        --image file:///var/lib/ironic/custom-image.qcow2

.. note:: Files must be readable by Ironic. Your home directory is often not.

Partition images can de deployed by specifying an image type:

.. code-block:: bash

    ./bifrost-cli deploy -e @baremetal-install-env.json \
        --image http://example.com/images/my-image.qcow2 \
        --image-checksum 91ebfb80743bb98c59f787c9dc1f3cef \
        --partition

.. note::
   The default root partition size is 10 GiB. Set the ``deploy_root_gb``
   parameter to override or use a first-boot service such as cloud-init to
   grow the root partition automatically.

Redeploy Hardware
=================

If the hosts need to be re-deployed, the dynamic redeploy playbook may be used:

.. code-block:: bash

  export BIFROST_INVENTORY_SOURCE=/tmp/baremetal.json
  cd playbooks
  ansible-playbook -vvvv -i inventory/bifrost_inventory.py redeploy-dynamic.yaml

This playbook will undeploy the hosts, followed by a deployment, allowing
a configurable timeout for the hosts to transition in each step.

Use playbooks instead of bifrost-cli
====================================

Using playbooks directly allows you full control over what is executed by
Bifrost, with what variables and using what inventory.

Utilizing the dynamic inventory module, enrollment is as simple as setting
the ``BIFROST_INVENTORY_SOURCE`` environment variable to your inventory data
source, and then executing the enrollment playbook:

.. code-block:: bash

  export BIFROST_INVENTORY_SOURCE=/tmp/baremetal.json
  cd playbooks
  ansible-playbook -vvvv -i inventory/bifrost_inventory.py enroll-dynamic.yaml

To utilize the dynamic inventory based deployment:

.. code-block:: bash

  export BIFROST_INVENTORY_SOURCE=/tmp/baremetal.json
  cd playbooks
  ansible-playbook -vvvv -i inventory/bifrost_inventory.py deploy-dynamic.yaml

If you used ``bifrost-cli`` for installation, you should pass its environment
variables:

.. code-block:: bash

  export BIFROST_INVENTORY_SOURCE=/tmp/baremetal.json
  cd playbooks
  ansible-playbook -vvvv \
    -i inventory/bifrost_inventory.py \
    -e @../baremetal-install-env.json \
    deploy-dynamic.yaml

Deployment and configuration of operating systems
=================================================

By default, Bifrost deploys a configuration drive which includes the user SSH
public key, hostname, and the network configuration in the form of
network_data.json that can be read/parsed by
`glean <https://opendev.org/opendev/glean>`_ or `cloud-init
<https://cloudinit.readthedocs.io/en/latest/>`_. This allows for
the deployment of Ubuntu, CentOS, or Fedora "tenants" on baremetal.

By default, Bifrost utilizes a utility called *simple-init* which leverages
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

To be able to access nodes via SSH, ensure that the value for
`ssh_public_key_path` in ``./playbooks/inventory/group_vars/baremetal``
refers to a valid public key file, or set the ``ssh_public_key_path`` variable
on the command line, e.g. ``-e ssh_public_key_path=~/.ssh/id_rsa.pub``.

Advanced topics
===============

Using a remote ironic
---------------------

When ironic is installed on remote server, a regular ansible inventory
with a target server should be added to ansible. This can be achieved by
specifying a directory with files, each file in that directory will be part of
the ansible inventory. Refer to ansible documentation
http://docs.ansible.com/ansible/intro_dynamic_inventory.html#using-inventory-directories-and-multiple-inventory-sources.
Example:

.. code-block:: bash

  export BIFROST_INVENTORY_SOURCE=/tmp/baremetal.json
  cd playbooks
  rm inventory/*.example
  ansible-playbook -vvvv -i inventory/ enroll-dynamic.yaml

Build Custom Ironic Python Agent (IPA) images
---------------------------------------------

Content moved, see :ref:`custom-ipa-images`.

Configuring the integrated DHCP server
--------------------------------------

Content moved, see :doc:`dhcp`.

Use Bifrost with Keystone
-------------------------

Content moved, see :doc:`keystone`.
