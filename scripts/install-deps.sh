#!/bin/bash
set -xeu

declare -A PKG_MAP

# workaround: for latest bindep to work, it needs to use en_US local
export LANG=c

ENABLE_VENV=${ENABLE_VENV:-true}
if [[ "$ENABLE_VENV" != false ]]; then
    export VENV=${VENV:-/opt/stack/bifrost}
fi

CHECK_CMD_PKGS=(
    python3-devel
    python3
    python3-pip
)

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
    PKG_MANAGER=$(which dnf || which yum)
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
        sudo -H -E chown -R ${USER} ${VENV}
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
PYTHON="python3"
PIP="${PYTHON} -m pip"

$PYTHON << EOF
import pip
version = tuple(map(int, pip.__version__.split('.')))
assert version >= (7, 1)
EOF

export PIP_OPTS="--upgrade-strategy only-if-needed"

if [ -n "${VENV-}" ]; then
  ls -la ${VENV}/bin
fi

# Install the rest of required packages using bindep
if [ -n "${VENV-}" ]; then
    ${PIP} install bindep
else
    sudo -H -E ${PIP} install bindep
fi

echo "Using Bindep to install binary dependencies..."
# bindep returns 1 if packages are missing
bindep -b &> /dev/null || ${INSTALLER_CMD} $(bindep -b)

echo "Installing Python requirements"
if [ -n "${VENV-}" ]; then
    ${PIP} install -r "$(dirname $0)/../requirements.txt"
else
    sudo -H -E ${PIP} install -r "$(dirname $0)/../requirements.txt"
fi

echo "Completed installation of basic dependencies."
