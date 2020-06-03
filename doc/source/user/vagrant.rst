.. _vagrant:

Bifrost via Vagrant
===================

One of the main user audiences that we've found is for users to utilize
vagrant in order to build quick development environments, or for their
environments to facilitate deployments, as the intent is for relatively
short lived installations.

As such, a virtual machine can be started with vagrant executing the
following commands::

  cd tools/vagrant_dev_env
  vagrant up

This will bring up an Ubuntu based virtual machine, with bifrost
installed.

.. note:: Virtual machine images, as well as all of the software
          used in bifrost can take some time to install. Typically
          expect ``vagrant up`` to take at least fifteen minutes if
          you do not already have the virtual machine image on your
          machine.

By default, the VM will have three interfaces:

- **eth0** - connected to a NAT network
- **eth1** - connected to Host-only network named: vboxnet1
- **eth2** - bridged - adapter must be set in Vagrantfile

Walkthrough done on OS X
-------------------------
Setup vagrant by:

- Installing git
- Installing virtualbox
- Installing vagrant
- Installing ansible

Configure Vagrant with the correct box::

  vagrant box add ubuntu/bionic64

Clone bifrost repo::

  git clone https://opendev.org/openstack/bifrost

Change into the bifrost directory::

  cd bifrost/tools/vagrant_dev_env

Edit the Vagrantfile:

- Change the ``bifrost.vm.network`` ``public_network`` value to a
  valid network interface to allow Bare Metal connectivity
- Change ``public_key`` to correct key name
- Change ``network_interface`` to match your needs


Boot the VM with::

  vagrant up

Installation Options
--------------------
Ansible is installed within the VM directly from `source
<https://github.com/ansible/ansible.git>`_ or from the path set by
``ANSIBLE_GIT_URL``. You can modify the path of installation by setting
``ANSIBLE_INSTALL_ROOT`` environment variable. The default value is
``/opt/stack``. When set in the host, this variable will also be set as an
environment variable inside the VM for use by test scripts.

Note:

  Only the ansible installation path is configurable at this point using
  the environment variable. All other dependencies will still continue to
  cloned under ``/opt/stack``.
