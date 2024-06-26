#!/bin/bash

set -euxo pipefail

export PYTHONUNBUFFERED=1
SCRIPT_HOME="$(cd "$(dirname "$0")" && pwd)"
BIFROST_HOME=$SCRIPT_HOME/..
USE_DHCP="${USE_DHCP:-false}"
BUILD_IMAGE="${BUILD_IMAGE:-false}"
BAREMETAL_DATA_FILE=${BAREMETAL_DATA_FILE:-'/tmp/baremetal.json'}
ENABLE_KEYSTONE="${ENABLE_KEYSTONE:-false}"
ZUUL_BRANCH=${ZUUL_BRANCH:-}
CLI_TEST=${CLI_TEST:-false}
BOOT_MODE=${BOOT_MODE:-}
ENABLE_GRUB_NETWORK_BOOT=${ENABLE_GRUB_NETWORK_BOOT:-false}
ENABLE_TLS=${ENABLE_TLS:-false}
ENABLE_PROMETHEUS_EXPORTER=${ENABLE_PROMETHEUS_EXPORTER:-false}
USE_VMEDIA=${USE_VMEDIA:-false}

# Set defaults for ansible command-line options to drive the different
# tests.

# NOTE(TheJulia/cinerama): The variables defined on the command line
# for the default and DHCP tests are to drive the use of Cirros as the
# deployed operating system, and as such sets the test user to cirros,
# and writes a debian style interfaces file out to the configuration
# drive as cirros does not support the network_data.json format file
# placed in the configuration drive. The "build image" test does not
# use cirros.

# NOTE(rpittau) we can't use kvm in CI
VM_DOMAIN_TYPE=qemu
export VM_DISK_CACHE="unsafe"
TEST_VM_NUM_NODES=1
DOWNLOAD_CUSTOM_DEPLOY_IMAGE=true
TESTING_USER=cirros
TEST_PLAYBOOK="test-bifrost.yaml"
USE_INSPECTOR=${USE_INSPECTOR:-false}
INSPECT_NODES=true
INVENTORY_DHCP=false
INVENTORY_DHCP_STATIC_IP=false
DOWNLOAD_IPA=true
CREATE_IPA_IMAGE=false
WRITE_INTERFACES_FILE=true
PROVISION_WAIT_TIMEOUT=${PROVISION_WAIT_TIMEOUT:-900}
NOAUTH_MODE=${NOAUTH_MODE:-false}
CLOUD_CONFIG=""
WAIT_FOR_DEPLOY=true
TEST_VM_NODE_DRIVER=${TEST_VM_NODE_DRIVER:-}

# Get OS information
source /etc/os-release || source /usr/lib/os-release
OS_DISTRO="$ID"

# Setup openstack_ci test database if run in OpenStack CI.
if [ "$ZUUL_BRANCH" != "" ]; then
    sudo mkdir -p /opt/libvirt/images
    VM_SETUP_EXTRA="--storage-pool-path /opt/libvirt/images"
fi

if [ -d "${WORKSPACE:-}" ]; then
    BIFROST_CLI_EXTRA="${BIFROST_CLI_EXTRA:-} --extra-vars copy_from_local_path=true"
fi

source $SCRIPT_HOME/env-setup.sh

# We're expected to test with SELinux enforcing
if which setenforce &> /dev/null; then
    SELINUX_STATUS=$(sudo getenforce)
    if [ "$SELINUX_STATUS" == "Disabled" ]; then
        echo "Selinux is Disabled, please enable it and restart the host"
        exit 1
    fi
    sudo setenforce Enforcing
fi

if [ ${DOWNLOAD_CUSTOM_DEPLOY_IMAGE} = "true" ] && [ ! -f "$HOME/.ssh/id_ecdsa.pub" ]; then
    # CentOS/RHEL 9, as well as Fedora, do not work with the RSA key
    # that the Cirros' SSH server uses. Generate an ECDSA key pair instead.
    ssh-keygen -t ECDSA -f "$HOME/.ssh/id_ecdsa" -N ""
fi

# Install lshw to collect info at the end of the test
if which rpm &> /dev/null; then
    sudo dnf install -y lshw
elif which apt &> /dev/null; then
    sudo apt install -y lshw
fi

# Note(cinerama): activate is not compatible with "set -u";
# disable it just for this line.
set +u
source ${VENV}/bin/activate
set -u
ANSIBLE=${VENV}/bin/ansible-playbook
ANSIBLE_PYTHON_INTERP=${VENV}/bin/python3

# Adjust options for DHCP, VM, or Keystone tests
if [ ${USE_DHCP} = "true" ]; then
    INSPECT_NODES=false
    TEST_VM_NUM_NODES=3
    VM_DISK=4
    INVENTORY_DHCP=true
    INVENTORY_DHCP_STATIC_IP=true
    WRITE_INTERFACES_FILE=false
    CLOUD_CONFIG+=" -e dhcp_provider=none"
elif [ ${BUILD_IMAGE} = "true" ]; then
    DOWNLOAD_CUSTOM_DEPLOY_IMAGE=false
    TESTING_USER=root
    VM_MEMORY_SIZE="4096"
    INSPECT_NODES=false
    DOWNLOAD_IPA=false
    CREATE_IPA_IMAGE=true

