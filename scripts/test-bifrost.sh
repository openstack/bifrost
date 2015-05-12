#!/bin/bash
set -eux
set -o pipefail
export PYTHONUNBUFFERED=1

SCRIPT_HOME=$(dirname $0)
BIFROST_HOME=$SCRIPT_HOME/..
# Install Ansible
$SCRIPT_HOME/env-setup.sh

# Source Ansible
source /opt/stack/ansible/hacking/env-setup

# Change working directory
cd $BIFROST_HOME/playbooks

# Perform a syntax check
ansible-playbook -vvvv -i inventory/localhost test-bifrost.yaml --syntax-check --list-tasks

set +e

# Execute test playbook
ansible-playbook -vvvv -i inventory/localhost test-bifrost.yaml
EXITCODE=$?
if [ $EXITCODE != 0 ]; then
    echo "*************************"
    echo "Test failed. Test VM log:"
    sudo cat /var/log/libvirt/baremetal_logs/testvm1_console.log
    echo "*************************"
    echo "Kernel log:"
    sudo dmesg
    echo "*************************"
    echo "Network Sockets in LISTEN state:"
    sudo netstat -apn|grep LISTEN
    echo "*************************"
    echo "Firewalling settings:"
    sudo iptables -L -n -v
    echo "*************************"
    echo "Ironic API log, last 1000 lines:"
    sudo cat /var/log/upstart/ironic-api.log
    echo "*************************"
    echo "Ironic Conductor log, last 1000 lines:"
    sudo cat /var/log/upstart/ironic-conductor.log
fi
exit $EXITCODE
