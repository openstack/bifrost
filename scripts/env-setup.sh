#!/bin/bash
set -eu

ANSIBLE_GIT_URL=${ANSIBLE_GIT_URL:-https://github.com/ansible/ansible.git}
# Note(TheJulia): Normally this should be stable-2.0, pinning due to
# issues with the stable branch.
# https://github.com/ansible/ansible-modules-core/issues/2804
ANSIBLE_GIT_BRANCH=${ANSIBLE_GIT_BRANCH:-v2.0.0.0-1}

function check_get_module () {
    local file=${1}
    local url=${2}
    if [ ! -e ${file} ]; then
        wget -O ${file} ${url}
    fi
}

if [ -x '/usr/bin/apt-get' ]; then
    if ! $(gcc -v &>/dev/null); then
        sudo -H apt-get -y install gcc
    fi
    if ! $(git --version &>/dev/null) ; then
        sudo -H apt-get -y install git
    fi
    if ! $(python --version &>/dev/null); then
        sudo -H apt-get -y install python-minimal
    fi
    if ! $(dpkg -l libpython-dev &>/dev/null); then
        sudo -H apt-get -y install libpython-dev
    fi
    if ! $(dpkg -l wget &>/dev/null); then
        sudo -H apt-get -y install wget
    fi
    if [ -n "${VENV-}" ]; then
        if ! $(virtualenv --version &>/dev/null); then
            sudo -H apt-get -y install python-virtualenv
        fi
    fi
elif [ -x '/usr/bin/yum' ]; then
    if ! $(python --version $>/dev/null); then
        sudo -H yum -y install python
    fi
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
    if [ -n "${VENV-}" ]; then
        if $(virtualenv --version &>/dev/null); then
            sudo -H yum -y install python-virtualenv
        fi
    fi
    if ! $(rpm -q openssl-devel &>/dev/null); then
        sudo -H yum -y install openssl-devel
    fi
    if ! $(rpm -q libffi-devel &>/dev/null); then
        sudo -H yum -y install libffi-devel
    fi
else
    echo "ERROR: Supported package manager not found.  Supported: apt,yum"
fi

if [ -n "${VENV-}" ]; then
    echo "NOTICE: Using virtualenv for this installation."
    if [ ! -f ${VENV}/bin/activate ]; then
        # only create venv if one doesn't exist
        sudo -H -E virtualenv --no-site-packages ${VENV}
    fi
    # Note(cinerama): activate is not compatible with "set -u";
    # disable it just for this line.
    set +u
    source ${VENV}/bin/activate
    set -u
    VIRTUAL_ENV=${VENV}
else
    echo "NOTICE: Not using virtualenv for this installation."
fi

# If we're using a venv, we need to work around sudo not
# keeping the path even with -E.
PYTHON=$(which python)

# To install python packages, we need pip.
#
# We can't use the apt packaged version of pip since
# older versions of pip are incompatible with
# requests, one of our indirect dependencies (bug 1459947).
#
# Note(cinerama): We use pip to install an updated pip plus our
# other python requirements. pip breakages can seriously impact us,
# so we've chosen to install/upgrade pip here rather than in
# requirements (which are synced automatically from the global ones)
# so we can quickly and easily adjust version parameters.
# See bug 1536627.

if ! which pip; then
    wget -O /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py
    sudo -H -E ${PYTHON} /tmp/get-pip.py
fi

PIP=$(which pip)
sudo -H -E ${PIP} install "pip>6.0"
sudo -H -E ${PIP} install -r "$(dirname $0)/../requirements.txt"
u=$(whoami)
g=$(groups | awk '{print $1}')

if [ ! -d /opt/stack ]; then
    mkdir -p /opt/stack || (sudo mkdir -p /opt/stack)
fi
sudo -H chown -R $u:$g /opt/stack
cd /opt/stack

if [ ! -d ansible ]; then
    git clone $ANSIBLE_GIT_URL --recursive -b $ANSIBLE_GIT_BRANCH
    cd ansible
else
    cd ansible
    git remote update origin --prune
    git fetch --tags
    git checkout $ANSIBLE_GIT_BRANCH
    git pull --rebase origin $ANSIBLE_GIT_BRANCH
    git submodule update --init --recursive
    git fetch
fi
# Note(TheJulia): These files should be in the ansible folder
# and this functionality exists for a level of ansible 1.9.x
# backwards compatability although the modules were developed
# for Ansible 2.0.

check_get_module `pwd`/lib/ansible/modules/core/cloud/openstack/os_ironic.py \
    https://raw.githubusercontent.com/ansible/ansible-modules-core/stable-2.0/cloud/openstack/os_ironic.py
check_get_module `pwd`/lib/ansible/modules/core/cloud/openstack/os_ironic_node.py \
    https://raw.githubusercontent.com/ansible/ansible-modules-core/stable-2.0/cloud/openstack/os_ironic_node.py

# Note(TheJulia): Proposed, however not yet accepted. Once the pull request
# https://github.com/ansible/ansible-modules-extras/pull/1681 has merged, this
# URL should be changed.
check_get_module `pwd`/lib/ansible/modules/extras/cloud/openstack/os_ironic_inspect.py \
    https://raw.githubusercontent.com/juliakreger/ansible-modules-extras/feature/os-ironic-inspect/cloud/openstack/os_ironic_inspect.py

if [ -n "${VENV-}" ]; then
    sudo -H -E ${PIP} install --upgrade /opt/stack/ansible
    echo
    echo "To use bifrost, do"

    echo "source ${VENV}/bin/activate"
    echo "source env-vars"
    echo "Then run playbooks as normal."
    echo
else
    echo
    echo "If you're using this script directly, execute the"
    echo "following commands to update your shell."
    echo
    echo "source env-vars"
    echo "source /opt/stack/ansible/hacking/env-setup"
    echo
fi
