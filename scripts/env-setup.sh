#!/bin/bash
set -eu

. $(dirname $0)/install-deps.sh
# NOTE(pas-ha) the above exports some useful variables like
# $PYTHON , $PIP and $VENV depending on venv install or not

DEFAULT_PIP_ANSIBLE='>=2.9,<2.10'

ANSIBLE_PIP_VERSION=${ANSIBLE_PIP_VERSION:-${DEFAULT_PIP_ANSIBLE}}
ANSIBLE_SOURCE_PATH=${ANSIBLE_SOURCE_PATH:-ansible${ANSIBLE_PIP_VERSION}}
ANSIBLE_COLLECTION_REQ=${ANSIBLE_COLLECTION_REQ:-$(dirname $0)/../ansible-collection-requirements.yml}
BIFROST_COLLECTIONS_PATHS=${ANSIBLE_COLLECTIONS_PATHS:-}

if [ -n "${VENV-}" ]; then
    ${PIP} install "${ANSIBLE_SOURCE_PATH}"
    ANSIBLE=${VENV}/bin/ansible
    ANSIBLE_GALAXY=${VENV}/bin/ansible-galaxy
    if [[ -z $BIFROST_COLLECTIONS_PATHS ]]; then
        echo  "Setting ANSIBLE_COLLECTIONS_PATHS to virtualenv"
        export ANSIBLE_COLLECTIONS_PATHS=${VENV}/collections
        BIFROST_COLLECTIONS_PATHS=$ANSIBLE_COLLECTIONS_PATHS
    fi
else
    ${PIP} install --user --upgrade "${ANSIBLE_SOURCE_PATH}"
    ANSIBLE=${HOME}/.local/bin/ansible
    ANSIBLE_GALAXY=${HOME}/.local/bin/ansible-galaxy
fi

PLAYBOOKS_LIBRARY_PATH=$(dirname $0)/../playbooks/library

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


# Install Collections
if [[ -z $BIFROST_COLLECTIONS_PATHS ]];
then
    echo "Installing ansible collections on default collections path"
    ${ANSIBLE_GALAXY} collection install -r ${ANSIBLE_COLLECTION_REQ}
else
    echo "Installing ansible collections on $BIFROST_COLLECTIONS_PATHS"
    ${ANSIBLE_GALAXY} collection install -r ${ANSIBLE_COLLECTION_REQ} -p ${BIFROST_COLLECTIONS_PATHS}
fi

# Symlink Collections to the playbook directory. This removes the need of setting
# ANSIBLE_COLLECTIONS_PATHS environment variable
if [ ! -e "$(dirname $0)/../playbooks/collections" ]; then
    echo "Creating a symbolic link to ansible collections in bifrost playbook directory"
    ln -s ${ANSIBLE_COLLECTIONS_PATHS} "$(dirname $0)/../playbooks/collections"
fi

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
