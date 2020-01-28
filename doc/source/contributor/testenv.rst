===================
Testing Environment
===================

Execute local testing
=====================

A simple ``scripts/test-bifrost.sh`` script can be utilized to install
pre-requisite software packages, Ansible, and then execute the
``test-bifrost-create-vm.yaml`` and ``test-bifrost.yaml`` playbooks in order
to provide a single step testing mechanism.

``playbooks/test-bifrost-create-vm.yaml`` creates one or more VMs for
testing and saves out a baremetal.json file which is used by
``playbooks/test-bifrost.yaml`` to execute the remaining roles.  Two
additional roles are invoked by this playbook which enables Ansible to
connect to the new nodes by adding them to the inventory, and then
logging into the remote machine via the user's ssh host key.  Once
that has successfully occurred, additional roles will unprovision the
host(s) and delete them from ironic.

Command::

  scripts/test-bifrost.sh

Note:

- Cleaning mode is explicitly disabled in the ``test-bifrost.yaml``
  playbook due to the fact that is an IO-intensive operation that can
  take a great deal of time.

- In order to cap requirements for installation, an ``upper_constraints_file``
  setting is defined. This is consuming the ``UPPER_CONSTRAINTS_FILE`` env
  var by default, to properly integrate with CI systems, and will default
  to ``/opt/stack/requirements/upper-constraints.txt`` file if not present.

Manually test with Virtual Machines
===================================

Bifrost supports using virtual machines to emulate the hardware.

It is assumed you have an SSH server running on the host machine. The
``agent_ssh`` driver, used by ironic with VM testing, will need to use
SSH to control the virtual machines.

An SSH key is generated for the ``ironic`` user when testing. The
ironic conductor will use this key to connect to the host machine and
run virsh commands.

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
   /tmp/baremetal.json.
#. Run the enrollment step, as documented above, using the CSV file
   you created in the previous step.
#. Run the deployment step, as documented above.
