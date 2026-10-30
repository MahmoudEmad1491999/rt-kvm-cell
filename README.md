# rt-kvm-cell

A **PREEMPT_RT Linux host consolidating three KVM virtual machines** that would normally be three separate
boxes in an industrial cell, all reproducible on a laptop through nested QEMU/KVM.

| VM | Role | Kernel | Key requirement |
|---|---|---|---|
| `vm-ctrl` | 1 kHz closed-loop motor controller | PREEMPT_RT | deadline misses = 0 under load |
| `vm-gw` | plant simulator + field-I/O gateway | standard | feeds sensor data via shared memory |
| `vm-mon` | telemetry, latency stats, dashboard, watchdog | standard | detects & recovers a failed controller |

The question it answers: *how much isolation and tuning does a real-time guest need to stay deterministic next to noisy neighbours?*
Results are in [docs/results](docs/results).

> 🚧 Built incrementally — see [ROADMAP.md](ROADMAP.md) and the [development journal](docs/journal).

## Quick start
```sh
make images     # Buildroot: cell host + guest images (first build ~1 h)
make run        # boots the cell host in QEMU and starts the three guests
make check      # unit tests + end-to-end boot and latency smoke test
```
