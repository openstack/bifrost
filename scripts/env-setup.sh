#!/bin/bash
set -e

ANSIBLE_GIT_URL=${ANSIBLE_GIT_URL:-https://github.com/ansible/ansible.git}
# NOTE(TheJulia): Switching to Ansible stable-1.9 branch as the development
# branch is undergoing some massive changes and we are seeing odd failures
# that we should not be seeing.  Until devel has stabilized, we should stay
# on the stable branch.
ANSIBLE_GIT_BRANCH=${ANSIBLE_GIT_BRANCH:-stable-1.9}

if [ -x '/usr/bin/apt-get' ]; then
    if ! $(gcc -v &>/dev/null); then
        sudo -H apt-get -y install gcc
    fi
    if ! $(git --version &>/dev/null) ; then
        sudo -H apt-get -y install git
    fi
    if ! $(dpkg -l libpython-dev &>/dev/null); then
        sudo -H apt-get -y install libpython-dev
    fi
    if ! $(dpkg -l wget &>/dev/null); then
        sudo -H apt-get -y install wget
    fi
elif [ -x '/usr/bin/yum' ]; then
    if ! yum -q list installed python-devel; then
        sudo -H yum -y install python-devel
    fi
    if ! $(gcc -v &>/dev/null); then
        sudo -H yum -y install gcc
    fi
    if ! $(git --version &>/dev/null); then
        sudo -H yum -y install git
    fi
    if ! $(wget --version &>/dev/null); then
        sudo -H yum -y install wget
    fi
else
    echo "ERROR: Supported package manager not found.  Supported: apt,yum"
fi

# To install python packages, we need pip.
#
# We can't use the apt packaged version of pip since
# older versions of pip are incompatible with
# requests, one of our indirect dependencies (bug 1459947).
wget -O /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py
sudo python /tmp/get-pip.py

sudo -E pip install -r "$(dirname $0)/../requirements.txt"

u=$(whoami)
g=$(groups | awk '{print $1}')

if [ ! -d /opt/stack ]; then
    mkdir -p /opt/stack || (sudo mkdir -p /opt/stack)
fi
sudo -H chown -R $u:$g /opt/stack
cd /opt/stack

if [ ! -d ansible ]; then
    git clone $ANSIBLE_GIT_URL --recursive -b $ANSIBLE_GIT_BRANCH
else
    cd ansible
    git checkout $ANSIBLE_GIT_BRANCH
    git pull --rebase
    git submodule update --init --recursive
    git fetch
fi

echo
echo "If you're using this script directly, execute the"
echo "following commands to update your shell."
echo
echo "source env-vars"
echo "source /opt/stack/ansible/hacking/env-setup"
echo
