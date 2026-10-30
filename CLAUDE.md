# rt-kvm-cell — rules for the coding agent

## Goal
Show that one PREEMPT_RT Linux host can consolidate a small industrial "cell" — normally three separate boxes —
into three KVM guests **without the real-time guest missing deadlines**, and prove it with measurements.

## Architecture (everything runs on a laptop, nested in QEMU)
```
L0  laptop (Ubuntu, KVM)
└─ L1  "cell host" VM  — qemu-system-x86_64 -enable-kvm -cpu host, 6 vCPU, 6 GB
       Buildroot rootfs, Linux 6.18 LTS + PREEMPT_RT, isolcpus/nohz_full on vCPU 2-4, QEMU+KVM inside
       ├─ L2 vm-ctrl   (RT guest)   2 vCPU pinned to isolated cores, PREEMPT_RT kernel, SCHED_FIFO 1 kHz control loop
       ├─ L2 vm-gw     (gateway)    plant simulator + field-I/O: produces sensor values, applies actuator outputs
       └─ L2 vm-mon    (monitoring) telemetry collector, latency stats, web dashboard, watchdog/restart of vm-ctrl
   vm-ctrl ⇄ vm-gw : ivshmem shared-memory mailbox (low latency, lock-free seqlock)
   vm-gw/vm-ctrl → vm-mon : virtio-net, UDP telemetry
```
Nested virtualization adds latency the real thing wouldn't have. Never hide this: report **relative** results
(untuned vs tuned, idle vs stressed) and state the nesting caveat in docs/results.

## Layout
```
Makefile                 top-level: `make images`, `make run`, `make check`, `make ci`
br2-external/            Buildroot external tree: configs/{cellhost,guest_rt,guest_std}_defconfig, board/, package/
kernel/                  kernel config fragments (rt.cfg, kvm-host.cfg, guest.cfg)
apps/ctrl-loop/          C: RT control loop (PID), cyclic timing, shm client
apps/plant-sim/          C: DC-motor plant model, shm server
apps/telemetry/          C or Python: collector + dashboard
apps/libshm/             C: ivshmem mailbox (seqlock), host-testable
scripts/                 run-l1.sh, start-cell.sh (inside L1), tune-host.sh, measure.sh
tests/                   host unit tests for apps/, tests/e2e/*.py (pexpect over L1 serial)
docs/design/ docs/results/ docs/journal/ (human-only — never edit journal)
```

## Rules
- Buildroot version pinned (git submodule or download with sha256). Downloads cached in `~/.cache/rt-kvm-cell/dl`.
- Laptop has 16 GB RAM: L1 ≤ 6 GB; L2 guests ≤ 1 GB each. Use `-j$(nproc)` for builds but never run two builds at once.
- No sudo anywhere. User-mode networking (slirp/hostfwd) for L0↔L1; inside L1 use a bridge/tap (root inside L1 is fine).
- C code: C11, `-Wall -Wextra -Werror`, real-time code avoids malloc/printf in the loop, locks memory (`mlockall`).
- Every measurement script writes machine-readable output (CSV/JSON) to `docs/results/` plus a short Markdown summary.
- Extend `ci/check.sh` as the project grows; it must always run every test that exists. `make ci` = fast subset for GitHub (no image builds).

## Commit style
Conventional Commits, scopes: `host`, `guest`, `ctrl`, `plant`, `shm`, `mon`, `tune`, `test`, `docs`.
