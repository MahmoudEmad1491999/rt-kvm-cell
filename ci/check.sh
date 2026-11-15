#!/usr/bin/env bash
# Local verification (agent + you). Grows with the project; see CLAUDE.md.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== shellcheck =="
shopt -s nullglob globstar
sh_files=(scripts/**/*.sh ci/*.sh br2-external/**/*.sh)
[ ${#sh_files[@]} -gt 0 ] && shellcheck "${sh_files[@]}"

echo "== buildroot submodule =="
if [ ! -f .gitmodules ]; then
  echo "ERROR: .gitmodules missing — run: git submodule add ... buildroot" >&2; exit 1
fi
grep -q 'path = buildroot' .gitmodules || { echo "ERROR: .gitmodules has no buildroot entry" >&2; exit 1; }
grep -q 'url.*buildroot' .gitmodules    || { echo "ERROR: buildroot submodule has no url" >&2; exit 1; }
echo "  .gitmodules ok"

echo "== br2-external skeleton =="
for f in br2-external/external.desc br2-external/Config.in br2-external/external.mk \
         br2-external/package/Config.in; do
  [ -f "$f" ] || { echo "ERROR: $f missing" >&2; exit 1; }
done
grep -q '^name:' br2-external/external.desc || { echo "ERROR: external.desc missing 'name:'" >&2; exit 1; }
grep -q '^desc:' br2-external/external.desc || { echo "ERROR: external.desc missing 'desc:'" >&2; exit 1; }
echo "  br2-external skeleton ok"

echo "== cellhost_defconfig =="
DEFCONFIG=br2-external/configs/cellhost_defconfig
[ -f "$DEFCONFIG" ] || { echo "ERROR: $DEFCONFIG missing" >&2; exit 1; }
grep -q '^BR2_x86_64=y'                        "$DEFCONFIG" || { echo "ERROR: BR2_x86_64=y missing"                        >&2; exit 1; }
grep -q '^BR2_TOOLCHAIN_BUILDROOT_GLIBC=y'     "$DEFCONFIG" || { echo "ERROR: BR2_TOOLCHAIN_BUILDROOT_GLIBC=y missing"     >&2; exit 1; }
grep -q '^BR2_LINUX_KERNEL=y'                  "$DEFCONFIG" || { echo "ERROR: BR2_LINUX_KERNEL=y missing"                  >&2; exit 1; }
grep -q 'BR2_LINUX_KERNEL_CUSTOM_VERSION_VALUE.*6\.18' \
                                                "$DEFCONFIG" || { echo "ERROR: kernel version 6.18.x not set"               >&2; exit 1; }
grep -q '^BR2_TARGET_ROOTFS_EXT2=y'            "$DEFCONFIG" || { echo "ERROR: BR2_TARGET_ROOTFS_EXT2=y missing"            >&2; exit 1; }
grep -q '^BR2_TARGET_GENERIC_GETTY_PORT="ttyS0"' \
                                                "$DEFCONFIG" || { echo "ERROR: serial console (ttyS0 getty) not set"        >&2; exit 1; }
grep -q 'BR2_EXTERNAL_RT_KVM_CELL_PATH'        "$DEFCONFIG" || { echo "ERROR: BR2_EXTERNAL_RT_KVM_CELL_PATH ref missing"   >&2; exit 1; }
echo "  cellhost_defconfig ok"

echo "== cellhost board files =="
LINUX_CFG=br2-external/board/cellhost/linux.config
[ -f "$LINUX_CFG" ] || { echo "ERROR: $LINUX_CFG missing" >&2; exit 1; }
grep -q 'CONFIG_SERIAL_8250_CONSOLE=y' "$LINUX_CFG" || { echo "ERROR: serial console not in linux.config" >&2; exit 1; }
grep -q 'CONFIG_KVM=y'                 "$LINUX_CFG" || { echo "ERROR: CONFIG_KVM=y not in linux.config"   >&2; exit 1; }
grep -q 'CONFIG_VIRTIO_BLK=y'          "$LINUX_CFG" || { echo "ERROR: CONFIG_VIRTIO_BLK=y missing"        >&2; exit 1; }
grep -q 'CONFIG_EXT4_FS=y'             "$LINUX_CFG" || { echo "ERROR: CONFIG_EXT4_FS=y missing"           >&2; exit 1; }
echo "  board/cellhost ok"

echo "== Makefile images target =="
grep -q 'images-cellhost' Makefile || { echo "ERROR: images-cellhost target missing from Makefile" >&2; exit 1; }
grep -q 'cellhost_defconfig'       Makefile || { echo "ERROR: cellhost_defconfig not referenced in Makefile" >&2; exit 1; }
echo "  Makefile images target ok"

if [ -f Makefile ]; then
  echo "== make check =="
  make check
else
  echo "no Makefile yet — skipping build/tests"
fi
echo "ALL CHECKS PASSED"
