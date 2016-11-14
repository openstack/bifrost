Deploying with libvirt
======================

In order to deploy bifrost with libvirt, but managing baremetal servers, a special
network config needs to be setup.

Two networks need to be created:
- default network, that will be a standard virtual network, using NAT.
- provisioning network, that will be used for PXE boot. As we need to setup
  a dhcp server on bifrost guest, creating a virtual network will give
  conflicts between guest and host. So to avoid it, we can define a
  network that uses macvtap interfaces, associated with the physical
  interface.
  Please note that you will need to have macvlan enabled on your kernel.

When creating the guest, a minimum of 8GB of memory is needed in order to
build disk images properly. Also when defining the interfaces for the guest, the two
networks that have been created need to be attached.

These sample commands will spin up a bifrost vm based on centos:

virsh net-define --file network/default.xml
virsh net-start default
virsh net-define --file network/br_direct.xml
virsh net-start br_direct
virsh define --file vm/baremetal.xml
virsh start baremetal
virsh console baremetal

When you login into baremetal, the interface for the provisioning
network will be down. You may need to add an IP manually:

ip addr add <<provisioning_ip_address>>/<<mask>> dev <<interface>>
ip link set <<interface>> up

Where to get guest images
=========================
In order to create the guest VMs, you will need a cloud image
for the distro you want to deploy. You will need to download the
guest image on a directory on the host, and then in the template
for the VM, you can specify it on the disk section, as shown
in the example template.

Please follow the information on this link to get the images:

http://docs.openstack.org/image-guide/obtain-images.html

Add credentials to guest image
==============================

Normally guest images come without user and password, they rely on ssh to
allow access. In this case, it can be useful to enable ssh access to some
user from host to guest. A way to do that, is creating a config drive
and reference it on the template for the guest VM.

A useful script to generate config drives can be found at:

https://github.com/larsks/virt-utils/blob/master/create-config-drive

Relying on this script, a config drive can be created with:

create-config-drive -k ~/.ssh/id_rsa.pub config.iso

And then this ISO can be referenced on the guest VM template.

