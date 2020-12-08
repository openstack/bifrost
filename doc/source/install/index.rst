####################
Bifrost Installation
####################

============
Introduction
============

This document will guide you through installing the Bare Metal Service (ironic)
using Bifrost.

Requirements
============

Supported operating systems:

* Ubuntu 18.04, 20.04
* CentOS 8 Stream (normal CentOS 8 and RHEL 8 should work but are not tested)
* openSUSE Leap 15.2 (15.1 is supported but not recommended)
* Fedora 32 (30 is supported but not recommended)
* Debian Buster

Bifrost structure
=================

Installation and use of Bifrost is split into roughly three steps:

- **install**:
  prepare the local environment by downloading and/or building machine images,
  and installing and configuring the necessary services.
- **enroll-dynamic**:
  take as input a customizable hardware inventory file and enroll the
  listed hardware with ironic, configuring each appropriately for deployment
  with the previously-downloaded images.
- **deploy-dynamic**:
  instruct ironic to deploy the operating system onto each machine.

Installation of Bifrost can be done in three ways:

* Via the ``bifrost-cli`` command line tool.

  This is the path recommended for those who want something that just works.
  It provides minimum configuration and uses the recommended defaults.

* By directly invoking ``ansible-playbook`` on one of provided playbooks.

* By writing your own playbooks using Ansible roles provided with Bifrost.

=================
Pre-install steps
=================

Know your environment
=====================

Before you start, you need to gather certain facts about your bare metal
environment (this step can be skipped if you're testing Bifrost on virtual
machines).

For the machine that hosts Bifrost you'll need to figure out:

* The network interface you're going to use for communication between the bare
  metal machines and the Bifrost services.

  On systems using firewalld (Fedora, CentOS and RHEL currently), a new zone
  ``bifrost`` will be created, and the network interface will be moved to it.
  DHCP, PXE and API services will only be added to this zone. If you need any
  of them available in other zones, you need to configure firewall yourself.

  .. warning::
    If you use the same NIC for bare metal nodes and external access,
    installing bifrost may lock you out of SSH to the node. You have two
    options:

    #. Pre-create the ``bifrost`` firewalld zone before installation and add
       the SSH service to it.
    #. Use the ``public`` zone by providing ``firewalld_internal_zone=public``
       when installing.

* Pool of IP addresses for DHCP (must be within the network configured on the
  chosen network interface).

* Whether you want the services to use authentication via Keystone_.

For each machine that is going to be enrolled in the Bare Metal service you'll
need:

* The management technology you are going to use to control the machine (IPMI,
  Redfish, etc). See `bare metal drivers`_ for guidance.
* An IP address or a host name of its management controller (BMC).
* Credentials for the management controller.
* MAC address of the NIC the machine uses for PXE booting (optional for IPMI).
* Whether it boots in the UEFI or legacy (BIOS) mode.

  .. note::
     Some hardware types (like ``redfish``) can enforce the desired boot mode,
     while the other (like ``ipmi``) require the same boot mode to be set in
     ironic and on the machine.

.. _Keystone: https://docs.openstack.org/keystone/latest/
.. _bare metal drivers: https://docs.openstack.org/ironic/latest/admin/drivers.html

Required packages
=================

To start with Bifrost you will need Python 3.6 or newer and the ``git`` source
code management tool.

On CentOS/RHEL/Fedora:

.. code-block:: bash

   sudo dnf install -y git python3

On Ubuntu/Debian:

.. code-block:: bash

   sudo apt-get update
   sudo apt-get install -y python3 git

On openSUSE:

.. code-block:: bash

   sudo zipper install -y python3 git

Enable additional repositories (RHEL only)
==========================================

The ``extras`` and ``optional`` dnf repositories must be enabled to satisfy
bifrost's dependencies. To check::

   sudo dnf repolist | grep 'optional\|extras'

To view the status of repositories::

   sudo dnf repolist all | grep 'optional\|extras'

The output will look like this::

  !rhui-REGION-rhel-server-debug-extras/8Server/x86_64        Red H disabled
  rhui-REGION-rhel-server-debug-optional/8Server/x86_64       Red H disabled
  rhui-REGION-rhel-server-extras/8Server/x86_64               Red H disabled
  rhui-REGION-rhel-server-optional/8Server/x86_64             Red H disabled
  rhui-REGION-rhel-server-source-extras/8Server/x86_64        Red H disabled
  rhui-REGION-rhel-server-source-optional/8Server/x86_64      Red H disabled

Use the names of the repositories (minus the version and architecture)
to enable them::

  sudo dnf config-manager --enable rhui-REGION-rhel-server-optional
  sudo dnf config-manager --enable rhui-REGION-rhel-server-extras

