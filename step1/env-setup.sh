#!/bin/bash
sudo apt-get -y install git
mkdir /opt/stack
cd /opt/stack
if [ ! -d ansible ]; then
    git clone git://github.com/ansible/ansible.git --recursive
else
    cd ansible
    git pull --rebase
    git submodule update --init --recursive
fi
echo
echo "source /opt/stack/ansible/hacking/env-setup to proceed"
