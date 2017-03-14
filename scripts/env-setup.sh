#!/bin/bash
set -eu

source $(dirname $0)/install-deps.sh
# NOTE(pas-ha) the above exports some useful variables like
# $PYTHON , $PIP and $VENV depending on venv install or not

ANSIBLE_PIP_VERSION=${ANSIBLE_PIP_VERSION:-${ANSIBLE_GIT_BRANCH:-stable-2.1}}

ANSIBLE_PIP_STRING=$(${PYTHON} $(dirname $0)/ansible-pip-str.py ${ANSIBLE_PIP_VERSION})

if [ -n "${VENV-}" ]; then
    sudo -H -E ${PIP} install --upgrade "${ANSIBLE_PIP_STRING}"
    ANSIBLE=${VENV}/bin/ansible
else
    ${PIP} install --user --upgrade "${ANSIBLE_PIP_STRING}"
    ANSIBLE=${HOME}/.local/bin/ansible
fi

PLAYBOOKS_LIBRARY_PATH=$(dirname $0)/../playbooks/library

function check_get_module () {
    local module=${1}
    local module_url_base=${2}
    ${ANSIBLE} localhost -m ${module} | grep "changed" || \
        wget "${module_url_base}/${module}.py" -O "${PLAYBOOKS_LIBRARY_PATH}/${module}.py"
}

# Note(TheJulia): These files should be in the ansible library folder
# and this functionality exists for a level of ansible 1.9.x
# backwards compatability although the modules were developed
# for Ansible 2.0.
check_get_module os_ironic \
    https://raw.githubusercontent.com/ansible/ansible-modules-core/stable-2.0/cloud/openstack

check_get_module os_ironic_node \
    https://raw.githubusercontent.com/ansible/ansible-modules-core/stable-2.0/cloud/openstack

# os_ironic_inspect has appeared in Ansible 2.1
check_get_module os_ironic_inspect \
    https://raw.githubusercontent.com/ansible/ansible-modules-extras/stable-2.1/cloud/openstack

# os_keystone_service has appeared in Ansible 2.2
check_get_module os_keystone_service \
    https://raw.githubusercontent.com/ansible/ansible-modules-extras/stable-2.2/cloud/openstack

# NOTE(pas-ha) the following is a temporary workaround for third-party CI
# scripts that try to source Ansible's hacking/env-setup
# after running this very script
# TODO(pas-ha) remove after deprecation (in Pike?) and when third-party CIs
# (in particular OPNFV) are fixed
ANSIBLE_INSTALL_ROOT=${ANSIBLE_INSTALL_ROOT:-/opt/stack}
u=$(whoami)
g=$(groups | awk '{print $1}')
if [ ! -d ${ANSIBLE_INSTALL_ROOT} ]; then
    mkdir -p ${ANSIBLE_INSTALL_ROOT} || (sudo mkdir -p ${ANSIBLE_INSTALL_ROOT})
fi
sudo -H chown -R $u:$g ${ANSIBLE_INSTALL_ROOT}
mkdir -p ${ANSIBLE_INSTALL_ROOT}/ansible/hacking
echo "echo Sourcing this file is no longer needed! Ansible is always installed from PyPI" > ${ANSIBLE_INSTALL_ROOT}/ansible/hacking/env-setup

echo
echo "To use bifrost, do"

if [ -n "${VENV-}" ]; then
    echo "source ${VENV}/bin/activate"
else
    echo "Prepend ~/.local/bin to your PATH if it is not that way already.."
    echo ".. or use full path to local Ansible at ~/.local/bin/ansible-playbook"
fi
echo "source env-vars"
echo "Then run playbooks as normal."
echo
