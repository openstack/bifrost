#!/bin/bash

set -euo pipefail

. $(dirname $0)/install-deps.sh
# NOTE(pas-ha) the above exports some useful variables like
# $PYTHON , $PIP and $VENV depending on venv install or not
source /etc/os-release
if [[ $ID == "centos" ]] || [[ $VERSION_CODENAME == "bullseye" ]]; then
    DEFAULT_PIP_ANSIBLE='>=8,<9'
elif [[ $ID == "ubuntu" ]] || [[ $VERSION_CODENAME == "bookworm" ]] ; then
    DEFAULT_PIP_ANSIBLE='>=9,<10'
fi

ANSIBLE_COLLECTIONS_REQ=${ANSIBLE_COLLECTIONS_REQ:-$(dirname $0)/../ansible-collections-requirements.yml}
ANSIBLE_COLLECTION_SOURCE_PATH=
if [[ -d "${WORKSPACE:-}/openstack/ansible-collections-openstack" ]]; then
    ANSIBLE_COLLECTION_SOURCE_PATH="${WORKSPACE}/openstack/ansible-collections-openstack"
fi
ANSIBLE_PIP_VERSION=${ANSIBLE_PIP_VERSION:-${DEFAULT_PIP_ANSIBLE}}
ANSIBLE_SOURCE_PATH=${ANSIBLE_SOURCE_PATH:-ansible${ANSIBLE_PIP_VERSION}}

BIFROST_COLLECTIONS_PATHS=${ANSIBLE_COLLECTIONS_PATHS:-}
PLAYBOOKS_LIBRARY_PATH=$(dirname $0)/../playbooks/library

echo "Installing/upgrading Ansible"
ANSIBLE=${VENV}/bin/ansible
if [ -f "$ANSIBLE" ]; then
  ${PIP} uninstall -y ansible
  ${PIP} uninstall -y ansible-base
  ${PIP} uninstall -y ansible-core
fi
${PIP} install "${ANSIBLE_SOURCE_PATH}"

ANSIBLE_GALAXY="${SUDO} ${VENV}/bin/ansible-galaxy"
if [[ -z $BIFROST_COLLECTIONS_PATHS ]]; then
    echo  "Setting ANSIBLE_COLLECTIONS_PATHS to virtualenv"
    export ANSIBLE_COLLECTIONS_PATHS=${VENV}/collections
    BIFROST_COLLECTIONS_PATHS=$ANSIBLE_COLLECTIONS_PATHS
fi
if [[ -n "$ANSIBLE_COLLECTION_SOURCE_PATH" ]]; then
    ${SUDO} mkdir -p "$BIFROST_COLLECTIONS_PATHS/ansible_collections/openstack"
    ${SUDO} ln -s "$ANSIBLE_COLLECTION_SOURCE_PATH" "$BIFROST_COLLECTIONS_PATHS/ansible_collections/openstack/cloud"
fi

# Install Collections
if [[ -n "$ANSIBLE_COLLECTION_SOURCE_PATH" ]]; then
    echo "Using openstack ansible collection from $ANSIBLE_COLLECTION_SOURCE_PATH"
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