elif [ ${ENABLE_KEYSTONE} = "true" ]; then
    NOAUTH_MODE=false
    CLOUD_CONFIG+=" -e cloud_name=bifrost"
fi

REDEPLOY_NODES=$DOWNLOAD_CUSTOM_DEPLOY_IMAGE

if [[ -n "$BOOT_MODE" ]]; then
    CLOUD_CONFIG+=" -e default_boot_mode=$BOOT_MODE"
    VM_SETUP_EXTRA+=" -e default_boot_mode=$BOOT_MODE"
fi

if [ ${USE_VMEDIA} = "true" ]; then
    TEST_VM_NODE_DRIVER=redfish
    CLOUD_CONFIG+=" -e default_boot_interface=redfish-virtual-media"
elif [ ${ENABLE_GRUB_NETWORK_BOOT} = "true" ]; then
    CLOUD_CONFIG+=" -e default_boot_interface=pxe"
fi

if [[ -n "$TEST_VM_NODE_DRIVER" ]]; then
    VM_SETUP_EXTRA+=" --driver $TEST_VM_NODE_DRIVER"
    CLOUD_CONFIG+=" -e enabled_hardware_types=$TEST_VM_NODE_DRIVER"
fi

on_exit() {
    $SCRIPT_HOME/collect-test-info.sh
}
trap on_exit EXIT

# Change working directory
cd $BIFROST_HOME/playbooks

# Syntax check of dynamic inventory test path
for task in syntax-check list-tasks; do
    ${ANSIBLE} -vvvv \
           -i inventory/localhost \
           test-bifrost-create-vm.yaml \
           --${task}
    ${ANSIBLE} -vvvv \
           -i inventory/localhost \
           ${TEST_PLAYBOOK} \
           --${task} \
           -e testing_user=${TESTING_USER}
done

# Create the test VMs
../bifrost-cli --debug testenv \
    --count ${TEST_VM_NUM_NODES} \
    --memory ${VM_MEMORY_SIZE:-1024} \
    --disk ${VM_DISK:-5} \
    --inventory "${BAREMETAL_DATA_FILE}" \
    --extra-vars git_url_root="${WORKSPACE:-https://opendev.org}" \
    ${VM_SETUP_EXTRA:-} \
    ${BIFROST_CLI_EXTRA:-}

if [ ${USE_DHCP} = "true" ]; then
    # reduce the number of nodes in JSON file
    # to limit number of nodes to enroll for testing purposes
    python $BIFROST_HOME/scripts/split_json.py 2 \
        ${BAREMETAL_DATA_FILE} \
        ${BAREMETAL_DATA_FILE}.new \
        ${BAREMETAL_DATA_FILE}.rest \
        && mv ${BAREMETAL_DATA_FILE}.new ${BAREMETAL_DATA_FILE}
fi

if [ ${CLI_TEST} = "true" ]; then
    ../bifrost-cli --debug install --testenv \
        --extra-vars git_url_root="${WORKSPACE:-https://opendev.org}" \
        ${BIFROST_CLI_EXTRA:-}
fi

set +e

# Set BIFROST_INVENTORY_SOURCE
export BIFROST_INVENTORY_SOURCE=${BAREMETAL_DATA_FILE}

# Execute the installation and VM startup test.

${ANSIBLE} -vvvv \
    -i inventory/bifrost_inventory.py \
    -i inventory/target \
    ${TEST_PLAYBOOK} \
    -e download_custom_deploy_image=${DOWNLOAD_CUSTOM_DEPLOY_IMAGE} \
    -e use_tinyipa=true \
    -e testing_user=${TESTING_USER} \
    -e test_vm_num_nodes=${TEST_VM_NUM_NODES} \
    -e inventory_dhcp=${INVENTORY_DHCP} \
    -e inventory_dhcp_static_ip=${INVENTORY_DHCP_STATIC_IP} \
    -e enable_inspector=${USE_INSPECTOR} \
    -e inspect_nodes=${INSPECT_NODES} \
    -e redeploy_nodes=${REDEPLOY_NODES} \
    -e download_ipa=${DOWNLOAD_IPA} \
    -e create_ipa_image=${CREATE_IPA_IMAGE} \
    -e write_interfaces_file=${WRITE_INTERFACES_FILE} \
    -e wait_timeout=${PROVISION_WAIT_TIMEOUT} \
    -e noauth_mode=${NOAUTH_MODE} \
    -e enable_keystone=${ENABLE_KEYSTONE} \
    -e wait_for_node_deploy=${WAIT_FOR_DEPLOY} \
    -e not_enrolled_data_file=${BAREMETAL_DATA_FILE}.rest \
    -e enable_tls=${ENABLE_TLS} \
    -e enable_prometheus_exporter=${ENABLE_PROMETHEUS_EXPORTER} \
    -e generate_tls=${ENABLE_TLS} \
    -e skip_install=${CLI_TEST} \
    -e skip_package_install=${CLI_TEST} \
    -e skip_bootstrap=${CLI_TEST} \
    -e skip_start=${CLI_TEST} \
    -e skip_migrations=${CLI_TEST} \
    ${CLOUD_CONFIG}
EXITCODE=$?

if [ $EXITCODE != 0 ]; then
    echo "****************************"
    echo "Test failed. See logs folder"
    echo "****************************"
fi

exit $EXITCODE
