#!/bin/bash
set -eu

ANSIBLE_GIT_URL=${ANSIBLE_GIT_URL:-https://github.com/ansible/ansible.git}
ANSIBLE_GIT_BRANCH=${ANSIBLE_GIT_BRANCH:-stable-2.1}
ANSIBLE_INSTALL_ROOT=${ANSIBLE_INSTALL_ROOT:-/opt/stack}

function check_get_module () {
    local file=${1}
    local url=${2}
    if [ ! -e ${file} ]; then
        wget -O ${file} ${url}
    fi
}

u=$(whoami)
g=$(groups | awk '{print $1}')

if [ ! -d ${ANSIBLE_INSTALL_ROOT} ]; then
    mkdir -p ${ANSIBLE_INSTALL_ROOT} || (sudo mkdir -p ${ANSIBLE_INSTALL_ROOT})
fi
sudo -H chown -R $u:$g ${ANSIBLE_INSTALL_ROOT}
cd ${ANSIBLE_INSTALL_ROOT}

if [ ! -d ansible ]; then
    git clone $ANSIBLE_GIT_URL --recursive -b $ANSIBLE_GIT_BRANCH
    cd ansible
else
    cd ansible
    git remote update origin --prune
    git fetch --tags
    git checkout $ANSIBLE_GIT_BRANCH
    git pull --rebase origin $ANSIBLE_GIT_BRANCH
    git submodule update --init --recursive
    git fetch
fi
# Note(TheJulia): These files should be in the ansible folder
# and this functionality exists for a level of ansible 1.9.x
# backwards compatability although the modules were developed
# for Ansible 2.0.

check_get_module `pwd`/lib/ansible/modules/core/cloud/openstack/os_ironic.py \
    https://raw.githubusercontent.com/ansible/ansible-modules-core/stable-2.0/cloud/openstack/os_ironic.py
check_get_module `pwd`/lib/ansible/modules/core/cloud/openstack/os_ironic_node.py \
    https://raw.githubusercontent.com/ansible/ansible-modules-core/stable-2.0/cloud/openstack/os_ironic_node.py

# os_ironic_inspect has appeared in Ansible 2.1
check_get_module `pwd`/lib/ansible/modules/extras/cloud/openstack/os_ironic_inspect.py \
    https://raw.githubusercontent.com/ansible/ansible-modules-extras/stable-2.1/cloud/os_ironic_inspect.py

# os_keystone_service has appeared in Ansible 2.2
check_get_module `pwd`/lib/ansible/modules/extras/cloud/openstack/os_keystone_service.py \
    https://raw.githubusercontent.com/ansible/ansible-modules-extras/stable-2.2/cloud/openstack/os_keystone_service.py

if [ -n "${VENV-}" ]; then
    sudo -H -E ${PIP} install --upgrade ${ANSIBLE_INSTALL_ROOT}/ansible
    echo
    echo "To use bifrost, do"

    echo "source ${VENV}/bin/activate"
    echo "source env-vars"
    echo "Then run playbooks as normal."
    echo
else
    echo
    echo "If you're using this script directly, execute the"
    echo "following commands to update your shell."
    echo
    echo "source env-vars"
    echo "source ${ANSIBLE_INSTALL_ROOT}/ansible/hacking/env-setup"
    echo
fi

