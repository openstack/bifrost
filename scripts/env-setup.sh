#!/bin/bash
set -e

if [ -x '/usr/bin/apt-get' ]; then
    if ! $(git --version &>/dev/null) ; then
        sudo -H apt-get -y install git
    fi
    if ! $(pip -v &>/dev/null); then
        sudo -H apt-get -y install python-pip
    fi
elif [ -x '/usr/bin/yum' ]; then
    if ! $(git --version &>/dev/null); then
        sudo -H yum -y install git
    fi
    if ! $(pip -v &>/dev/null); then
        sudo -H yum -y install python-pip
    fi
else
    echo "ERROR: Supported package manager not found.  Supported: apt,yum"
fi

sudo -E pip install -r "$(dirname $0)/../requirements.txt"

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
    git checkout devel
    git pull --rebase
    git submodule update --init --recursive
    git fetch

fi

echo
echo "If your using this script directly, execute the"
echo "following commands to update your shell."
echo
echo "source env-vars"
echo "source /opt/stack/ansible/hacking/env-setup"
echo
