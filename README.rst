#######
Bifrost
#######

Bifrost (pronounced bye-frost) is a set of Ansible playbooks that
automates the task of deploying a base image onto a set of known hardware using
ironic. It provides modular utility for one-off operating system deployment
with as few operational requirements as reasonably possible.

========================
Team and repository tags
========================

.. image:: http://governance.openstack.org/badges/bifrost.svg
    :target: http://governance.openstack.org/reference/tags/index.html

.. Change things from this point on

=========
Use Cases
=========

* Installation of ironic in standalone/noauth mode without other OpenStack
  components.
* Deployment of an operating system to a known pool of hardware as
  a batch operation.
* Testing and development of ironic in a standalone use case.

==========
How to Use
==========

Installation and use of bifrost is split into roughly three steps:

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

* Ubuntu 14.04, 14.10, 15.04, 16.04
* Red Hat Enterprise Linux (RHEL) 7
* CentOS 7
* Fedora 22
* openSUSE Leap 42.1, 42.2

============
Installation
============

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

Bifrost Installation
====================

The installation is split into two parts.

The first part is a bash script which lays the basic groundwork of installing
Ansible itself.

Bifrost source code should be pulled directly from git first::

  git clone https://git.openstack.org/openstack/bifrost.git
  cd bifrost

Edit ``./playbooks/inventory/group_vars/*`` to match your environment. The
target file is intended for steps executed upon the target server, such as
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

The recommended path for use is with a local Ansible installation, and to
install the library requirements. Alternatively the ``env-setup.sh`` script
will install ansible and all of bifrost's dependencies.

If you use ``env-setup.sh``, ansible will be installed along
with its missing Python dependencies into user's ``~/.local`` directory.

Warning::

  Use of the ``env-setup.sh`` script can squash an existing
  Ansible installation, and is intended primarily for development
  and testing.

Note::

  The next setup steps require elevated privilges, and might need to
  be executed with the ``sudo`` command, depending on the access rights
  of the user executing the command.

If using the environment setup script::

  bash ./scripts/env-setup.sh
  export PATH=${HOME}/.local/bin:${PATH}
  cd playbooks

Otherwise::

  pip install -r requirements.txt
  cd playbooks

The second part is an Ansible playbook that installs and configures ironic
in a stand-alone fashion.

* Keystone is NOT installed by default, and ironic's API is accessible without
  authentication.  It is possible to put basic password auth on ironic's API by
  changing the nginx configuration accordingly.

  * Bifrost playbooks can leverage and optionally install keystone.
    See `doc/source/keystone.rst`.

* Neutron is NOT installed. Ironic performs static IP injection via
  config-drive.
* dnsmasq is configured statically and responds to all PXE boot requests by
  chain-loading to iPXE, which then fetches the ironic-python-agent ramdisk
  from Nginx.
* Deployments are performed by the Ironic Python Agent, which as configured
  supports IPMI, iLO, and UCS drivers.
* By default, installation will build an Ubuntu-based image for deployment
  to nodes.  This image can be easily customized if so desired.

The re-execution of the playbook will cause states to be re-asserted.  If not
already present, a number of software packages including MySQL and RabbitMQ
will be installed on the host.  Python code will be reinstalled regardless if
it has changed, RabbitMQ user passwords will be reset, and services will be
restarted.

Run::

  If you have passwordless sudo enabled, run:
     ansible-playbook -vvvv -i inventory/target install.yaml
  Otherwise, add -K option to let Ansible prompting for the sudo  password:
     ansible-playbook -K -vvvv -i inventory/target install.yaml

With regard to testing, ironic's node cleaning capability is disabled by
default as it can be an unexpected surprise for a new user that their test
node is unusable for however long it takes for the disks to be wiped.

If you wish to enable cleaning, you can achieve this by passing the option
``-e cleaning=true`` to the command line or executing the command below::

  ansible-playbook -K -vvvv -i inventory/target install.yaml -e cleaning=true

After you have performed an installation, you can edit /etc/ironic/ironic.conf
to enable or disable cleaning as desired, however it is highly encouraged to
utilize cleaning in any production environment.

The ironic community maintains a repository additional of drivers outside ironic.
These drivers and information about them can be found in
`ironic-staging-drivers docs <http://git.openstack.org/cgit/openstack/ironic-staging-drivers/>`_.
If you would like to install the ironic staging drivers, simply pass
``-e staging_drivers_include=true`` when executing the install playbook::

  ansible-playbook -K -vvvv -i inventory/target install.yaml -e staging_drivers_include=true

==============
Driver Support
==============


Testing Mode
============

When setup in testing mode, bifrost configures ironic to utilize the
``agent_ssh`` driver to help facilitate the deployment of local test
machines.


Default Mode
============

When not in testing mode, bifrost enables the following ironic drivers:

* agent_ipmitool
* agent_ilo
* agent_ucs


OneView Driver Support
======================

As the OneView driver requires configuration information to be populated
in the ironic.conf configuration file that points to the OneView manager
node as well as credentials, bifrost does not support installation and
configuration of the driver.

Please reference the ironic OneView driver documentation at if you wish
to update the configuration after installation in order to leverage bifrost
for mass node deployment.

More information about this driver can be found in the
`OneView driver documentation <http://docs.openstack.org/developer/ironic/drivers/oneview.html>`_.
