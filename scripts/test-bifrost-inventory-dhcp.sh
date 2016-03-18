#!/bin/bash

# Note(TheJulia): If there is a workspace variable, we want to utilize that as
# the preference of where to put logs
LOG_LOCATION="${WORKSPACE:-..}/logs"

set -eux
set -o pipefail
export PYTHONUNBUFFERED=1

SCRIPT_HOME="$(cd "$(dirname "$0")" && pwd)"
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

# Create the test VMS
ansible-playbook -vvvv -i inventory/localhost test-bifrost-create-vm.yaml -e test_vm_num_nodes="5" -e test_vm_memory_size="1024"

# cut file
head -n -2 /tmp/baremetal.csv > /tmp/baremetal.csv.new && mv /tmp/baremetal.csv.new /tmp/baremetal.csv

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
ansible-playbook -vvvv \
    -i inventory/bifrost_inventory.py \
    test-bifrost-dhcp.yaml \
    -e use_cirros=true \
    -e testing_user=cirros \
    -e inventory_dhcp=true \
    -e inventory_dhcp_static_ip=true \
    -e test_vm_num_nodes="5"
EXITCODE=$?

if [ $EXITCODE != 0 ]; then
    echo "****************************"
    echo "Test failed. See logs folder"
    echo "****************************"
fi

$SCRIPT_HOME/collect-test-info.sh

exit $EXITCODE
