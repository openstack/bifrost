#!/bin/bash
set -eu

. $(dirname $0)/install-deps.sh
# NOTE(pas-ha) the above exports some useful variables like
# $PYTHON , $PIP and $VENV depending on venv install or not

DEFAULT_PIP_ANSIBLE='>=2.9,<2.10'

ANSIBLE_PIP_VERSION=${ANSIBLE_PIP_VERSION:-${DEFAULT_PIP_ANSIBLE}}
ANSIBLE_SOURCE_PATH=${ANSIBLE_SOURCE_PATH:-ansible${ANSIBLE_PIP_VERSION}}

if [ -n "${VENV-}" ]; then
    ${PIP} install "${ANSIBLE_SOURCE_PATH}"
    ANSIBLE=${VENV}/bin/ansible
else
    ${PIP} install --user --upgrade "${ANSIBLE_SOURCE_PATH}"
    ANSIBLE=${HOME}/.local/bin/ansible
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
