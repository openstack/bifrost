#!/bin/bash
set -e

if [ -x '/usr/bin/apt-get' ]; then
    if ! $(git --version &>/dev/null) ; then
        sudo -H apt-get -y install git
    fi
    # To install python packages, we need pip.
    #
    # We can't use the apt packaged version of pip since
    # older versions of pip are incompatible with
    # requests, one of our indirect dependencies (bug 1459947).
    #
    # So we use easy_install to install pip.
    #
    # But we may not have easy_install; if that's the case,
    # our bootstrap's bootstrap is to use apt to install
    # python-setuptools to get easy_install.
    if ! $(easy_install --version &>/dev/null) ; then
        sudo -H apt-get -y install python-setuptools
    fi
elif [ -x '/usr/bin/yum' ]; then
    if ! yum -q list installed python-devel; then
        sudo -H yum -y install python-devel
    fi
    if ! $(git --version &>/dev/null); then
        sudo -H yum -y install git
    fi
else
    echo "ERROR: Supported package manager not found.  Supported: apt,yum"
fi

if ! $(pip -v &>/dev/null); then
       sudo easy_install pip
fi

sudo -E pip install -r "$(dirname $0)/../requirements.txt"

u=$(whoami)
g=$(groups | awk '{print $1}')

if [ ! -d /opt/stack ]; then
    mkdir -p /opt/stack || (sudo mkdir -p /opt/stack)
fi
sudo -H chown -R $u:$g /opt/stack
cd /opt/stack

# NOTE(TheJulia): Switching to Ansible stable-1.9 branch as the development
# branch is undergoing some massive changes and we are seeing odd failures
# that we should not be seeing.  Until devel has stabilized, we should stay
# on the stable branch.
if [ ! -d ansible ]; then
    git clone https://github.com/ansible/ansible.git --recursive -b stable-1.9
else
    cd ansible
    git checkout stable-1.9
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
