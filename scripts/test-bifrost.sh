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

# Syntax check of dynamic inventory test path
ansible-playbook -vvvv -i inventory/localhost test-bifrost-create-vm.yaml --syntax-check --list-tasks
ansible-playbook -vvvv -i inventory/localhost test-bifrost-dynamic.yaml --syntax-check --list-tasks

set +e

# Create the test VM
ansible-playbook -vvvv -i inventory/localhost test-bifrost-create-vm.yaml

# Set BIFROST_INVENTORY_SOURCE
export BIFROST_INVENTORY_SOURCE=/tmp/baremetal.csv

# Execute the installation and VM startup test.
ansible-playbook -vvvv -i inventory/bifrost_inventory.py test-bifrost-dynamic.yaml -e use_cirros=true -e testing_user=cirros
EXITCODE=$?
if [ $EXITCODE != 0 ]; then
    echo "****************************"
    echo "Test failed. See logs folder"
    echo "****************************"
fi
echo "Making logs directory and collecting logs."
mkdir ../logs
sudo cp /var/log/libvirt/baremetal_logs/testvm1_console.log ../logs/
sudo chown $USER ../logs/testvm1_console.log
dmesg &> ../logs/dmesg.log
sudo netstat -apn &> ../logs/netstat.log
sudo iptables -L -n -v &> ../logs/iptables.log
sudo cp /var/log/upstart/ironic-api.log ../logs/
sudo chown $USER ../logs/ironic-api.log
sudo cp /var/log/upstart/ironic-conductor.log ../logs/
sudo chown $USER ../logs/ironic-conductor.log
exit $EXITCODE
