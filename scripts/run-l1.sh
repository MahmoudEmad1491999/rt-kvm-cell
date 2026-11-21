#!/usr/bin/env bash
# Boot the L1 cell-host VM in QEMU (headless, KVM-accelerated, slirp networking).
# Usage:  scripts/run-l1.sh [extra-qemu-args...]
#   SSH_PORT=10022  override the hostfwd SSH port (default 10022)
#
# After boot: ssh -p "${SSH_PORT}" root@localhost
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGES_DIR="${REPO_ROOT}/output/cellhost/images"
KERNEL="${IMAGES_DIR}/bzImage"
ROOTFS="${IMAGES_DIR}/rootfs.ext2"
SSH_PORT="${SSH_PORT:-10022}"

if [ ! -f "${KERNEL}" ]; then
    printf 'ERROR: kernel not found: %s\n       Run "make images" first.\n' "${KERNEL}" >&2
    exit 1
fi

if [ ! -f "${ROOTFS}" ]; then
    printf 'ERROR: rootfs not found: %s\n       Run "make images" first.\n' "${ROOTFS}" >&2
    exit 1
fi

# KVM is a project prerequisite; warn early so the error is obvious.
if [ ! -e /dev/kvm ]; then
    echo "WARNING: /dev/kvm not found — nested virtualisation is required, QEMU will fail" >&2
fi

exec qemu-system-x86_64 \
    -enable-kvm \
    -cpu host \
    -smp 6 \
    -m 6G \
    -nographic \
    -kernel "${KERNEL}" \
    -drive "file=${ROOTFS},format=raw,if=virtio" \
    -append "root=/dev/vda rw console=ttyS0,115200n8" \
    -netdev "user,id=net0,hostfwd=tcp::${SSH_PORT}-:22" \
    -device virtio-net-pci,netdev=net0 \
    "$@"
