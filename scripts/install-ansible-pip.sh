#!/bin/bash
set -eu

ANSIBLE_PIP_VERSION=${ANSIBLE_PIP_VERSION:-"2.2"}
sudo -H -E ${PIP} install "ansible==$ANSIBLE_PIP_VERSION"

echo
echo "To use bifrost, do"

if [ -n "${VENV-}" ]; then
    echo "source ${VENV}/bin/activate"
fi
echo "source env-vars"
echo "Then run playbooks as normal."
echo
