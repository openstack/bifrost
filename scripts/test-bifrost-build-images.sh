#!/bin/bash

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

# Create the test VM
ansible-playbook -vvvv -i inventory/localhost test-bifrost-create-vm.yaml \
    -e test_vm_memory_size="4096"

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
    -e create_ipa_image=true \
    -e inspect_nodes=true \
    -e enable_inspector=true
EXITCODE=$?

if [ $EXITCODE != 0 ]; then
    echo "****************************"
    echo "Test failed. See logs folder"
    echo "****************************"
fi

$SCRIPT_HOME/collect-test-info.sh

exit $EXITCODE
