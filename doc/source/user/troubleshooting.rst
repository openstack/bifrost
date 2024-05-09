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
    6385/TCP for the ironic API
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
better hardware support than Tiny Core Linux.

DIB images:
  https://docs.openstack.org/ironic-python-agent-builder/latest/admin/dib.html
TinyIPA:
  https://docs.openstack.org/ironic-python-agent-builder/latest/admin/tinyipa.html

For documentation on diskimage-builder, See::
  https://docs.openstack.org/diskimage-builder/latest/.

It should be noted that the steps for diskimage-builder installation and
use to create an IPA image for Bifrost are the same as for ironic. See:
https://docs.openstack.org/ironic/latest/install/deploy-ramdisk.html

Once your build is completed, you will need to copy the images files into
the ``/var/lib/ironic/httpboot`` folder.

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

    kernel_append_params=nofb nomodeset vga=normal console=ttyS0 systemd.journald.forward_to_console=yes

   Parameters will vary by your hardware type and configuration,
   however the ``systemd.journald.forward_to_console=yes`` setting is
   a default, and will only work for systemd based IPA images.

   The example above, effectively disables all attempts by the kernel to set
   the video mode, defines the console as ttyS0 or the first serial port, and
   instructs systemd to direct logs to the console.

2) Once set, restart the ironic service, e.g.
   ``systemctl restart ironic`` and attempt to redeploy the node.
   You will want to view the system console occurring. If possible, you
   may wish to use ``ipmitool`` and write the output to a log file.

Gaining access via SSH to the node running IPA for custom images
================================================================

Custom built images will require a user to be burned into the image.
Typically a user would use the diskimage-builder ``devuser`` element
to achieve this. More detail on this can be located at
https://docs.openstack.org/diskimage-builder/latest/elements/devuser/README.html.

Example::

  export DIB_DEV_USER_USERNAME=customuser
  export DIB_DEV_USER_PWDLESS_SUDO=yes
  export DIB_DEV_USER_AUTHORIZED_KEYS=$HOME/.ssh/id_rsa.pub
  ironic-python-agent-builder -o /path/to/custom-ipa -e devuser debian

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

******************************************
Changing from TinyIPA to another IPA Image
******************************************

With-in the Newton cycle, the default IPA image for Bifrost was changed
to TinyIPA, which is based on Tiny Core Linux. This has a greatly reduced
boot time for testing, however should be expected to have less hardware
support. In the Yoga cycle, the default image was changed to one based
on CentOS.

If on a fresh install, or a re-install, you wish to change to
DIB-based or any other IPA image, you will need to take the following steps:

#. Remove the existing IPA image ipa.kernel and ipa.initramfs.
#. Edit the ``playbooks/roles/bifrost-ironic-install/defaults/main.yml``
   file and update the ``ipa_kernel_upstream_url`` and
   ``ipa_kernel_upstream_url`` settings to a new URL.
   For DIB-based images, these urls would be,
   ``https://tarballs.opendev.org/openstack/ironic-python-agent/dib/files/ipa-centos9-master.kernel``
   and
   ``https://tarballs.opendev.org/openstack/ironic-python-agent/dib/files/ipa-centos9-master.initramfs``
   respectively.
#. Execute the installation playbook, and the set files will be automatically
   downloaded again. If the files are not removed prior to (re)installation,
   then they will not be replaced. Alternatively, the files can just be
   directly replaced on disk. The default where the kernel and ramdisk are
   located is in ``/httboot/``.
