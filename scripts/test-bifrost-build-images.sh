#!/bin/bash

# Note(TheJulia): If there is a workspace variable, we want to utilize that as
# the preference of where to put logs
LOG_LOCATION=${WORKSPACE:-../logs}

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

# Syntax check of dynamic inventory test path
ansible-playbook -vvvv -i inventory/localhost test-bifrost-create-vm.yaml --syntax-check --list-tasks
ansible-playbook -vvvv -i inventory/localhost test-bifrost-dynamic.yaml --syntax-check --list-tasks

# Create the test VM
ansible-playbook -vvvv -i inventory/localhost test-bifrost-create-vm.yaml

set +e

# Set BIFROST_INVENTORY_SOURCE
export BIFROST_INVENTORY_SOURCE=/tmp/baremetal.csv

# Execute the installation and VM startup test.
# NOTE(TheJulia): The variables defined on the command line are to
# drive the use of Cirros as the deployed operating system, and
# as such sets the test user to cirros, and writes a debian style
# interfaces file out to the configuration drive as cirros does
# not support the network_info.json format file placed in the
# configuration drive.
ansible-playbook -vvvv -i inventory/bifrost_inventory.py \
    test-bifrost-dynamic.yaml \
    -e testing_user=root \
    -e download_ipa=false \
    -e create_ipa_image=true
EXITCODE=$?

if [ $EXITCODE != 0 ]; then
    echo "****************************"
    echo "Test failed. See logs folder"
    echo "****************************"
fi
echo "Making logs directory and collecting logs."
mkdir ${LOG_LOCATION}
sudo cp /var/log/libvirt/baremetal_logs/testvm1_console.log ${LOG_LOCATION}/
sudo chown $USER ${LOG_LOCATION}/testvm1_console.log
dmesg &> ${LOG_LOCATION}/dmesg.log
sudo netstat -apn &> ${LOG_LOCATION}/netstat.log
sudo iptables -L -n -v &> ${LOG_LOCATION}/iptables.log
sudo cp /var/log/upstart/ironic-api.log .${LOG_LOCATION}/
sudo chown $USER ${LOG_LOCATION}/ironic-api.log
sudo cp /var/log/upstart/ironic-conductor.log ${LOG_LOCATION}/
sudo chown $USER ${LOG_LOCATION}/ironic-conductor.log
exit $EXITCODE
