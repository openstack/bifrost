####################
Bifrost Installation
####################

============
Introduction
============

This document will guide you through installing the Bare Metal Service (ironic)
using Bifrost.

Supported operating systems
===========================

Full support (fully tested in the CI, no known or potential issues):

* CentOS Stream 9

  .. note::
     RHEL 9 and derivatives are assumed to work but not tested explicitly.

* Ubuntu 22.04 "Jammy"
* Debian 11 "Bullseye" and 12 "Bookworm"

.. note::
   Operating systems evolve and so does the support for them, even on stable
   branches.

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

If you want to understand what and how is installed by Bifrost, please see
:doc:`/user/architecture`.

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

* Whether to use the integrated DHCP server or an external DHCP service.

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

.. warning::

   Testenv for bifrost will default to using the default libvirt network. If you
   are installing the testenv inside a VM using the default libvirt network, you
   will encounter errors.

.. _bifrost-cli:

============================
Quick start with bifrost-cli
============================

The ``bifrost-cli`` script, available since the Victoria release series,
installs the Bare Metal service with the recommended defaults.
Follow :doc:`playbooks` if using Ussuri or older or if you need a full control
over your environment.

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

``--uefi`` / ``--legacy-boot``
    Boot machines in the UEFI or BIOS mode by default (defaults to UEFI).

``--disable-dhcp``
    Disable the configuration of the integrated DHCP server, allowing to use
    an external DHCP service.

``--develop``
    Install services in develop mode, so that the changes to the repositories
    in ``/opt`` get immediately reflected in the environment.


See the built-in documentation for more details:

.. code-block:: bash

    ./bifrost-cli install --help

The Ansible variables generated for installation are stored in a JSON file
(``baremetal-install-env.json`` by default) that should be passed via the
``-e`` flag to subsequent playbook or command invocations.

.. _custom-ipa-images:

Build Custom Ironic Python Agent (IPA) images
=============================================

Bifrost supports the ability for a user to build a custom IPA ramdisk
utilizing diskimage-builder and ironic-python-agent-builder. In order
to utilize this feature, the ``download_ipa`` setting must be set to ``false``
and the create_ipa_image must be set to "true".  By default, the install
playbook will build a Debian Bookworm based IPA image, if a pre-existing IPA
image is not present on disk. If you wish to explicitly set a specific release
to be passed to diskimage-create, then the setting ``dib_os_release`` can be
set in addition to ``dib_os_element``.

If you wish to include an extra element into the IPA disk image, such as a
custom hardware manager, you can pass the variable ``ipa_extra_dib_elements``
as a space-separated list of elements. This defaults to an empty string.

Using Bifrost
=============

After installation is done, export the following environment variable to
configure the bare metal client to use the ``bifrost`` cloud configuration from
the generated ``clouds.yaml`` (see :ref:`baremetal-cli` for details):

.. code-block:: shell

   export OS_CLOUD=bifrost

Now you can use Ironic directly, see the `standalone guide`_ for more details.
Alternatively, you can use the provided playbooks to automate certain common
operations - see :doc:`/user/howto`.

.. _standalone guide: https://docs.openstack.org/ironic/latest/install/standalone.html

===============
Advanced Topics
===============

.. toctree::
   :maxdepth: 2

   playbooks
   keystone
   offline-install

.. toctree::
   :hidden:

   virtualenv
