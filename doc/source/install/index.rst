####################
Bifrost Installation
####################

============
Introduction
============

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

Installing bifrost on RHEL or CentOS requires a few extra pre-install steps,
in order to have access to the additional packages contained in the EPEL
repository. Some of the software bifrost leverages, can only be obtained from
EPEL on RHEL and CentOS systems.

.. note:: Use of EPEL repositories may result in incompatible packages
          being installed by the package manager. Care should be taken
          when using a system with EPEL enabled.

RHEL
----

Enable additional repositories (RHEL only)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The ``extras`` and ``optional`` yum repositories must be enabled to satisfy
bifrost's dependencies. To check::

   sudo yum repolist | grep 'optional\|extras'

To view the status of repositories::

   sudo yum repolist all | grep 'optional\|extras'

The output will look like this::

  !rhui-REGION-rhel-server-debug-extras/7Server/x86_64        Red H disabled
  rhui-REGION-rhel-server-debug-optional/7Server/x86_64       Red H disabled
  rhui-REGION-rhel-server-extras/7Server/x86_64               Red H disabled
  rhui-REGION-rhel-server-optional/7Server/x86_64             Red H disabled
  rhui-REGION-rhel-server-source-extras/7Server/x86_64        Red H disabled
  rhui-REGION-rhel-server-source-optional/7Server/x86_64      Red H disabled

Use the names of the repositories (minus the version and architecture)
to enable them::

  sudo yum-config-manager --enable rhui-REGION-rhel-server-optional
  sudo yum-config-manager --enable rhui-REGION-rhel-server-extras

Enable the EPEL repository
^^^^^^^^^^^^^^^^^^^^^^^^^^

The Extra Packages for Enterprise Linux (EPEL) repository contains
some of bifrost's dependencies. To enable it, install the
``epel-release`` package as follows::

  sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

CentOS
------

Enable the EPEL repository (CentOS)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To enable EPEL on CentOS, run::

  sudo yum install epel-release

Performing the installation
===========================

Installation is split into four parts:

* Cloning the bifrost repository
* Installation of Ansible
* Configuring settings for the installation
* Execution of the installation playbook

.. note:: The documentation expects that you have a copy of the repository
          on your local machine, and that your working directory is inside
          of the copy of the bifrost repository.

Cloning
-------

Clone the Bifrost repository::

  git clone https://git.openstack.org/openstack/bifrost.git
  cd bifrost

Installation of Ansible
-----------------------

Installation of Ansible can take place using the provided environment setup
script located at ``scripts/env-setup.sh`` which is present in the bifrost
repository. This may also be used if you already have ansible, as it will
install ansible and various dependencies to ``~/.local`` in order to avoid
overwriting or conflicting with a system-wide Ansible installation.

If you use ``env-setup.sh``, ansible will be installed along
with its missing Python dependencies into user's ``~/.local`` directory.

Alternatively, if you have a working Ansible installation,
under normal circumstances the installation playbook can be executed.

.. note:: All testing takes place utilizing the ``scripts/env-setup.sh``
          script. Please feel free to submit
          `bug reports <https://bugs.launchpad.net/bifrost/>`_ or patches
          to OpenStack Gerrit for any issues encountered if you choose to
          directly invoke the playbooks without using ``env-setup.sh``.

Pre-installation settings
-------------------------

