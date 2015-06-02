#!/bin/bash
set -eux
set -o pipefail
export PYTHONUNBUFFERED=1

SCRIPT_HOME=$(dirname $0)
BIFROST_HOME=$SCRIPT_HOME/..
# Install Ansible
$SCRIPT_HOME/env-setup.sh

# Source Ansible
# NOTE(TheJulia): Ansible stable-1.9 source method tosses an error deep
# under the hood which -x will detect, so for this step, we need to suspend
# and then re-enable the feature.
set +x
source /opt/stack/ansible/hacking/env-setup
set -x

# Change working directory
cd $BIFROST_HOME/playbooks

# Perform a syntax check
ansible-playbook -vvvv -i inventory/localhost test-bifrost.yaml --syntax-check --list-tasks

set +e

# Execute test playbook
ansible-playbook -vvvv -i inventory/localhost test-bifrost.yaml -e use_cirros=true -e testing_user=cirros
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
