#!/bin/bash
set -eu

. $(dirname $0)/install-deps.sh
# NOTE(pas-ha) the above exports some useful variables like
# $PYTHON , $PIP and $VENV depending on venv install or not

DEFAULT_PIP_ANSIBLE='>=2.9,<2.11'

ANSIBLE_COLLECTIONS_REQ=${ANSIBLE_COLLECTIONS_REQ:-$(dirname $0)/../ansible-collections-requirements.yml}
ANSIBLE_COLLECTION_SOURCE_PATH=
if [[ -d "${WORKSPACE:-}/openstack/ansible-collections-openstack" ]]; then
    ANSIBLE_COLLECTION_SOURCE_PATH="${WORKSPACE}/openstack/ansible-collections-openstack"
fi
ANSIBLE_INSTALL_ROOT=${ANSIBLE_INSTALL_ROOT:-/opt/stack}
ANSIBLE_PIP_VERSION=${ANSIBLE_PIP_VERSION:-${DEFAULT_PIP_ANSIBLE}}
ANSIBLE_SOURCE_PATH=${ANSIBLE_SOURCE_PATH:-ansible${ANSIBLE_PIP_VERSION}}

BIFROST_COLLECTIONS_PATHS=${ANSIBLE_COLLECTIONS_PATHS:-}
PLAYBOOKS_LIBRARY_PATH=$(dirname $0)/../playbooks/library

echo "Installing/upgrading Ansible"
${PIP} install "${ANSIBLE_SOURCE_PATH}"
ANSIBLE=${VENV}/bin/ansible
ANSIBLE_GALAXY=${VENV}/bin/ansible-galaxy
if [[ -z $BIFROST_COLLECTIONS_PATHS ]]; then
    echo  "Setting ANSIBLE_COLLECTIONS_PATHS to virtualenv"
    export ANSIBLE_COLLECTIONS_PATHS=${VENV}/collections
    BIFROST_COLLECTIONS_PATHS=$ANSIBLE_COLLECTIONS_PATHS
fi
if [[ -n "$ANSIBLE_COLLECTION_SOURCE_PATH" ]]; then
    mkdir -p "$BIFROST_COLLECTIONS_PATHS/ansible_collections/openstack"
    ln -s "$ANSIBLE_COLLECTION_SOURCE_PATH" "$BIFROST_COLLECTIONS_PATHS/ansible_collections/openstack/cloud"
fi

# NOTE(pas-ha) the following is a temporary workaround for third-party CI
# scripts that try to source Ansible's hacking/env-setup
# after running this very script
# TODO(pas-ha) remove after deprecation (in Pike?) and when third-party CIs
# (in particular OPNFV) are fixed
ANSIBLE_USER=$(id -nu)
ANSIBLE_GROUP=$(id -ng)
if [[ ! -d ${ANSIBLE_INSTALL_ROOT} ]]; then
    mkdir -p ${ANSIBLE_INSTALL_ROOT} || (sudo mkdir -p ${ANSIBLE_INSTALL_ROOT})
fi
sudo -H chown -R ${ANSIBLE_USER}:${ANSIBLE_GROUP} ${ANSIBLE_INSTALL_ROOT}

# Install Collections
if [[ -n "$ANSIBLE_COLLECTION_SOURCE_PATH" ]]; then
    echo "Using openstack ansible collection from $ANSIBLE_COLLECTION_SOURCE_PATH"
elif [[ -z $BIFROST_COLLECTIONS_PATHS ]]; then
    echo "Installing ansible collections on default collections path"
    ${ANSIBLE_GALAXY} collection install -r ${ANSIBLE_COLLECTIONS_REQ}
else
    echo "Installing ansible collections on $BIFROST_COLLECTIONS_PATHS"
    ${ANSIBLE_GALAXY} collection install -r ${ANSIBLE_COLLECTIONS_REQ} -p ${BIFROST_COLLECTIONS_PATHS}
fi

# Symlink Collections to the playbook directory. This removes the need of setting
# ANSIBLE_COLLECTIONS_PATHS environment variable
if [ ! -e "$(dirname $0)/../playbooks/collections" ]; then
    echo "Creating a symbolic link to ansible collections in bifrost playbook directory"
    ln -s ${ANSIBLE_COLLECTIONS_PATHS} "$(dirname $0)/../playbooks/collections"
fi

if [[ "${BIFROST_HIDE_PROMPT:-false}" != true ]]; then
    echo
    echo "To use bifrost, do"
    echo "source ${VENV}/bin/activate"
    echo "Then run playbooks as normal."
    echo
fi