Enable the EPEL repository (RHEL and CentOS)
============================================

Building Debian or Ubuntu based images on RHEL or CentOS requires a few extra
pre-install steps, in order to have access to the additional packages contained
in the EPEL repository.

Please refer to the `official wiki page <https://fedoraproject.org/wiki/EPEL>`_
to install and configure them.

.. note:: Use of EPEL repositories may result in incompatible packages
          being installed by the package manager. Care should be taken
          when using a system with EPEL enabled.

Clone Bifrost
=============

Bifrost is typically installed from git:

.. code-block:: bash

   git clone https://opendev.org/openstack/bifrost
   cd bifrost

To install Bare Metal services from a specific release series (rather than the
latest versions), check out the corresponding stable branch. For example, for
Ussuri:

.. code-block:: bash

   git checkout stable/ussuri

Testing on virtual machines
===========================

If you want to try Bifrost on virtual machines instead of real hardware, you
need to prepare a testing environment. The easiest way is via ``bifrost-cli``,
available since the Victoria release series:

.. code-block:: bash

   ./bifrost-cli testenv

Then do not forget to pass ``--testenv`` flag to ``bifrost-cli install``.

See :doc:`/contributor/testenv` for more details and for advanced ways of
creating a virtual environment (also supported on Ussuri and older).

============================
Quick start with bifrost-cli
============================

The ``bifrost-cli`` script, available since the Victoria release series,
installs the Bare Metal service with the recommended defaults.

.. note::
   Follow `Installation via playbooks`_ if using Ussuri or older.

Using it is as simple as:

.. code-block:: bash

    ./bifrost-cli install \
        --network-interface <the network interface to use> \
        --dhcp-pool <DHCP start IP>-<DHCP end IP>

For example:

.. code-block:: bash

    ./bifrost-cli install --network-interface eno1 \
        --dhcp-pool 10.0.0.20-10.0.0.100

.. note::
   See `Know your environment`_ for the guidance on the two required
   parameters.

If installing on a virtual environment, skip these two parameters:

.. code-block:: bash

    ./bifrost-cli install --testenv

Additionally, the following parameters can be useful:

``--hardware-types``
    A comma separated list of hardware types to enable.
``--enable-keystone``
    Whether to enable authentication with Keystone_.
``--enable-tls``
    Enable self-signed TLS on API endpoints.

    .. warning::
       If using Keystone_, see :ref:`keystone-tls` for important notes.

