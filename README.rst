Bifrost
=======

Bifrost is a set of Ansible playbooks that automates the task of
deploying a base image onto a set of known hardware using ironic. It
provides modular utility for one-off operating system deployment with
as few operational requirements as reasonably possible.

Use Cases
=========

* Installation of ironic in standalone/noauth mode without other OpenStack
  components.
* Deployment of an operating system to a known pool of hardware as
  a batch operation.
* Testing and development of ironic in a standalone use case.

Use
===

This is split into roughly three steps:

- **install**:
  prepare the local environment by downloading and/or building machine images,
  and installing and configuring the necessary services.
- **enroll-dynamic**:
  take as input a customizable hardware inventory file and enroll the
  listed hardware with ironic, configuring each appropriately for deployment
  with the previously-downloaded images.
- **deploy-dynamic**:
  instruct ironic to deploy the operating system onto each machine.

Supported operating systems:

* Ubuntu 14.04, 14.10, 15.04
* Red Hat Enterprise Linux (RHEL) 7
* CentOS 7
* Fedora 22

Pre-install steps
=================

Installing bifrost on RHEL or CentOS requires a few extra pre-install steps.

Enable additional repositories (RHEL only)
------------------------------------------

The extras and optional yum repositories must be enabled to satisfy
bifrost's dependencies. To check::

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

Enable the EPEL repository (RHEL)
---------------------------------

The Extra Packages for Enterprise Linux (EPEL) repository contains
some of bifrost's dependencies. To enable it, install the
``epel-release`` package as follows::

  sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

Enable the EPEL repository (CentOS)
-----------------------------------

To enable EPEL on CentOS, run::

  sudo yum install epel-release

Installation
============

The installation is split into two parts.

The first part is a bash script which lays the basic groundwork of installing
Ansible itself.

Bifrost source code should be pulled directly from git first::

  git clone https://git.openstack.org/openstack/bifrost.git
  cd bifrost

