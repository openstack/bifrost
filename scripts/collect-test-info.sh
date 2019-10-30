#!/bin/bash

# Note(TheJulia): We should proceed with attempting to collect information
# even if a command fails, and as such set -e should not be present.
set -ux
set -o pipefail

# Note(TheJulia): If there is a workspace variable, we want to utilize that as
# the preference of where to put logs
SCRIPT_HOME="$(cd "$(dirname "$0")" && pwd)"
LOG_LOCATION="${LOG_LOCATION:-${SCRIPT_HOME}/../logs}"

VERBOSE_LOGS="${VERBOSE_LOGS:-False}"

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
if $(sudo iptables --version &>/dev/null); then
    iptables_dir="${LOG_LOCATION}/iptables"
    mkdir ${iptables_dir}
    sudo iptables -S &> ${iptables_dir}/iptables_all_saved_rules.txt
    if [[ "$VERBOSE_LOGS" == "True" ]]; then
        for table in filter raw security mangle nat; do
            sudo iptables -L -v -n -t ${table} &> ${iptables_dir}/iptables_${table}.log
        done
    fi
fi
if $(ip link &>/dev/null); then
    ip -s link &> ${LOG_LOCATION}/interface_counters.log
fi

mkdir -p ${LOG_LOCATION}/all
sudo cp -a /var/log/* ${LOG_LOCATION}/all/.
sudo chown -R $USER ${LOG_LOCATION}/all

if $(journalctl --version &>/dev/null); then
    sudo journalctl -u libvirtd &> ${LOG_LOCATION}/libvirtd.log
    sudo journalctl -u ironic-api &> ${LOG_LOCATION}/ironic-api.log
    sudo journalctl -u ironic-conductor &> ${LOG_LOCATION}/ironic-conductor.log
    sudo journalctl -u ironic-inspector &> ${LOG_LOCATION}/ironic-inspector.log
    sudo journalctl -u dnsmasq &> ${LOG_LOCATION}/dnsmasq.log
else
   sudo cp /var/log/upstart/ironic-api.log ${LOG_LOCATION}/
   sudo cp /var/log/upstart/ironic-conductor.log ${LOG_LOCATION}/
   sudo cp /var/log/upstart/ironic-inspector.log ${LOG_LOCATION}/
   sudo cp /var/log/upstart/libvirtd.log ${LOG_LOCATION}/
fi

# Copy PXE information
mkdir -p ${LOG_LOCATION}/pxe/
cp /httpboot/ipxe.* ${LOG_LOCATION}/pxe/
cp -aL /httpboot/pxelinux.cfg/ ${LOG_LOCATION}/pxe/

# Copy baremetal information
source $HOME/openrc bifrost
for vm in $(openstack baremetal node list -c Name -f value); do
    openstack baremetal node show $vm >> ${LOG_LOCATION}/baremetal.txt
done

if [ -d "/var/log/ironic" ]; then
   sudo cp -a "/var/log/ironic" ${LOG_LOCATION}/ipa-logs
   ls -la ${LOG_LOCATION}/ipa-logs
fi

sudo vbmc list &> ${LOG_LOCATION}/vbmc.txt
sudo virsh list --all &> ${LOG_LOCATION}/virsh-list.txt
TEST_VM=$(sudo virsh list --all --name | head -1)
sudo virsh dumpxml ${TEST_VM} > ${LOG_LOCATION}/${TEST_VM}_dump.xml
ps auxf &> ${LOG_LOCATION}/ps.txt

sudo chown -R $USER ${LOG_LOCATION}
# In CI scenarios, we want other users to be able to read the logs.
sudo chmod -R o+r ${LOG_LOCATION}

exit 0
