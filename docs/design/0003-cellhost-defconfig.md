# 0003 — cellhost Buildroot defconfig

**Context.** Phase 0 step 3 creates the Buildroot configuration for the L1 "cell host" VM:
x86_64, glibc, Linux 6.18 LTS, minimal BusyBox rootfs, serial console.

**Decision.** `br2-external/configs/cellhost_defconfig` uses:

- **Linux 6.18.7** — same point release as Buildroot's upstream `qemu_x86_64_defconfig`, known
  to build cleanly with Buildroot 2026.02.3.  The roadmap calls this "6.18 LTS"; it is the latest
  stable 6.18.x branch (not a formal kernel.org LTS, but the most current 6.18 point release).
- **glibc** (`BR2_TOOLCHAIN_BUILDROOT_GLIBC=y`) — the internal Buildroot toolchain with glibc.
  Explicit despite being the Buildroot default; makes the intent clear and future-proofs against
  a default change.  glibc is required for `mlockall`/`mmap`/POSIX AIO in the RT control loop
  (Phase 2).
- **Full custom kernel config** (`BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG`) rather than a defconfig +
  fragments. Fragments (`kernel/rt.cfg`, `kernel/kvm-host.cfg`) are added in later roadmap steps;
  for Phase 0 a single self-contained file is simpler.  The file uses the "minimal overlay" style:
  only non-default settings are listed; Buildroot runs `make olddefconfig` to fill in the rest.
- **Dual-role kernel config** (`board/cellhost/linux.config`): enables both KVM *guest* drivers
  (`HYPERVISOR_GUEST`, `PARAVIRT`, `KVM_GUEST`, virtio block/net) and KVM *host* support
  (`KVM`, `KVM_INTEL`, `KVM_AMD`, `VHOST_NET`, `TUN`, `BRIDGE`), because the cellhost runs
  *inside* a KVM VM while also *hosting* three nested L2 VMs.
- **Serial console only** — `BR2_TARGET_GENERIC_GETTY_PORT="ttyS0"` (115200 baud); no GRUB,
  no graphical window.  QEMU will use `-nographic` or `-serial stdio` (Phase 0 step 4).
- **EXT2/4 rootfs** — a single file image; no GRUB partition table needed for direct-kernel boot.

**Alternatives considered.**

- Use `qemu_x86_64_defconfig` as a base and override with a fragment — less explicit, harder to
  audit.  Rejected in favour of an external-tree defconfig owned by this project.
- musl instead of glibc — saves ~2 MB on the rootfs but would require patching the RT apps later.
  Rejected per CLAUDE.md spec.

**Consequences.**

- `make images` runs a two-step Buildroot build (defconfig + build) in `output/cellhost/`.
- Downloads are cached in `~/.cache/rt-kvm-cell/dl` per CLAUDE.md.
- `ci/check.sh` validates the defconfig and board files structurally (no actual build in CI).
- Future kernel fragments (`kernel/rt.cfg`, `kernel/kvm-host.cfg`) will be added via
  `BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES` once the base config is confirmed working.