``--release``
    If using a stable version of Bifrost, the corresponding version of Ironic
    is usually detected from the git checkout. If it is not possible (e.g.
    you're using Bifrost from a tarball), use this argument to provide
    the matching version.

    .. note::
       Using Bifrost to install older versions of Ironic may work, but is not
       guaranteed.

``--enable-prometheus-exporter``
    Enable the Ironic Prometheus Exporter service.

``--uefi``
    Boot machines in the UEFI mode by default.

See the built-in documentation for more details:

.. code-block:: bash

    ./bifrost-cli install --help

==========================
Installation via playbooks
==========================

Installation is split into four parts:

* Installation of Ansible
* Configuring settings for the installation
* Execution of the installation playbook

Installation of Ansible
=======================

Installation of Ansible can take place using the provided environment setup
script located at ``scripts/env-setup.sh`` which is present in the bifrost
repository. This may also be used if you already have ansible, as it will
install ansible and various dependencies to a virtual environment in order
to avoid overwriting or conflicting with a system-wide Ansible installation.

Alternatively, if you have a working Ansible installation, under normal
circumstances the installation playbook can be executed, but you will need
to configure the `Virtual environment`_.

.. note:: All testing takes place utilizing the ``scripts/env-setup.sh``
          script. Please feel free to submit
          `bug reports <https://bugs.launchpad.net/bifrost/>`_ or patches
          to OpenStack Gerrit for any issues encountered if you choose to
          directly invoke the playbooks without using ``env-setup.sh``.

Virtual environment
===================

To avoid conflicts between Python packages installed from source and system
packages, Bifrost defaults to installing everything to a virtual environment.
``scripts/env-setup.sh`` will automatically create a virtual environment in
``/opt/stack/bifrost`` if it does not exist.

If you want to relocate the virtual environment, export the ``VENV`` variable
before calling ``env-setup.sh``::

    export VENV=/path/to/my/venv

If you're using the ansible playbooks directly (without the helper scripts),
set the ``bifrost_venv_dir`` variables accordingly.

.. note::
   Because of Ansible dependencies Bifrost only supports virtual environments
   created with ``--system-site-packages``.

Pre-installation settings
=========================

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
- Set ``service_password`` which is used for communication between services.
  If unset, a random password is generated during the initial installation and
  stored on the controller in ``~/.config/bifrost/service_password``.

The install process, when executed will either download, or build
disk images for the deployment of nodes, and be deployed to the nodes.

If you wish to build an image, based upon the settings, you will need
to set ``create_image_via_dib`` to ``true``.

If you are running the installation behind a proxy, export the
environment variables ``http_proxy``, ``https_proxy`` and ``no_proxy``
so that ansible will use these proxy settings.

TLS support
-----------

Bifrost supports TLS for API services with two options:

* A self-signed certificate can be generated automatically. Set
  ``enable_tls=true`` and ``generate_tls=true``.

  .. note:: This is equivalent to the ``--enable-tls`` flag of ``bifrost-cli``.

* Certificate paths can be provided via:

  ``tls_certificate_path``
    Path to the TLS certificate (must be world-readable).
  ``tls_private_key_path``
    Path to the private key (must not be password protected).
  ``tls_csr_path``
    Path to the certificate signing request file.

  Set ``enable_tls=true`` and do not set ``generate_tls`` to use this option.

.. warning::
   If using Keystone, see :ref:`keystone-tls` for important notes.

Dependencies
============

In order to really get started, you must install dependencies.

With the addition of ansible collections, the ``env-setup.sh`` will install
the collections in the default ansible ``collections_paths`` (according to your
ansible.cfg) or you can specify the location setting
``ANSIBLE_COLLECTIONS_PATHS``:

.. code-block:: bash

    $ export ANSIBLE_COLLECTIONS_PATHS=/mydir/collections

.. note::

   If you are using a virtual environment ANSIBLE_COLLECTIONS_PATHS is
   automatically set. After Ansible Collections are installed,
   a symbolic link to to the installation is created in the bifrost playbook
   directory.

The ``env-setup.sh`` script automatically invokes ``install-deps.sh`` and
creates a virtual environment for you:

.. code-block:: bash

    $ bash ./scripts/env-setup.sh
    $ source /opt/stack/bifrost/bin/activate
    $ cd playbooks

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
already present, a number of software packages including MySQL will be
installed on the host. Python code will be reinstalled regardless if
it has changed.

Playbook Execution
==================

Playbook based install provides a greater degree of visibility and control
over the process and is suitable for advanced installation scenarios.

Examples:

First, make sure that the virtual environment is active (the example below
assumes that bifrost venv is installed into the default path
/opt/stack/bifrost).

    $ . /opt/stack/bifrost/bin/activate
    (bifrost) $

Verify if the ansible-playbook executable points to the one installed in
the virtual environment:

    (bifrost) $ which ansible-playbook
    /opt/stack/bifrost/bin/ansible-playbook
    (bifrost) $

change to the ``playbooks`` subdirectory of the cloned bifrost repository:

    $ cd playbooks

If you have passwordless sudo enabled, run::

    $ ansible-playbook -vvvv -i inventory/target install.yaml

Otherwise, add the ``-K`` to the ansible command line, to trigger ansible
to prompt for the sudo password::

    $ ansible-playbook -K -vvvv -i inventory/target install.yaml

With regard to testing, ironic's node cleaning capability is enabled by
default, but only metadata cleaning is turned on, as it can be an unexpected
surprise for a new user that their test node is unusable for however long it
takes for the disks to be wiped.

If you wish to enable full cleaning, you can achieve this by passing the option
``-e cleaning_disk_erase=true`` to the command line or executing the command
below::

    $ ansible-playbook -K -vvvv -i inventory/target install.yaml -e cleaning_disk_erase=true

If installing a stable release, you need to set two more parameters, e.g.::

    -e git_branch=stable/train -e ipa_upstream_release=stable-train

.. note::
   Note the difference in format: git branch uses slashes, IPA release uses
   dashes.

After you have performed an installation, you can edit
``/etc/ironic/ironic.conf`` to enable or disable cleaning as desired.
It is highly encouraged to utilize cleaning in any production environment.

Additional ironic drivers
=========================

An additional collection of drivers are maintained outside of the ironic source
code repository, as they do not have Continuous Integration (CI) testing.

These drivers and information about them can be found in
`ironic-staging-drivers docs <https://opendev.org/x/ironic-staging-drivers/>`_.
If you would like to install the ironic staging drivers, simply pass
``-e staging_drivers_include=true`` when executing the install playbook::

    $ ansible-playbook -K -vvvv -i inventory/target install.yaml -e staging_drivers_include=true

===============
Advanced Topics
===============

.. toctree::
   :maxdepth: 1

   keystone
   offline-install

.. toctree::
   :hidden:

   virtualenv
