#!/bin/bash

sudo -H apt-get -y install git python-pip
sudo -H pip install jinja2

u=$(whoami)
g=$(groups | awk '{print $1}')

if [ ! -d /opt/stack ]; then
    mkdir -p /opt/stack || (sudo mkdir -p /opt/stack)
fi
sudo -H chown -R $u:$g /opt/stack
cd /opt/stack

if [ ! -d ansible ]; then
    git clone https://github.com/ansible/ansible.git --recursive
else
    cd ansible
    git checkout stable-1.9
    #git pull --rebase
    git submodule update --init --recursive
    git fetch

fi

echo
echo "Run the following commands to proceed: "
echo
echo "source env-vars"
echo "source /opt/stack/ansible/hacking/env-setup"
echo
