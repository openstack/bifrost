#!/bin/bash

set -eux
set -o pipefail

# Note(TheJulia): If there is a workspace variable, we want to utilize that as
# the preference of where to put logs
SCRIPT_HOME="$(cd "$(dirname "$0")" && pwd)"
LOG_LOCATION="${WORKSPACE:-${SCRIPT_HOME}/..}/logs"

echo "Making logs directory and collecting logs."
[ -d ${LOG_LOCATION} ] || mkdir -p ${LOG_LOCATION}
sudo cp /var/log/libvirt/baremetal_logs/testvm1_console.log ${LOG_LOCATION}
sudo chown $USER ${LOG_LOCATION}/testvm1_console.log
dmesg &> ${LOG_LOCATION}/dmesg.log
if $(netstat --version &>/dev/null); then
    sudo netstat -apn &> ${LOG_LOCATION}/netstat.log
fi
if $(iptables --version &>/dev/null); then
    sudo iptables -L -n -v &> ${LOG_LOCATION}/iptables.log
fi
if $(journalctl --version &>/dev/null); then
    sudo journalctl -u ironic-api &> ${LOG_LOCATION}/ironic-api.log
    sudo journalctl -u ironic-conductor &> ${LOG_LOCATION}/ironic-conductor.log
else
   sudo cp /var/log/upstart/ironic-api.log ${LOG_LOCATION}/
   sudo cp /var/log/upstart/ironic-conductor.log ${LOG_LOCATION}/
fi
sudo chown $USER ${LOG_LOCATION}/ironic-api.log
sudo chown $USER ${LOG_LOCATION}/ironic-conductor.log
