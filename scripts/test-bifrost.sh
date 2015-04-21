#!/bin/bash
set -eux
set -o pipefail

SCRIPT_HOME=$(dirname $0)
BIFROST_HOME=$SCRIPT_HOME/..
# Install Ansible
$SCRIPT_HOME/env-setup.sh

# Source Ansible
source /opt/stack/ansible/hacking/env-setup

# Change working directory
cd $BIFROST_HOME/playbooks

# Perform a syntax check
ansible-playbook -vvvv -i inventory/localhost test-bifrost.yaml --syntax-check --list-tasks

# Execute test playbook
ansible-playbook -vvvv -i inventory/localhost test-bifrost.yaml
