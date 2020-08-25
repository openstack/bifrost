Installation with Keystone
==========================

Bifrost can now install and make use of keystone. In order to enable
this as part of the installation, the ``enable_keystone`` variable
must be set to ``true``, either in ``playbooks/inventory/group_vars/target``
or on the command line during installation. Note that enable_keystone and
noauth_mode are mutually exclusive so they should have an opposite value of
oneanother. Example::

    ansible-playbook -vvvv -i inventory/target install.yaml -e enable_keystone=true -e noauth_mode=false

However, prior to installation, overriding credentials should be set
in order to customize the deployment to meet your needs. At the very least,
the following parameters should be changed for a production environment:

``admin_password``
    Password for the bootstrap user (called ``admin`` by default).
``default_password``
    Password for the regular user (called ``bifrost_user`` by default).
``service_password``
    Password for communication between services (never exposed to end users).

If any of these values is not set, a random password is generated during the
initial installation and stored on the controller in an accordingly named file
in the ``~/.config/bifrost`` directory (override using ``password_dir``).

See the following files for more settings that can be overridden:

* ``playbooks/roles/bifrost-ironic-install/defaults/main.yml``
* ``playbooks/roles/bifrost-keystone-install/defaults/main.yml``

.. _keystone-tls:

TLS notes
---------

There are two important limitations to keep in mind when using Keystone with
TLS:

* It's not possible to enable TLS on upgrade from Bifrost < 9.0 (Ussuri
  and early Victoria). First do an upgrade to Bifrost >= 9.0, then enable TLS
  in a separate step.

* Automatically updating from a TLS environment to a non-TLS one may not be
  possible if using custom TLS certificates in a non-standard location
  (``/etc/bifrost/bifrost.crt``). You need to manually change identity
  endpoints in the catalog from ``https`` to ``http`` directly before
  an update. The ``public`` endpoint **must** be updated **last** or you may
  lock yourself out of keystone.

Using an existing Keystone
--------------------------

If you choose to install bifrost using an existing keystone, this
should be possible, however it has not been tested. In this case you
will need to set the appropriate defaults, via
``playbooks/roles/bifrost-ironic-install/defaults/main.yml``
which would be a good source for the role level defaults.
Ideally, when setting new defaults, they should be set in the
``playbooks/inventory/group_vars/target`` file.

Creation of clouds.yaml
-----------------------

By default, during bifrost installation, a file will be written to the user's
home directory that is executing the installation. That file can be located at
``~/.config/openstack/clouds.yaml``. The clouds that are written
to that file are named ``bifrost`` (for regular users) and ``bifrost-admin``
(for administrators).

Creation of openrc
------------------

Also by default, after bifrost installation and again, when keystone
is enabled, a file will be written to the user's home directory that
you can use to set the appropriate environment variables in your
current shell to be able to use OpenStack utilities::

    . ~/openrc bifrost
    openstack baremetal driver list
