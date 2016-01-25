#!/bin/bash
set -e

ANSIBLE_GIT_URL=${ANSIBLE_GIT_URL:-https://github.com/ansible/ansible.git}
# Note(TheJulia): Normally this should be stable-2.0, pinning due to
# issues with the stable branch.
# https://github.com/ansible/ansible-modules-core/issues/2804
ANSIBLE_GIT_BRANCH=${ANSIBLE_GIT_BRANCH:-v2.0.0.0-1}

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

# Note(TheJulia) This originally appeared because older
# versions of pip would do the wrong thing, 1459947.
# However, now pip 8.0 breaks things.  See 1536627
#wget -O /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py
#sudo -H -E python /tmp/get-pip.py

if ! which pip; then
    wget -O /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py
    sudo -H -E python /tmp/get-pip.py
fi

sudo -H -E pip install "pip>6.0"
sudo -H -E pip install -r "$(dirname $0)/../requirements.txt"

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
    git pull --rebase origin $ANSIBLE_GIT_BRANCH
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
