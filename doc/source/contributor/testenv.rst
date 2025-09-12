===================
Testing Environment
===================

Quick start with bifrost-cli
============================

This section provides a structured process to set up and deploy nodes using
the Bifrost test environment. It is ideal for users who want a quick
and guided approach without diving into detailed configurations upfront.

Clone Bifrost repository:

.. code-block:: bash

    git clone https://opendev.org/openstack/bifrost

    cd bifrost

.. note::
   This example uses the development branch ``master``. If you prefer to use
   a stable release, switch to the corresponding stable branch. For example:

.. code-block:: bash

       git checkout stable/2025.1

Set up SSH key pairs:

Bifrost requires that the user who executes bifrost has an SSH key in their
user home, or that the user defines a variable to tell bifrost
where to identify this file.

.. code-block:: bash

   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

.. note::
   The above example uses an RSA key, but other key types such as ``ed25519``
   are also supported. Choose the key type that
   best suits your security and compatibility needs.

Set up and configure a test environment:

If you want to try Bifrost on virtual machines instead of real hardware, you
need to prepare a testing environment. The easiest way is via ``bifrost-cli``,
available since the Victoria release series:

.. code-block:: bash

   ./bifrost-cli testenv

See the built-in documentation for more details:

.. code-block:: bash

     ./bifrost-cli testenv --help

To install Bifrost services inside the testenv:

.. code-block:: bash

     ./bifrost-cli install --testenv

Additionally, the following parameters can be useful:

``--driver=[ipmi|redfish]``
    Choose the default driver for the generated nodes inventory.

    .. note::
       Both IPMI and Redfish support is configured anyway, so you can switch
       the drivers on fly if needed.

       IPMI support uses VirtualBMC_, Redfish - sushy-tools_.

``--uefi``
    Makes the testing VMs boot with UEFI.

Activate the testenv and utilize the baremetal CLI in no-auth
mode with clouds.yaml:

    .. note::
       You still need to restart services to apply any changes, e.g.::

        sudo systemctl restart ironic

.. code-block:: bash

   source /opt/stack/bifrost/bin/activate

   export OS_CLOUD=bifrost

Verify that Ironic and its drivers are installed and operational:

.. code-block:: bash

   baremetal node list

   baremetal driver list

Enroll nodes using the pre-existing inventory:

The command `./bifrost-cli testenv` generates two files with node inventory
in the current directory:

* ``baremetal-inventory.json`` can be used with the provided playbooks, see
  :doc:`/user/howto` for details. Use the command:

.. code-block:: bash

   ./bifrost-cli enroll baremetal-inventory.json

* ``baremetal-nodes.json`` can be used with the Ironic enrollment command:

.. code-block:: bash

   export OS_CLOUD=bifrost

   baremetal create baremetal-nodes.json

Deploy the Enrolled Nodes:

.. code-block:: bash

   ./bifrost-cli deploy baremetal-inventory.json

Verify Deployment:

The following command should show the node in an `active` provision state
after a successful deployment.

.. code-block:: bash

   baremetal node list

Reproduce CI testing locally
============================

A simple ``scripts/test-bifrost.sh`` script can be utilized to install
pre-requisite software packages, Ansible, and then execute the
``test-bifrost-create-vm.yaml`` and ``test-bifrost.yaml`` playbooks in order
to provide a single step testing mechanism.

``playbooks/test-bifrost-create-vm.yaml`` creates one or more VMs for
testing and saves out a baremetal.json file which is used by
``playbooks/test-bifrost.yaml`` to execute the remaining roles.  Two
additional roles are invoked by this playbook which enables Ansible to
connect to the new nodes by adding them to the inventory, and then
logging into the remote machine via the user\'s ssh host key.  Once
that has successfully occurred, additional roles will unprovision the
host(s) and delete them from ironic.

Command::

  scripts/test-bifrost.sh

Note:

- In order to cap requirements for installation, an ``upper_constraints_file``
  setting is defined. This is consuming the ``UPPER_CONSTRAINTS_FILE`` or
  ``TOX_CONSTRAINTS_FILE`` env var by default, to properly integrate with CI
  systems, and will default to
  ``/opt/stack/requirements/upper-constraints.txt`` file if not present.

Manually test with Virtual Machines
===================================

Bifrost supports using virtual machines to emulate the hardware.

The VirtualBMC_ project is used as an IPMI proxy, so that the same ``ipmi``
hardware type can be used as for real hardware. Redfish emulator from
sushy-tools_ is also installed.

#. Set ``testing`` to *true* in the
   ``playbooks/inventory/group_vars/target`` file.
#. You may need to adjust the value for ``ssh_public_key_path``.
#. Execute the ``ansible-playbook -vvvv -i inventory/target
   test-bifrost-create-vm.yaml`` command to create a test virtual
   machine.
#. Run the install step, as documented in :doc:`/install/index`, however
   adding ``-e testing=true`` to the Ansible command line.
#. Set the environment variable of ``BIFROST_INVENTORY_SOURCE`` to the
   path to the JSON file, which by default has been written to
   ``/tmp/baremetal.json``.
#. Run the :ref:`enrollment step <enroll>`, using the JSON file you created
   in the previous step.
#. Run the deployment step, as documented in :ref:`deploy`.

.. _VirtualBMC: https://docs.openstack.org/virtualbmc/
.. _sushy-tools: https://docs.openstack.org/sushy-tools/

Virtual Switching
-----------------
By default, Bifrost sets up a Linux bridge as the virtual switch
interconnecting the virtual machines that implement the nodes.  To support
more complex test scenarios, it is possible to configure OVS as the virtual
switch.  This enables updates to port VLAN assignments to test complex
networking scenarios.

The virtual switch type can be controlled by modifying the
``test_vm_switch_type`` variable via ansible extra vars supplied to the Ansible
commands or via bifrost-cli's ``-e`` option.  Setting the variable to 'ovs'
enables the OVS switch type.

