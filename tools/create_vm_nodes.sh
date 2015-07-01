#!/bin/bash
#############################################################################
# create_nodes.sh - Script to create VM nodes for use with Ironic.
#
# PURPOSE
#    This script can be used to create VM instances without an operating
#    system and that are ready for netbooting. They are connected to the
#    bridge named 'brbm' (created if it does not exist).
#
# EXAMPLE USAGE
#    # Use defaults - Create a single node with base name of 'testvm'
#    sudo create_nodes.sh
#
#    # Create 5 nodes
#    sudo NODECOUNT=5 create_nodes.sh
#
#    # Create 3 nodes with base name of 'junk'
#    sudo NODEBASE=junk NODECOUNT=3 create_nodes.sh
#
#    # Write out the csv file
#    sudo OUTFILE=/path/to/file.csv create_nodes.sh
#
# THANKS
#    Thanks to the author(s) of the Ironic supporting code within devstack,
#    from which all of this is derived.
#
# AUTHOR
#    David Shrewsbury (shrewsbury.dave@gmail.com)
#############################################################################


set -e   # exit immediately on command error
set -u   # treat unset variables as error when substituting


LIBVIRT_CONNECT_URI=${LIBVIRT_CONNECT_URI:-"qemu:///system"}
export VIRSH_DEFAULT_CONNECT_URI="$LIBVIRT_CONNECT_URI"

# VM specs
VM_EMULATOR=${VM_EMULATOR:-/usr/bin/qemu-system-x86_64}
VM_CPU=${VM_CPU:-1}
VM_RAM=${VM_RAM:-3072}
VM_DISK=${VM_DISK:-10}

# VM network
VM_NET_BRIDGE=${VM_NET_BRIDGE:-default}

# VM logging directory
VM_LOGDIR=/var/log/libvirt/baremetal_logs

CSV_OUTPUT="CSV entries:"

#############################################################################
# FUNCTION
#   create_node
#
# PARAMETERS
#   $1: Virtual machine name
#   $2: Number of CPUs for the VM
#   $3: Amount of RAM for the VM
#   $4: Disk size (in GB) for the VM
#   $5: CPU architecture (i386 or amd64)
#   $6: Network bridge for the VMs
#   $7: Path to VM emulator
#   $8: Logging directory for the VMs
#############################################################################
function create_node {
    NAME=$1
    CPU=$2
    MEM=$(( 1024 * $3 ))
    # extra G to allow fuzz for partition table : flavor size and registered size
    # need to be different to actual size.
    DISK=$(( $4 + 1))

    case $5 in
        i386) ARCH='i686' ;;
        amd64) ARCH='x86_64' ;;
        *) echo "Unsupported arch $5!" ; exit 1 ;;
    esac

    BRIDGE=$6
    EMULATOR=$7
    LOGDIR=$8

    LIBVIRT_NIC_DRIVER=${LIBVIRT_NIC_DRIVER:-"e1000"}
    LIBVIRT_STORAGE_POOL=${LIBVIRT_STORAGE_POOL:-"default"}
    LIBVIRT_CONNECT_URI=${LIBVIRT_CONNECT_URI:-"qemu:///system"}

    if ! virsh pool-list --all | grep -q $LIBVIRT_STORAGE_POOL; then
        virsh pool-define-as --name $LIBVIRT_STORAGE_POOL dir --target /var/lib/libvirt/images >&2
        virsh pool-autostart $LIBVIRT_STORAGE_POOL >&2
        virsh pool-start $LIBVIRT_STORAGE_POOL >&2
    fi

    pool_state=$(virsh pool-info $LIBVIRT_STORAGE_POOL | grep State | awk '{ print $2 }')
    if [ "$pool_state" != "running" ] ; then
      [ ! -d /var/lib/libvirt/images ] && mkdir /var/lib/libvirt/images
      virsh pool-start $LIBVIRT_STORAGE_POOL >&2
    fi

    if [ -n "$LOGDIR" ] ; then
      mkdir -p "$LOGDIR"
    fi

    PREALLOC=
    if [ -f /etc/debian_version ]; then
        PREALLOC="--prealloc-metadata"
    fi

    VM_LOGGING="$LOGDIR/${NAME}_console.log"
    VOL_NAME="${NAME}.qcow2"

    if ! virsh list --all | grep -q $NAME; then
      virsh vol-list --pool $LIBVIRT_STORAGE_POOL | grep -q $VOL_NAME &&
          virsh vol-delete $VOL_NAME --pool $LIBVIRT_STORAGE_POOL >&2
      virsh vol-create-as $LIBVIRT_STORAGE_POOL ${VOL_NAME} ${DISK}G --format qcow2 $PREALLOC >&2
      volume_path=$(virsh vol-path --pool $LIBVIRT_STORAGE_POOL $VOL_NAME)
      # Pre-touch the VM to set +C, as it can only be set on empty files.
      touch "$volume_path"
      chattr +C "$volume_path" || true

      vm_xml="
