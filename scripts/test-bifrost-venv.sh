#!/bin/bash

set -eux
set -o pipefail
export PYTHONUNBUFFERED=1

SCRIPT_HOME="$(cd "$(dirname "$0")" && pwd)"
BIFROST_HOME=$SCRIPT_HOME/..
export VENV=/opt/stack/bifrost
# Install Ansible
$SCRIPT_HOME/env-setup.sh

# Source Ansible
# NOTE(TheJulia): Ansible stable-1.9 source method tosses an error deep
# under the hood which -x will detect, so for this step, we need to suspend
# and then re-enable the feature.
set +x +o nounset
source /opt/stack/bifrost/bin/activate
set -x -o nounset

export PATH=${VENV}/bin:${PATH}
echo $(which pip)
echo $(which python)


# Change working directory
cd $BIFROST_HOME/playbooks
echo $(which ansible-playbook)

# Syntax check of dynamic inventory test path
${VENV}/bin/ansible-playbook -vvvv \
       -i inventory/localhost \
       test-bifrost-create-vm.yaml \
       --syntax-check \
       --list-tasks \
       -e enable_venv=true
${VENV}/bin/ansible-playbook -vvvv \
       -i inventory/localhost \
       test-bifrost-dynamic.yaml \
       --syntax-check --list-tasks \
       -e testing_user=cirros \
       -e enable_venv=true

# Create the test VM
${VENV}/bin/ansible-playbook -vvvv \
       -i inventory/localhost \
       test-bifrost-create-vm.yaml \
       -e enable_venv=true
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
${VENV}/bin/ansible-playbook -vvvv \
    -i inventory/bifrost_inventory.py \
    test-bifrost-dynamic.yaml \
    -e use_cirros=true \
    -e testing_user=cirros \
    -e write_interfaces_file=true \
    -e enable_inspector=true \
    -e enable_venv=true
EXITCODE=$?

if [ $EXITCODE != 0 ]; then
    echo "****************************"
    echo "Test failed. See logs folder"
    echo "****************************"
fi

$SCRIPT_HOME/collect-test-info.sh

exit $EXITCODE
