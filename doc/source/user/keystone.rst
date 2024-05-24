Using Keystone
==============

Ultimately, as bifrost was designed for relatively short-lived
installations to facilitate rapid hardware deployment, the default
operating mode is referred to as ``noauth`` mode. In order to leverage Keystone
authentication for the roles, Bifrost reads configuration from ``clouds.yaml``.
If ``clouds.yaml`` has not been generated through the
``bifrost-keystone-client-config`` role, one of the following steps need
to take place:

#. Update the role defaults for each role you plan to make use.
   This may not make much sense  for most users, unless they are
   carrying such changes as downstream debt.
#. Invoke ansible-playbook with variables being set to override
   the default behavior. Example::

       -e enable_keystone=true -e noauth_mode=false -e cloud_name=bifrost

#. Set the global defaults for target
   (``master/playbooks/inventory/group_vars/target``).

OpenStack Client usage
----------------------

A user wishing to invoke OSC commands against the bifrost
installation, should set the ``OS_CLOUD`` environment variable.
An example of setting the environment variable and then executing
the OSC command to list all baremetal nodes::

    export OS_CLOUD=bifrost
    openstack baremetal node list

For administration actions, use the ``bifrost-admin`` cloud::

    export OS_CLOUD=bifrost-admin
    openstack endpoint list

Keystone roles
--------------

Ironic, which is the underlying OpenStack component bifrost
helps a user leverage, supports two different roles in keystone
that helps govern the rights a user has in keystone.

These roles are ``baremetal_admin`` and ``baremetal_observer``
and a user can learn more about the roles from the ironic `install
guide`_.

.. _`install guide`: https://docs.openstack.org/ironic/latest/install/configure-identity.html

Individual playbook use
-----------------------

The OpenStack Ansible modules utilize ``clouds.yaml`` file to obtain
authentication details to connect to determine details. The bifrost roles that
speak with Ironic for actions such as enrollment of nodes and
deployment, automatically attempt to collect authentication
data from ``clouds.yaml``. A user can explicitly select the cloud they wish
to deploy to via the ``cloud_name`` parameter.
