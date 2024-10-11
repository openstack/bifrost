#!/usr/bin/env bash
# Patch Cirros 0.6.x GRUB to add console=ttyS0 for serial console output.
# Cirros 0.6 ships without console= on the kernel command line, so kernel and
# init messages are missing from libvirt/Ironic serial logs.
#
# NOTE: virt-copy-out/in cannot be used here. Those wrappers always pass
# guestfish -i (OS inspection), and Cirros 0.6 is not inspectable because the
# rootfs lives in the initrd. Use guestfish copy-out/copy-in with an explicit
# mount of the EFI partition instead.

set -euo pipefail
[[ "${DEBUG:-}" == "true" ]] && set -x

# Avoid clashing with the host libvirt instance used for test VMs in CI.
export LIBGUESTFS_BACKEND="${LIBGUESTFS_BACKEND:-direct}"

CIRROS_IMAGE="${1:-/var/lib/ironic/httpboot/deployment_image.qcow2}"
GRUB_CFG_PATH="/EFI/ubuntu/grub.cfg"
EFI_MOUNT="/dev/sda15:/"

if [[ ! -f "${CIRROS_IMAGE}" ]]; then
    echo "Error: Cirros image not found at ${CIRROS_IMAGE}" >&2
    exit 1
fi

if ! command -v guestfish >/dev/null 2>&1; then
    echo "Error: guestfish is required (install libguestfs-tools or libguestfs)" >&2
    exit 1
fi

echo "Patching Cirros image: ${CIRROS_IMAGE}"

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TEMP_DIR}"' EXIT
TEMP_GRUB="${TEMP_DIR}/grub.cfg"

guestfish --ro -a "${CIRROS_IMAGE}" -m "${EFI_MOUNT}" -- \
    copy-out "${GRUB_CFG_PATH}" "${TEMP_DIR}"

if [[ ! -f "${TEMP_GRUB}" ]]; then
    echo "Error: failed to copy ${GRUB_CFG_PATH} from ${CIRROS_IMAGE}" >&2
    exit 1
fi

if grep -q 'console=ttyS0' "${TEMP_GRUB}"; then
    echo "Cirros GRUB already has console=ttyS0, skipping"
    exit 0
fi

# Append console=ttyS0 to the linux kernel command line.
sed -i 's|\(linux[ ]\+/boot/vmlinuz[^ ]*\)|\1 console=ttyS0|' "${TEMP_GRUB}"

if ! grep -q 'console=ttyS0' "${TEMP_GRUB}"; then
    echo "Error: failed to add console=ttyS0 to GRUB configuration" >&2
    exit 1
fi

echo "=== Modified GRUB configuration ==="
cat "${TEMP_GRUB}"
echo "==================================="

guestfish --rw -a "${CIRROS_IMAGE}" -m "${EFI_MOUNT}" -- \
    copy-in "${TEMP_GRUB}" /EFI/ubuntu/

echo "Cirros image patched successfully!"
