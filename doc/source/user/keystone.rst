.. _keystone:

.. NOTE:: Use of keystone with bifrost is a very new feature and should
   be considered an advanced topic. Please feel free to reach out to the
   bifrost contributors and the ironic community as a whole in the project's
   `IRC`_ channel.

.. _`IRC`: https://wiki.openstack.org/wiki/Ironic#IRC

Bifrost execution with Keystone
===============================

Ultimately, as bifrost was designed for relatively short-lived
installations to facilitate rapid hardware deployment, the default
operating mode is referred to as ``noauth`` mode. With that,
in order to leverage keystone authentication for the roles,
one of the following steps need to take place.

#. Update the role defaults for each role you plan to make use.
   This may not make much sense  for most users, unless they are
   carrying such changes as downstream debt.
#. Invoke ansible-playbook with variables being set to override
   the default behavior. Example::

       -e noauth_mode=false -e cloud_name=bifrost

#. Set the global defaults for tagret
   (``master/playbooks/inventory/group_vars/target``).

OpenStack Client use with bifrost installed Keystone
----------------------------------------------------

A user wishing to invoke OSC commands against the bifrost
installation, should set the ``OS_CLOUD`` environment variable.
An example of setting the environment variable and then executing
the OSC command to list all baremetal nodes::

    export OS_CLOUD=bifrost
    openstack baremetal node list

Keystone roles
--------------

Ironic, which is the underlying OpenStack component bifrost
helps a user leverage, supports two different roles in keystone
that helps govern the rights a user has in keystone.

These roles are ``baremetal_admin`` and ``baremetal_observer``
and a user can learn more about the roles from the ironic `install
guide`_.

.. _`install guide`: http://docs.openstack.org/project-install-guide/baremetal/draft/configure-integration.html#configure-the-identity-service-for-the-bare-metal-service

Individual playbook use with os-client-config
=============================================

The OpenStack Ansible modules utilize os-client-config to obtain
authentication details to connect to determine details.

If ``noauth_mode`` is explicitly disabled, the bifrost roles that
speak with Ironic for actions such as enrollment of nodes and
deployment, automatically attempt to collect authentication
data from os-client-config. Largely these details are governed
as environment variables.

That being said, os-client-config supports the concept of clouds
and an a user can explicitly select the cloud they wish to deploy
to via the ``cloud_name`` parameter.
