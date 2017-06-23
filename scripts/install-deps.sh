#!/bin/bash
set -eu

declare -A PKG_MAP

CHECK_CMD_PKGS=(
    gcc
    libffi
    libopenssl
    lsb-release
    make
    net-tools
    python-devel
    python
    venv
    wget
)

# Check zypper before apt-get in case zypper-aptitude
# is installed
if [ -x '/usr/bin/zypper' ]; then
    OS_FAMILY="Suse"
    INSTALLER_CMD="sudo -H -E zypper install -y --no-recommends"
    CHECK_CMD="zypper search --match-exact --installed"
    PKG_MAP=(
        [gcc]=gcc
        [libffi]=libffi-devel
        [libopenssl]=libopenssl-devel
        [lsb-release]=lsb-release
        [make]=make
        [net-tools]=net-tools
        [python]=python
        [python-devel]=python-devel
        [venv]=python-virtualenv
        [wget]=wget
    )
    EXTRA_PKG_DEPS=( python-xml )
    # NOTE (cinerama): we can't install python without removing this package
    # if it exists
    if $(${CHECK_CMD} patterns-openSUSE-minimal_base-conflicts &> /dev/null); then
        sudo -H zypper remove -y patterns-openSUSE-minimal_base-conflicts
    fi
elif [ -x '/usr/bin/apt-get' ]; then
    OS_FAMILY="Debian"
    INSTALLER_CMD="sudo -H -E apt-get -y install"
    CHECK_CMD="dpkg -l"
    PKG_MAP=(
        [gcc]=gcc
        [libffi]=libffi-dev
        [libopenssl]=libssl-dev
        [lsb-release]=lsb-release
        [make]=make
        [net-tools]=net-tools
        [python]=python-minimal
        [python-devel]=libpython-dev
        [venv]=python-virtualenv
        [wget]=wget
    )
    EXTRA_PKG_DEPS=()
elif [ -x '/usr/bin/dnf' ] || [ -x '/usr/bin/yum' ]; then
    OS_FAMILY="RedHat"
    PKG_MANAGER=$(which dnf || which yum)
    INSTALLER_CMD="sudo -H -E ${PKG_MANAGER} -y install"
    CHECK_CMD="rpm -q"
    PKG_MAP=(
        [gcc]=gcc
        [libffi]=libffi-devel
        [libopenssl]=openssl-devel
        [lsb-release]=redhat-lsb
        [make]=make
        [net-tools]=net-tools
        [python]=python
        [python-devel]=python-devel
        [venv]=python-virtualenv
        [wget]=wget
    )
    EXTRA_PKG_DEPS=()
else
    echo "ERROR: Supported package manager not found.  Supported: apt, dnf, yum, zypper"
fi

# if running in OpenStack CI, then make sure epel is enabled
# since it may already be present (but disabled) on the host
if env | grep -q ^ZUUL; then
    if [[ -x '/usr/bin/yum' ]]; then
        ${INSTALLER_CMD} yum-utils
        sudo yum-config-manager --enable epel || true
    fi
fi

if ! $(python --version &>/dev/null); then
    ${INSTALLER_CMD} ${PKG_MAP[python]}
fi
if ! $(gcc -v &>/dev/null); then
    ${INSTALLER_CMD} ${PKG_MAP[gcc]}
fi
if ! $(wget --version &>/dev/null); then
    ${INSTALLER_CMD} ${PKG_MAP[wget]}
fi
if [ -n "${VENV-}" ]; then
    if ! $(python -m virtualenv --version &>/dev/null); then
        ${INSTALLER_CMD} ${PKG_MAP[venv]}
    fi
fi

for pkg in ${CHECK_CMD_PKGS[@]}; do
    if ! $(${CHECK_CMD} ${PKG_MAP[$pkg]} &>/dev/null); then
        ${INSTALLER_CMD} ${PKG_MAP[$pkg]}
    fi
done

if [ -n "${EXTRA_PKG_DEPS-}" ]; then
    for pkg in ${EXTRA_PKG_DEPS}; do
        if ! $(${CHECK_CMD} ${pkg} &>/dev/null); then
            ${INSTALLER_CMD} ${pkg}
        fi
    done
fi

if [ -n "${VENV-}" ]; then
    echo "NOTICE: Using virtualenv for this installation."
    if [ ! -f ${VENV}/bin/activate ]; then
        # only create venv if one doesn't exist
        sudo -H -E python -m virtualenv --no-site-packages ${VENV}
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
#
# Note(cinerama): If pip is linked to pip3, the rest of the install
# won't work. Remove the alternatives. This is due to ansible's
# python 2.x requirement.
if [[ $(readlink -f /etc/alternatives/pip) =~ "pip3" ]]; then
    sudo -H update-alternatives --remove pip $(readlink -f /etc/alternatives/pip)
fi

if ! which pip; then
    wget -O /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py
    sudo -H -E ${PYTHON} /tmp/get-pip.py
fi

PIP=$(which pip)

sudo -H -E ${PIP} install "pip>6.0"
sudo -H -E ${PIP} install -r "$(dirname $0)/../requirements.txt"

# Install the rest of required packages using bindep
sudo -H -E ${PIP} install bindep

# bindep returns 1 if packages are missing
bindep -b &> /dev/null || ${INSTALLER_CMD} $(bindep -b)
