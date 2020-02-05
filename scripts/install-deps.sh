#!/bin/bash
set -xeu

declare -A PKG_MAP

# workaround: for latest bindep to work, it needs to use en_US local
export LANG=c

CHECK_CMD_PKGS=(
    gcc
    libffi
    libopenssl
    lsb-release
    make
    net-tools
    python3-devel
    python3
    wget
)

source /etc/os-release || source /usr/lib/os-release
case ${ID,,} in
    *suse*)
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
        [wget]=wget
    )
    EXTRA_PKG_DEPS=( python-xml )
    # netstat moved to net-tools-deprecated in Leap 15
    [[ ${VERSION%%.*} -lt 42 ]] && EXTRA_PKG_DEPS+=( net-tools-deprecated )
    sudo zypper -n ref
    # NOTE (cinerama): we can't install python without removing this package
    # if it exists
    if $(${CHECK_CMD} patterns-openSUSE-minimal_base-conflicts &> /dev/null); then
        sudo -H zypper remove -y patterns-openSUSE-minimal_base-conflicts
    fi
    ;;

    ubuntu|debian)
    OS_FAMILY="Debian"
    export DEBIAN_FRONTEND=noninteractive
    INSTALLER_CMD="sudo -H -E apt-get -y install"
    CHECK_CMD="dpkg -l"
    PKG_MAP=(
        [gcc]=gcc
        [libffi]=libffi-dev
        [libopenssl]=libssl-dev
        [lsb-release]=lsb-release
        [make]=make
        [net-tools]=net-tools
        [python3]=python3-minimal
        [python3-devel]=libpython3-dev
        [wget]=wget
        [venv]=python3-venv
    )
    EXTRA_PKG_DEPS=( python3-apt )
    sudo apt-get update
    ;;

    rhel|fedora|centos)
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
        [python]=python3
        [python-devel]=python3-devel
        [wget]=wget
    )
    EXTRA_PKG_DEPS=()
    sudo -E ${PKG_MANAGER} updateinfo
    if $(grep -q Fedora /etc/redhat-release); then
        EXTRA_PKG_DEPS="python3-dnf redhat-rpm-config"
    fi
    ;;

    *) echo "ERROR: Supported package manager not found.  Supported: apt, dnf, yum, zypper"; exit 1;;
esac

# if running in OpenStack CI, then make sure epel is enabled
# since it may already be present (but disabled) on the host
if env | grep -q ^ZUUL; then
    if [[ -x '/usr/bin/yum' ]]; then
        ${INSTALLER_CMD} yum-utils
        sudo yum-config-manager --enable epel || true
    fi
fi

if ! $(python3 --version &>/dev/null); then
    ${INSTALLER_CMD} ${PKG_MAP[python3]}
fi
if ! $(gcc -v &>/dev/null); then
    ${INSTALLER_CMD} ${PKG_MAP[gcc]}
fi
if ! $(wget --version &>/dev/null); then
    ${INSTALLER_CMD} ${PKG_MAP[wget]}
fi
if [ -n "${VENV-}" -a "${OS_FAMILY}" == "Debian" ]; then
        ${INSTALLER_CMD} ${PKG_MAP[venv]}
fi

for pkg in ${CHECK_CMD_PKGS[@]}; do
    if ! $(${CHECK_CMD} ${PKG_MAP[$pkg]} &>/dev/null); then
        ${INSTALLER_CMD} ${PKG_MAP[$pkg]}
    fi
done

if [ "${#EXTRA_PKG_DEPS[@]}" -ne 0 ]; then
    for pkg in ${EXTRA_PKG_DEPS[@]}; do
        if ! $(${CHECK_CMD} ${pkg} &>/dev/null); then
            ${INSTALLER_CMD} ${pkg}
        fi
    done
fi

if [ -n "${VENV-}" ]; then
    echo "NOTICE: Using virtualenv for this installation."
    if [ ! -f ${VENV}/bin/activate ]; then
        # only create venv if one doesn't exist
        sudo -H -E python3 -m venv --system-site-packages ${VENV}
    fi
    # Note(cinerama): activate is not compatible with "set -u";
    # disable it just for this line.
    set +u
    . ${VENV}/bin/activate
    set -u
    VIRTUAL_ENV=${VENV}
else
    echo "NOTICE: Not using virtualenv for this installation."
fi

# If we're using a venv, we need to work around sudo not
# keeping the path even with -E.
PYTHON=$(which python3)

# To install python packages, we need pip.
#
# We can't use the apt packaged version of pip since
# older versions of pip are incompatible with
# requests, one of our indirect dependencies (bug 1459947).
#
ls $PYTHON
sudo -H -E $PYTHON -m pip install -U pip --ignore-installed
if [ "$?" != "0" ]; then
    wget -O /tmp/get-pip.py https://bootstrap.pypa.io/3.4/get-pip.py
    sudo -H -E ${PYTHON} /tmp/get-pip.py
fi

if [ -n "${VENV-}" ]; then
  ls -la ${VENV}/bin
fi

PIP=$(echo $PYTHON | sed 's/python/pip/')

if [ "$OS_FAMILY" == "RedHat" ]; then
    sudo -H -E ${PIP} freeze
    sudo -H -E ${PIP} install --ignore-installed pyparsing ipaddress
fi
sudo -H -E ${PIP} install -r "$(dirname $0)/../requirements.txt"

# Install the rest of required packages using bindep
sudo -H -E ${PIP} install bindep

echo "Using Bindep to install binary dependencies..."
# bindep returns 1 if packages are missing
bindep -b &> /dev/null || ${INSTALLER_CMD} $(bindep -b)
echo "Completed installation of basic dependencies."
