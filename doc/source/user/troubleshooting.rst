===============
Troubleshooting
===============

***********
Firewalling
***********

Due to the nature of firewall settings and customizations, bifrost does
**not** change any local firewalling on the node. Users must ensure that
their firewalling for the node running bifrost is such that the nodes that
are being booted can connect to the following ports::

    67/UDP for DHCP requests to be serviced
    69/UDP for TFTP file transfers (Initial iPXE binary)
    6301/TCP for the ironic API
    8080/TCP for HTTP File Downloads (iPXE, Ironic-Python-Agent)

If you encounter any additional issues, use of ``tcpdump`` is highly
recommended while attempting to deploy a single node in order to capture
and review the traffic exchange between the two nodes.

*****************
NodeLocked Errors
*****************

This is due to node status checking thread in ironic, which is a locking
action as it utilizes IPMI.  The best course of action is to retry the
operation.  If this is occurring with a high frequency, tuning might be
required.

Example error::

    NodeLocked: Node 00000000-0000-0000-0000-046ebb96ec21 is locked by
    host $HOSTNAME, please retry after the current operation is completed.

*****************************************************
New image appears not to be deploying upon deployment
*****************************************************

When deploying a new image with the same previous name, it is necessary to
purge the contents of the TFTP master_images folder which caches the image
file for deployments.  The default location for this folder is
``/tftpboot/master_images``.

Additionally, a playbook has been included that can be used prior to a
re-installation to ensure fresh images are deployed.  This playbook can
be found at ``playbooks/cleanup-deployment-images.yaml``.

*********************
Building an IPA image
*********************

Troubleshooting issues involving IPA can be time consuming.  The IPA
developers **HIGHLY** recommend that users build their own custom IPA
images in order to inject things such as SSH keys, and turn on agent
debugging which must be done in a custom image as there is no mechanism
to enable debugging via the kernel command line at present.

Custom IPA images can be built a number of ways, the most generally useful
mechanism is with diskimage-builder as the distributions typically have
better hardware support than CoreOS and Tiny Core Linux. However, CoreOS
and Tiny Core based images are what are used by the OpenStack CI for
ironic tests.

CoreOS::
  http://git.openstack.org/cgit/openstack/ironic-python-agent/tree/imagebuild/coreos/README.rst
TinyIPA::
  https://git.openstack.org/cgit/openstack/ironic-python-agent/tree/imagebuild/tinyipa/README.rst

For documentation on diskimage-builder, See::
  https://docs.openstack.org/diskimage-builder/latest/.

It should be noted that the steps for diskimage-builder installation and
use to create an IPA image for Bifrost are the same as for ironic. See:
https://docs.openstack.org/ironic/latest/install/deploy-ramdisk.html

This essentially boils down to the following steps:

#. ``git clone https://git.openstack.org/openstack/ironic-python-agent``
#. ``cd ironic-python-agent``
#. ``pip install -r ./requirements.txt``
   #. If you don't already have docker installed, execute:
   ``sudo apt-get install docker docker.io``
#. ``cd imagebuild/coreos``
#. Edit ``oem/cloudconfig.yml`` and add ``--debug`` to the end of the ExecStart
   setting for the ironic-python-agent.service unit.
#. Execute ``make`` to complete the build process.

Once your build is completed, you will need to copy the images files written
to the UPLOAD folder, into the /httpboot folder.  If your utilizing the
default file names, executing `cp UPLOAD/* /httpboot/` should achieve this.

Since you have updated the image to be deployed, you will need to purge the
contents of /tftpboot/master_images for the new image to be utilized for the
deployment process.

*********************************************
Unexpected/Unknown failure with the IPA Agent
*********************************************

Many failures due to the IPA agent can be addressed by building a custom
IPA Image.  See `Building an IPA image`_ for information on building
your own IPA image.

Obtaining IPA logs via the console
==================================

