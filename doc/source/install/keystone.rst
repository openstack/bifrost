Installation with Keystone
==========================

.. NOTE:: Use of keystone with bifrost is a very new feature and should
   be considered an advanced topic. Please feel free to reach out to the
   bifrost contributors and the ironic community as a whole in the project's
   `IRC`_ channel.

.. _`IRC`: https://wiki.openstack.org/wiki/Ironic#IRC

Bifrost can now install and make use of keystone. In order to enable
this as part of the installation, the ``enable_keystone`` variable
must be set to ``true``, either in ``playbooks/inventory/group_vars/target``
or on the command line during installation. Example::

    ansible-playbook -vvvv -i inventory/target install.yaml -e enable_keystone=true

However, prior to installation, overriding credentials should be set
in order to customize the deployment to meet your needs.

* ``playbooks/roles/bifrost-ironic-install/defaults/main.yml``
* ``playbooks/roles/bifrost-keystone-install/defaults/main.yml``

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

By default, during bifrost installation, when keystone is enabled,
a file will be written to the user's home directory that is executing
the installation.  That file can be located at
``~/.config/openstack/clouds.yaml``. The cloud that is written
to that file is named ``bifrost``.
