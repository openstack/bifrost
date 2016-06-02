#!/bin/bash

set -eux
set -o pipefail
export PYTHONUNBUFFERED=1
SCRIPT_HOME="$(cd "$(dirname "$0")" && pwd)"
BIFROST_HOME=$SCRIPT_HOME/..
ANSIBLE_INSTALL_ROOT=${ANSIBLE_INSTALL_ROOT:-/opt/stack}
ENABLE_VENV="false"
USE_DHCP="false"
USE_VENV="false"
BUILD_IMAGE="false"

# Set defaults for ansible command-line options to drive the different
# tests.

# NOTE(TheJulia/cinerama): The variables defined on the command line
# for the default and DHCP tests are to drive the use of Cirros as the
# deployed operating system, and as such sets the test user to cirros,
# and writes a debian style interfaces file out to the configuration
# drive as cirros does not support the network_info.json format file
# placed in the configuration drive. The "build image" test does not
# use cirros.

VM_MEMORY_SIZE="3072"
TEST_VM_NUM_NODES=1
USE_CIRROS=true
TESTING_USER=cirros
TEST_PLAYBOOK="test-bifrost-dynamic.yaml"
USE_INSPECTOR=true
INSPECT_NODES=true
INVENTORY_DHCP=false
INVENTORY_DHCP_STATIC_IP=false
DOWNLOAD_IPA=true
CREATE_IPA_IMAGE=false
WRITE_INTERFACES_FILE=true

# NOTE(cinerama): We could remove this if we change the CI job to use
# USE_DHCP, BUILD_IMAGE, etc.
SOURCE=$(basename ${BASH_SOURCE[0]})
if [ $SOURCE = "test-bifrost-inventory-dhcp.sh" ]; then
     USE_DHCP="true"
elif [ $SOURCE = "test-bifrost-venv.sh" ]; then
     USE_VENV="true"
elif [ $SOURCE = "test-bifrost-create-vm.sh" ]; then
     BUILD_IMAGE="true"
fi

# Source Ansible
# NOTE(TheJulia): Ansible stable-1.9 source method tosses an error deep
# under the hood which -x will detect, so for this step, we need to suspend
# and then re-enable the feature.
set +x +o nounset
if [ ${USE_VENV} = "true" ]; then
    export VENV=/opt/stack/bifrost
    export PATH=${VENV}/bin:${PATH}
    $SCRIPT_HOME/env-setup.sh
    source /opt/stack/bifrost/bin/activate
    ANSIBLE=${VENV}/bin/ansible-playbook
    ENABLE_VENV="true"
else
    $SCRIPT_HOME/env-setup.sh
    source ${ANSIBLE_INSTALL_ROOT}/ansible/hacking/env-setup
    ANSIBLE=$(which ansible-playbook)
fi
set -x -o nounset

# Adjust options for DHCP or create VM tests
if [ ${USE_DHCP} = "true" ]; then
    VM_MEMORY_SIZE="1024"
    ENABLE_INSPECTOR=false
    INSPECT_NODES=false
    TEST_PLAYBOOK="test-bifrost-dhcp.yaml"
    TEST_VM_NUM_NODES=5
    INVENTORY_DHCP=true
    INVENTORY_DHCP_STATIC_IP=true
    WRITE_INTERFACES_FILE=false
elif [ ${BUILD_IMAGE} = "true" ]; then
    USE_CIRROS=false
    TESTING_USER=root
    VM_MEMORY_SIZE="4096"
    ENABLE_INSPECTOR=false
    INSPECT_NODES=false
    DOWNLOAD_IPA=false
    CREATE_IPA_IMAGE=true
fi

# Change working directory
cd $BIFROST_HOME/playbooks

# Syntax check of dynamic inventory test path
${ANSIBLE} -vvvv \
       -i inventory/localhost \
       test-bifrost-create-vm.yaml \
       --syntax-check \
       --list-tasks
${ANSIBLE} -vvvv \
       -i inventory/localhost \
       ${TEST_PLAYBOOK} \
       --syntax-check \
       --list-tasks \
       -e testing_user=${TESTING_USER}

# Create the test VM
${ANSIBLE} -vvvv \
       -i inventory/localhost \
       test-bifrost-create-vm.yaml \
       -e test_vm_num_nodes=${TEST_VM_NUM_NODES} \
       -e test_vm_memory_size=${VM_MEMORY_SIZE} \
       -e enable_venv=${ENABLE_VENV}

if [ ${USE_DHCP} = "true" ]; then
    # cut file to limit number of nodes to enroll for testing purposes
    head -n -2 /tmp/baremetal.csv > /tmp/baremetal.csv.new && mv /tmp/baremetal.csv.new /tmp/baremetal.csv
fi

set +e

# Set BIFROST_INVENTORY_SOURCE
export BIFROST_INVENTORY_SOURCE=/tmp/baremetal.csv

# Execute the installation and VM startup test.

${ANSIBLE} -vvvv \
    -i inventory/bifrost_inventory.py \
    ${TEST_PLAYBOOK} \
    -e use_cirros=${USE_CIRROS} \
    -e testing_user=${TESTING_USER} \
    -e test_vm_num_nodes=${TEST_VM_NUM_NODES} \
    -e inventory_dhcp=${INVENTORY_DHCP} \
    -e inventory_dhcp_static_ip=${INVENTORY_DHCP_STATIC_IP} \
    -e enable_venv=${ENABLE_VENV} \
    -e enable_inspector=${USE_INSPECTOR} \
    -e inspect_nodes=${INSPECT_NODES} \
    -e download_ipa=${DOWNLOAD_IPA} \
    -e create_ipa_image=${CREATE_IPA_IMAGE} \
    -e write_interfaces_file=${WRITE_INTERFACES_FILE}
EXITCODE=$?

if [ $EXITCODE != 0 ]; then
    echo "****************************"
    echo "Test failed. See logs folder"
    echo "****************************"
fi

$SCRIPT_HOME/collect-test-info.sh

exit $EXITCODE