<domain type='qemu'>
  <name>${NAME}</name>
  <memory unit='KiB'>${MEM}</memory>
  <vcpu>${CPU}</vcpu>
  <os>
    <type arch='${ARCH}' machine='pc-1.0'>hvm</type>
    <boot dev='network'/>
    <bootmenu enable='no'/>
    <bios useserial='yes'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>${EMULATOR}</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='writeback'/>
      <source file='${volume_path}'/>
      <target dev='vda' bus='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
    </disk>
    <controller type='ide' index='0'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x1'/>
    </controller>
    <interface type='network'>
      <source network='${BRIDGE}'/>
    </interface>
    <input type='mouse' bus='ps2'/>
    <graphics type='vnc' port='-1' autoport='yes'/>
    <video>
      <model type='cirrus' vram='9216' heads='1'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </video>
    <serial type='file'>
      <source path='${VM_LOGGING}'/>
      <target port='0'/>
      <alias name='serial0'/>
    </serial>
    <serial type='pty'>
      <source path='/dev/pts/49'/>
      <target port='1'/>
      <alias name='serial1'/>
    </serial>
    <console type='file'>
      <source path='${VM_LOGGING}'/>
      <target type='serial' port='0'/>
      <alias name='serial0'/>
    </console>
    <memballoon model='virtio'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x0'/>
    </memballoon>
  </devices>
</domain>
"

      echo ${vm_xml} > /tmp/vm.xml
      virsh create /tmp/vm.xml 2>&1 >/dev/null
      if [ $? != 0 ]
      then
         echo "failed to create VM $NAME"
         rm -f /tmp/vm.xml
         exit 1
      fi
      rm -f /tmp/vm.xml

    fi

    # echo mac
    local macaddr=`virsh dumpxml $NAME | grep "mac address" | head -1 | cut -d\' -f2`

    echo $macaddr
}


####################
# Main script code
####################

NODEBASE=${NODEBASE:-testvm}
NODECOUNT=${NODECOUNT:-1}

# must be root
user=`whoami`
if [ "$user" != "root" ]
then
    echo "Must be run as root. You are $user."
    exit 1
fi

CSV_LINES=()
IFS=$'\n'
for (( i=1; i<=${NODECOUNT}; i++ ))
do
    name=${NODEBASE}${i}
    mac=$(create_node $name $VM_CPU $VM_RAM $VM_DISK amd64 $VM_NET_BRIDGE $VM_EMULATOR $VM_LOGDIR)

    CSV_LINES+=("$mac,root,undefined,192.168.122.1,$VM_CPU,$VM_RAM,$VM_DISK,flavor,type,a8cb6624-0d9f-c882-affc-046ebb96ec0${i},$name,192.168.122.$((i+1)),,,,agent_ssh")
done

echo ${CSV_OUTPUT}
echo -e "${CSV_LINES[*]}"

if [ $OUTFILE ]; then
    echo -e "${CSV_LINES[*]}" > $OUTFILE
fi
