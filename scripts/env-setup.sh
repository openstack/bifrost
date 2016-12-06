#!/bin/bash
set -eu

ANSIBLE_FROM_PYPI=${ANSIBLE_FROM_PYPI:-"False"}

source $(dirname $0)/install-deps.sh

if [[ "$ANSIBLE_FROM_PYPI" == "True" ]]; then
    source $(dirname $0)/install-ansible-pip.sh
else
    source $(dirname $0)/install-ansible-source.sh
fi
