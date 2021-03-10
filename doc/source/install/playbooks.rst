==========================
Installation via playbooks
==========================

Countrary to :ref:`bifrost-cli`, this method of installation allows full
control over all parameters, as well as injecting your own ansible playbooks.

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
