#!/bin/bash

set -euo pipefail

if [[ "${BIFROST_TRACE:-}" == true ]]; then
    set -x
fi

declare -A PKG_MAP

# NOTE(rpittau): we need a stable recent version of pip to avoid issues with
# the cryptography package.
PIP_MIN_REQ="20.0.1"
PIP_TUPLE="(20, 0, 1)"

# workaround: for latest bindep to work, it needs to use en_US local
export LANG=en_US.UTF-8

export VENV=${VENV:-/opt/stack/bifrost}

# NOTE(dtantsur): change this when creating a stable branch
BRANCH=${ZUUL_BRANCH:-master}
CONSTRAINTS_FILE=${UPPER_CONSTRAINTS_FILE:-${TOX_CONSTRAINTS_FILE:-https://releases.openstack.org/constraints/upper/$BRANCH}}

CHECK_CMD_PKGS=(
    python3-devel
    python3
    python3-pip
)

echo "Detecting package manager"

source /etc/os-release || source /usr/lib/os-release
case ${ID,,} in
    *suse*)
    OS_FAMILY="Suse"
    INSTALLER_CMD="sudo -H -E zypper install -y --no-recommends"
    CHECK_CMD="zypper search --match-exact --installed"
    PKG_MAP=(
        [python3]=python3
        [python3-devel]=python3-devel
        [python3-pip]=python3-pip
    )
    EXTRA_PKG_DEPS=()
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
    CHECK_CMD="dpkg -s"
    PKG_MAP=(
        [python3]=python3-minimal
        [python3-devel]=libpython3-dev
        [python3-pip]=python3-pip
    )
    EXTRA_PKG_DEPS=( python3-venv python3-setuptools )
    sudo apt-get update
    # NOTE(dtantsur): workaround for segfault when installing cryptography:
    # https://github.com/pyca/cryptography/issues/3815
    if $(${CHECK_CMD} python3-cryptography &> /dev/null); then
        sudo -E apt-get remove -y python3-cryptography
    fi
    ;;

    rhel|fedora|centos)
    OS_FAMILY="RedHat"
    PKG_MANAGER=$(/usr/bin/which dnf || /usr/bin/which yum)
    if [[ "${BIFROST_TRACE:-}" != true ]]; then
        PKG_MANAGER="$PKG_MANAGER --quiet"
    fi
    INSTALLER_CMD="sudo -H -E ${PKG_MANAGER} -y install"
    CHECK_CMD="rpm -q"
    PKG_MAP=(
        [python3]=python3
        [python3-devel]=python3-devel
        [python3-pip]=python3-pip
    )
    EXTRA_PKG_DEPS=()
    sudo -E ${PKG_MANAGER} updateinfo
    ;;

    *) echo "ERROR: Supported package manager not found.  Supported: apt, dnf, yum, zypper"; exit 1;;
esac

echo "Installing Python and PIP"

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

if [ ! -f ${VENV}/bin/activate ]; then
    echo "Creating a virtual environment"

    # only create venv if one doesn't exist
    sudo -H -E python3 -m venv --system-site-packages ${VENV}
    sudo -H -E chown -R ${USER} ${VENV}
else
    echo "Virtual environment exists, skipping creation"

    # NOTE(dtantsur): place here any actions required to upgrade existing
    # virtual environments.
fi

# Note(cinerama): activate is not compatible with "set -u";
# disable it just for this line.
set +ux
. ${VENV}/bin/activate
set -u
if [[ "${BIFROST_TRACE:-}" == true ]]; then
    set -x
fi
VIRTUAL_ENV=${VENV}

# If we're using a venv, we need to work around sudo not
# keeping the path even with -E.
PYTHON="python3"
PIP="${PYTHON} -m pip"
if [[ "${BIFROST_TRACE:-}" != true ]]; then
    PIP="$PIP --quiet"
fi

# NOTE(rpittau): we need a stable recent version of pip to avoid issues with
# the cryptography package.
PIP_REQUIRED=$($PYTHON -c "import pip; print(tuple(map(int, pip.__version__.split('.'))) >= $PIP_TUPLE)")
if [[ $PIP_REQUIRED == "False" ]]; then
    ${PIP} install "pip==$PIP_MIN_REQ"
fi

export PIP_OPTS="--upgrade-strategy only-if-needed"

if [[ $OS_FAMILY == "Suse" ]]; then
    # https://storyboard.openstack.org/#!/story/2008591
    ${PIP} install -U setuptools
fi

echo "Installing bindep"
${PIP} install bindep

echo "Using Bindep to install binary dependencies"
# bindep returns 1 if packages are missing
bindep -b &> /dev/null || ${INSTALLER_CMD} $(bindep -b)

echo "Installing Python requirements"
${PIP} install -r "$(dirname $0)/../requirements.txt" -c "${CONSTRAINTS_FILE}"

echo "Completed installation of basic dependencies."