1) By default, bifrost sets the agent journal to be logged to the system
   console. Due to the variation in hardware, you may need to tune the
   parameters passed to the deployment ramdisk.  This can be done, as shown
   below in ironic.conf::

    agent_pxe_append_params=nofb nomodeset vga=normal console=ttyS0 systemd.journald.forward_to_console=yes

   Parameters will vary by your hardware type and configuration,
   however the ``systemd.journald.forward_to_console=yes`` setting is
   a default, and will only work for systemd based IPA images such as
   the CoreOS image.

   The example above, effectively disables all attempts by the kernel to set
   the video mode, defines the console as ttyS0 or the first serial port, and
   instructs systemd to direct logs to the console.

2) Once set, restart the ironic-conductor service, e.g.
   ``service ironic-conductor restart`` and attempt to redeploy the node.
   You will want to view the system console occurring. If possible, you
   may wish to use ``ipmitool`` and write the output to a log file.

Gaining access via SSH to the node running IPA on CoreOS based images
=====================================================================

If you wish to SSH into the node in order to perform any sort of post-mortem,
you will need to do the following:

1) Set an ``sshkey="ssh-rsa AAAA....."`` value on the
   ``agent_pxe_append_params`` setting in ``/etc/ironic/ironic.conf``

2) You will need to short circuit the ironic conductor process. An ideal
   place to do so is in ``ironic/drivers/modules/agent.py`` in the
   reboot_to_instance method.  Temporarily short circuiting this step
   will force you to edit the MySQL database if you wish to re-deploy
   the node, but the node should stay online after IPA has completed
   deployment.

3) ``ssh -l core <ip-address-of-node>``

Gaining access via SSH to the node running IPA for custom images
================================================================

Custom built images will require a user to be burned into the image.
Typically a user would use the diskimage-builder devuser element
to achieve this. More detail on this can be located at::

  https://github.com/openstack/diskimage-builder/tree/master/elements/devuser

Example::

  export DIB_DEV_USER_USERNAME=customuser
  export DIB_DEV_USER_PWDLESS_SUDO=yes
  export DIB_DEV_USER_AUTHORIZED_KEYS=$HOME/.ssh/id_rsa.pub
  disk-image-create -o /path/to/custom-ipa debian ironic-agent devuser

************************************
``ssh_public_key_path is not valid``
************************************

Bifrost requires that the user who executes bifrost have an SSH key in
their user home, or that the user defines a variable to tell bifrost where
to identify this file.  Once this variable is defined to a valid file, the
deployment playbook can be re-run.

Generating a new ssh key
========================

See the manual page for the ``ssh-keygen`` command.

Defining a specific public key file
===================================

A user can define a specific public key file by utilizing the
``ssh_public_key_path`` variable.  This can be set in the
``group_vars/inventory/all`` file, or on the ``ansible-playbook`` command
line utilizing the ``-e`` command line parameter.

Example::

  ansible-playbook -i inventory/bifrost_inventory.py deploy-dynamic.yaml -e ssh_public_key_path=~/path/to/public/key/id_rsa.pub

NOTE: The matching private key will need to be utilized to login to the
machine deployed.

***********************************************************
Changing from TinyIPA to CoreOS IPA, or any other IPA Image
***********************************************************

With-in the Newton cycle, the default IPA image for Bifrost was changed
to TinyIPA, which is based on Tiny Core Linux. This has a greatly reduced
boot time for testing, however should be expected to have less hardware
support. If on a fresh install, or a re-install, you wish to change to CoreOS
or any other IPA image, you will need to take the following steps:

#. Remove the existing IPA image ipa.vmlinuz and ipa.initramfs.
#. Edit the ``playbooks/roles/bifrost-ironic-install/defaults/main.yml``
   file and update the ``ipa_kernel_upstream_url`` and
   ``ipa_kernel_upstream_url`` settings to a new URL.
   For CoreOS, these urls would be,
   ``https://tarballs.openstack.org/ironic-python-agent/coreos/files/coreos_production_pxe.vmlinuz``
   and
   ``https://tarballs.openstack.org/ironic-python-agent/coreos/files/coreos_production_pxe_image-oem.cpio.gz``
   respectively.
#. Execute the installation playbook, and the set files will be automatically
   downloaded again. If the files are not removed prior to (re)installation,
   then they will not be replaced. Alternatively, the files can just be
   directly replaced on disk. The default where the kernel and ramdisk are
   located is in ``/httboot/``.
