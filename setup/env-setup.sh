#!/bin/bash

sudo apt-get -y install git python-pip
sudo pip install jinja2

u=$(whoami)
g=$(groups | awk '{print $1}')

mkdir -p /opt/stack || (sudo mkdir -p /opt/stack && chown $u:$g /opt/stack)
cd /opt/stack

if [ ! -d ansible ]; then
    git clone git://github.com/ansible/ansible.git --recursive
else
    cd ansible
    git pull --rebase
    git submodule update --init --recursive
fi

echo
echo "Run the following commands to proceed: "
echo
echo "source env-vars"
echo "source /opt/stack/ansible/hacking/env-setup"
echo
