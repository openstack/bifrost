#!/bin/bash

# Note(TheJulia): We should proceed with attempting to collect information
# even if a command fails, and as such set -e should not be present.
set -ux
set -o pipefail

# Note(TheJulia): If there is a workspace variable, we want to utilize that as
# the preference of where to put logs
SCRIPT_HOME="$(cd "$(dirname "$0")" && pwd)"
LOG_LOCATION="${WORKSPACE:-${SCRIPT_HOME}/..}/logs"

echo "Making logs directory and collecting logs."
[ -d ${LOG_LOCATION} ] || mkdir -p ${LOG_LOCATION}

if [ -z "${TEST_VM_NODE_NAMES+x}" ]; then
    sudo sh -c "cp /var/log/libvirt/baremetal_logs/testvm[[:digit:]]_console.log ${LOG_LOCATION}"
    sudo chown $USER ${LOG_LOCATION}/testvm[[:digit:]]_console.log
    sudo chmod o+r ${LOG_LOCATION}/testvm[[:digit:]]_console.log
else
    for TEST_VM_NODE_NAME in ${TEST_VM_NODE_NAMES}; do
        sudo cp /var/log/libvirt/baremetal_logs/${TEST_VM_NODE_NAME}_console.log ${LOG_LOCATION}
        sudo chown $USER ${LOG_LOCATION}/${TEST_VM_NODE_NAME}_console.log
        sudo chmod o+r ${LOG_LOCATION}/${TEST_VM_NODE_NAME}_console.log
    done
fi
dmesg &> ${LOG_LOCATION}/dmesg.log
# NOTE(TheJulia): Netstat exits with error code 5 when --version is used.
sudo netstat -apn &> ${LOG_LOCATION}/netstat.log
if $(iptables --version &>/dev/null); then
    sudo iptables -L -n -v &> ${LOG_LOCATION}/iptables.log
fi
if $(ip link &>/dev/null); then
    ip -s link &> ${LOG_LOCATION}/interface_counters.log
fi
if $(journalctl --version &>/dev/null); then
    cp -a /var/log/* ${LOG_LOCATION}/.
    sudo journalctl -u libvirtd &> ${LOG_LOCATION}/libvirtd.log
    sudo journalctl -u ironic-api &> ${LOG_LOCATION}/ironic-api.log
    sudo journalctl -u ironic-conductor &> ${LOG_LOCATION}/ironic-conductor.log
    sudo journalctl -u ironic-inspector &> ${LOG_LOCATION}/ironic-inspector.log
    sudo journalctl -u libvirtd &> ${LOG_LOCATION}/libvirtd.log
else
   sudo cp /var/log/upstart/ironic-api.log ${LOG_LOCATION}/
   sudo cp /var/log/upstart/ironic-conductor.log ${LOG_LOCATION}/
   sudo cp /var/log/upstart/ironic-inspector.log ${LOG_LOCATION}/
   sudo cp /var/log/upstart/libvirtd.log ${LOG_LOCATION}/
fi

# Copy PXE information
mkdir -p ${LOG_LOCATION}/pxe/
cp /httpboot/ipxe.pxe ${LOG_LOCATION}/pxe/
cp -aL /httpboot/pxelinux.cfg/ ${LOG_LOCATION}/pxe/

# Copy baremetal information
source $HOME/openrc
for vm in $(openstack baremetal node list -c Name -f value); do
    openstack baremetal node show $vm >> ${LOG_LOCATION}/baremetal.txt
done

if [ -d "/var/log/ironic" ]; then
   sudo cp -a "/var/log/ironic" ${LOG_LOCATION}/ipa-logs
   ls -la ${LOG_LOCATION}/ipa-logs 
fi

sudo vbmc list &> ${LOG_LOCATION}/vbmc.txt
sudo virsh list --all &> ${LOG_LOCATION}/virsh-list.txt
ps auxf &> ${LOG_LOCATION}/ps.txt

sudo chown -R $USER ${LOG_LOCATION}
# In CI scenarios, we want other users to be able to read the logs.
sudo chmod -R o+r ${LOG_LOCATION}

exit 0