Before performing the installation, it is highly recommended that you edit
``./playbooks/inventory/group_vars/*`` to match your environment. Several
files are located in this folder, and you may wish to review and edit the
settings across multiple files:

* The ``target`` file is used by roles that execute against the target node
  upon which you are installing ironic and all required services.
* The ``baremetal`` file is geared for roles executed against baremetal
  nodes. This may be useful if you are automating multiple steps involving
  deployment and configuration of nodes beyond deployment via the same
  roles.
* The ``localhost`` file is similar to the ``target`` file, and likely
  contains identical settings. This file is referenced if no explicit
  target is defined, as it defaults to the localhost.

Duplication between variable names does occur within these files, as
variables are unique to the group that the role is being executed
upon.

- If MySQL is already installed, update ``mysql_password`` to match
  your local installation.
- Change ``network_interface`` to match the interface that will need
  to service DHCP requests.
- Change the ``ironic_db_password`` which is set by ansible in MySQL
  and in ironic's configuration file.

The install process, when executed will either download, or build
disk images for the deployment of nodes, and be deployed to the nodes.

If you wish to build an image, based upon the settings, you will need
to set ``create_image_via_dib`` to ``true``.

.. note:: Bifrost does not overwrite pre-existing IPA ramdisk and
          deployment image files. As such, you will need to remove
          the files if you wish to rebuild them.
          These files typically consist the default files:
          ``/httpboot/deployment_image.qcow2``, ``/httpboot/ipa.kernel``,
          ``/etc/httpboot/ipa.initramfs``.

If you are running the installation behind a proxy, export the
environment variables ``http_proxy``, ``https_proxy`` and ``no_proxy``
so that ansible will use these proxy settings.

Installing
----------

Dependencies
^^^^^^^^^^^^

In order to really get started, you must install dependencies.

If you used the ``env-setup.sh`` environment setup script::

  bash ./scripts/env-setup.sh
  export PATH=${HOME}/.local/bin:${PATH}
  cd playbooks

Otherwise::

  pip install -r requirements.txt
  cd playbooks

Once the dependencies are in-place, you can execute the ansible playbook to
perform the actual installation. The playbook will install and configure
ironic in a stand-alone fashion.

A few important notes:

* The OpenStack Identity service (keystone) is NOT installed by default,
  and ironic's API is accessible without authentication. It is possible
  to put basic password authentication on ironic's API by changing the nginx
  configuration accordingly.

.. note:: Bifrost playbooks can leverage and optionally install keystone.
          See :doc:`Keystone install details <keystone>`.

* The OpenStack Networking service (neutron) is NOT installed. Ironic performs
  static IP injection via config-drive or DHCP reservation.
* Deployments are performed by the ironic python agent (IPA).
* dnsmasq is configured statically and responds to all PXE boot requests by
  chain-loading to iPXE, which then fetches the Ironic Python Agent ramdisk
  from nginx.
* By default, installation will build an Ubuntu-based image for deployment
  to nodes. This image can be easily customized if so desired.

The re-execution of the playbook will cause states to be re-asserted.  If not
already present, a number of software packages including MySQL and RabbitMQ
will be installed on the host.  Python code will be reinstalled regardless if
it has changed. RabbitMQ user passwords will be reset, and services will be
restarted.

Playbook Execution
^^^^^^^^^^^^^^^^^^

If you have passwordless sudo enabled, run::

  ansible-playbook -vvvv -i inventory/target install.yaml

Otherwise, add the ``-K`` to the ansible command line, to trigger ansible
to prompt for the sudo password::

  ansible-playbook -K -vvvv -i inventory/target install.yaml

With regard to testing, ironic's node cleaning capability is disabled by
default as it can be an unexpected surprise for a new user that their test
node is unusable for however long it takes for the disks to be wiped.

If you wish to enable cleaning, you can achieve this by passing the option
``-e cleaning=true`` to the command line or executing the command below::

  ansible-playbook -K -vvvv -i inventory/target install.yaml -e cleaning=true

After you have performed an installation, you can edit
``/etc/ironic/ironic.conf`` to enable or disable cleaning as desired.
It is highly encouraged to utilize cleaning in any production environment.

Additional ironic drivers
=========================

An additional collection of drivers are maintained outside of the ironic source
code repository, as they do not have Continuous Integration (CI) testing.

These drivers and information about them can be found in
`ironic-staging-drivers docs <https://git.openstack.org/cgit/openstack/ironic-staging-drivers/>`_.
If you would like to install the ironic staging drivers, simply pass
``-e staging_drivers_include=true`` when executing the install playbook::

  ansible-playbook -K -vvvv -i inventory/target install.yaml -e staging_drivers_include=true

Advanced Topics
===============

.. toctree::
   :maxdepth: 1

   keystone
   offline-install
   virtualenv
   oneview