Edit ``./playbooks/inventory/group_vars/*`` to match your environment. The
localhost file is intended for steps executed upon the localhost, such as
installation, or image generation.  The baremetal file is geared for steps
performed on baremetal nodes, such as enrollment, deployment, or any other
custom playbooks that a user may bolt on to this toolkit.

- If MySQL is already installed, update ``mysql_password`` to match
  your local installation.
- Change ``network_interface`` to match the interface that will need
  to service DHCP requests.
- Change the ``ironic_db_password`` which is set by Ansible in MySQL
  and in ironic's configuration file.

The install process builds or modifies a disk image to deploy. The
following two settings (which are mutually exclusive) allow you to
choose if a partition image is used or an image is created with
diskimage-builder::

  create_image_via_dib: true
  transform_boot_image: false

If you are running the installation behind a proxy, export the
environment variables ``http_proxy`` and ``https_proxy`` so that
Ansible will use these proxy settings.

The below script ``env-setup.sh`` will install ansible and all of bifrost's
dependencies. You can configure the ansible installation location by setting
``ANSIBLE_INSTALL_ROOT`` environment variable. The default value will be
``/opt/stack``.

Note:

  Only ansible installation location will be moved as part of the
  environment variable.  The other components will continue to be cloned under
  ``/opt/stack``

Then run::

  bash ./scripts/env-setup.sh
  source ${ANSIBLE_INSTALL_ROOT}/ansible/hacking/env-setup
  cd playbooks

The second part is an Ansible playbook that installs and configures ironic
in a stand-alone fashion.

* Keystone is NOT installed, and ironic's API is accessible without
  authentication.  It is possible to put basic password auth on ironic's API by
  changing the nginx configuration accordingly.
* Neutron is NOT installed. Ironic performs static IP injection via
  config-drive.
* dnsmasq is configured statically and responds to all PXE boot requests by
  chain-loading to iPXE, which then fetches the ironic-python-agent ramdisk
  from Nginx.
* Deployments are performed by the Ironic Python Agent, which as configured
  supports IPMI, iLO, and UCS drivers.  AMT driver support is also enabled,
  however it should only be used for testing as due to a known bug which
  can be read about at https://bugs.launchpad.net/ironic/+bug/1454492.
* By default, installation will build an Ubuntu-based image for deployment
  to nodes.  This image can be easily customized if so desired.

The re-execution of the playbook will cause states to be re-asserted.  If not
already present, a number of software packages including MySQL and RabbitMQ
will be installed on the host.  Python code will be reinstalled regardless if
it has changed, RabbitMQ user passwords will be reset, and services will be
restarted.

Run::

  If you have passwordless sudo enabled, run:
     ansible-playbook -vvvv -i inventory/localhost install.yaml
  Otherwise, add -K option to let Ansible prompting for the sudo  password:
     ansible-playbook -K -vvvv -i inventory/localhost install.yaml

With regard to testing, ironic's node cleaning capability is disabled by
default as it can be an unexpected surprise for a new user that their test
node is unusable for however long it takes for the disks to be wiped.

If you wish to enable cleaning, you can achieve this by passing the option
``-e cleaning=true`` to the command line or executing the command below::

  ansible-playbook -K -vvvv -i inventory/localhost install.yaml -e cleaning=true

After you have performed an installation, you can edit /etc/ironic/ironic.conf
to enable or disable cleaning as desired, however it is highly encouraged to
utilize cleaning in any production environment.

Manual CLI use
--------------

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

Hardware enrollment
===================

The following requirements are installed during the `Installation`_ step
above:

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

Note that enrollment is a one-time operation. The Ansible module *does not*
synchronize data for existing nodes.  You should use the ironic CLI to do this
manually at the moment.

Additionally, it is important to note that the playbooks for enrollment are
split into three separate playbooks based on the ``ipmi_bridging`` setting.

Hardware deployment
===================

How this works?
---------------

After the nodes are enrolled, they can be deployed upon.  Bifrost is geared to
utilize configuration drives to convey basic configuration information to the
each host. This configuration information includes an SSH key to allow a user
to login to the system.

To utilize the newer dynamic inventory based deployment::

  export BIFROST_INVENTORY_SOURCE=/tmp/baremetal.json
  ansible-playbook -vvvv -i inventory/bifrost_inventory.py deploy-dynamic.yaml

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

Testing with a single command
=============================

A simple ``scripts/test-bifrost.sh`` script can be utilized to install
pre-requisite software packages, Ansible, and then execute the
``test-bifrost-create-vm.yaml`` and ``test-bifrost.yaml`` playbooks in order
to provide a single step testing mechanism.

``playbooks/test-bifrost-create-vm.yaml`` creates one or more VMs for
testing and saves out a baremetal.csv file which is used by
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

Legacy - testing with virtual machines
======================================

Bifrost supports using virtual machines to emulate the hardware. All of the
steps mentioned above are mostly the same.

It is assumed you have an SSH server running on the host machine. The
``agent_ssh`` driver, used by ironic with VM testing, will need to use
SSH to control the virtual machines.

An SSH key is generated for the ``ironic`` user when testing. The
ironic conductor will use this key to connect to the host machine and
run virsh commands.

#. Set ``testing`` to *true* in the
   ``playbooks/inventory/group_vars/localhost`` file.
#. You may need to adjust the value for ``ssh_public_key_path``.
#. Run the install step, as documented above, however adding ``-e
   testing=true`` to the Ansible command line.
#. Execute the ``ansible-playbook -vvvv -i inventory/localhost
   test-bifrost-create-vm.yaml`` command to create a test virtual
   machine.
#. Set the environment variable of ``BIFROST_INVENTORY_SOURCE`` to the
   path to the csv file, which by default has been written to
   /tmp/baremetal.csv.
#. Run the enrollment step, as documented above, using the CSV file
   you created in the previous step.
#. Run the deployment step, as documented above.

Deployment and configuration of operating systems
=================================================

By default, Bifrost deploys a configuration drive which includes the user SSH
public key, hostname, and the network configuration in the form of
network_info.json that can be read/parsed by the
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

Custom IPA images
=================

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

Driver Support
==============

Testing Mode
------------

When setup in testing mode, bifrost configures ironic to utilize the
``agent_ssh`` driver to help facilitate the deployment of local test
machines.

Default Mode
------------

When not in testing mode, bifrost enables the following ironic drivers:

* agent_ipmitool
* pxe_amt
* agent_ilo
* agent_ucs

OneView Driver Support
----------------------

As the OneView driver requires configuration information to be populated
in the ironic.conf configuration file that points to the OneView manager
node as well as credentials, bifrost does not support installation and
configuration of the driver.

Please reference the ironic OneView driver documentation at if you wish
to update the configuration after installation in order to leverage bifrost
for mass node deployment.

The OneView documentation can be found
`here <http://docs.openstack.org/developer/ironic/drivers/oneview.html>`_.

Virtualenv installation support (EXPERIMENTAL)
==============================================

Bifrost can be used with a python virtual environment. At present,
this feature is experimental, so it's disabled by default. If you
would like to use a virtual environment, you'll need to modify the
install steps slightly. To set up the virtual environment and install
ansible into it, run ``env-setup.sh`` as follows::

  export VENV=/opt/stack/bifrost
  ./scripts/env-setup.sh

Then run the install playbook with the following arguments::

  ansible-playbook -vvvv -i inventory/localhost install.yaml

This will install ironic and its dependencies into the virtual environment.
