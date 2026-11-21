# 0002 — QEMU flags for `scripts/run-l1.sh`

**Context.** `scripts/run-l1.sh` starts the L1 cell-host VM headlessly on a developer's
laptop without root privileges.

**Decisions.**

*Slirp networking (`-netdev user`).* Requires no kernel bridge, no TUN/TAP, and no `sudo`.
SSH reachability via `hostfwd=tcp::${SSH_PORT}-:22` (default 10022) covers all Phase 0–2
development. `SSH_PORT` is overridable so CI or parallel instances can avoid port conflicts.
Tradeoff: higher per-packet overhead than TAP, irrelevant for management-only L0↔L1 traffic.

*`-enable-kvm -cpu host` unconditional.* The script warns and exits early if `/dev/kvm` is
absent rather than silently degrading to TCG. Nested-virt is a project prerequisite; a silent
slow fallback would mask environment problems.

*`exec` to replace the shell.* `exec qemu-system-x86_64 …` replaces the shell process so
Ctrl-C, SIGTERM, and exit-code flow directly from QEMU to the caller without an extra process.

*`-drive if=virtio`.* Exposes the rootfs as `/dev/vda`, matching `CONFIG_VIRTIO_BLK=y` in
`linux.config`. IDE emulation adds unnecessary overhead and legacy interrupt routing.

*`"$@"` pass-through.* Callers (Phase 1 scripts, test harnesses) can inject QMP sockets,
extra drives, or snapshot flags without modifying this script.

**Alternatives considered.** `-M q35` (PCIe machine type) adds an IOMMU and PCIe topology
closer to real hardware but requires OVMF/UEFI. Deferred: the default `pc` machine type
suffices for Phase 0 and avoids a firmware dependency.

**Consequences.** Phase 1 networking inside L1 uses TAP/bridge; slirp is only the L0↔L1
management plane and is unaffected by that change.
