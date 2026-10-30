# Roadmap

One task ≈ one day. The agent takes the first unchecked item.

## Phase 0 — Skeleton
- [ ] Top-level Makefile (images/run/check/ci/clean targets as stubs), `.gitignore`, `docs/design/0001-architecture.md` with the diagram from CLAUDE.md
- [ ] Pin Buildroot (latest LTS 20xx.02.x) as a submodule; `br2-external/` skeleton (external.desc, Config.in, external.mk)
- [ ] `cellhost_defconfig`: x86_64, glibc, Linux 6.18 LTS, minimal rootfs, serial console; `make images` builds it
- [ ] `scripts/run-l1.sh`: boot cell host in QEMU (-enable-kvm -cpu host, 6 vCPU, 6 GB, slirp with ssh hostfwd), headless serial
- [ ] `tests/e2e/boot_l1.py` (pexpect): boot, log in, assert kernel version; wired into `make check`
- [ ] Kernel fragment `kernel/rt.cfg`: PREEMPT_RT, HZ=1000, NO_HZ_FULL, RCU_NOCB, disable debug options; assert `uname -v` contains PREEMPT_RT
- [ ] Kernel fragment `kernel/kvm-host.cfg`: KVM, KVM_INTEL, VHOST, VFIO-less virtio, tun/bridge; `/dev/kvm` present in L1 (e2e assert)
- [ ] Add QEMU (target package, x86_64 softmmu only) to the cell host; `qemu-system-x86_64 --version` e2e check

## Phase 1 — Guests
- [ ] `guest_std_defconfig`: small x86_64 guest (BusyBox, virtio drivers), image < 64 MB
- [ ] `guest_rt_defconfig`: same plus PREEMPT_RT kernel and rt-tests (cyclictest)
- [ ] Ship guest images inside the cell-host rootfs (/var/lib/cell/images) via post-build script
- [ ] `scripts/start-cell.sh` (runs in L1): launch vm-gw, vm-mon, vm-ctrl with QEMU+KVM, serial logs to /var/log/cell
- [ ] Networking inside L1: bridge br0 + tap per guest, static IPs (10.10.0.0/24), e2e ping test between guests
- [ ] Init integration: cell starts automatically at boot (BusyBox init script), clean shutdown of guests
- [ ] e2e test: all three guests boot and report their role over the network within 60 s
- [ ] QMP control socket per guest + `cellctl` script: status/stop/start/restart a guest

## Phase 2 — Shared memory & applications
- [ ] `apps/libshm`: seqlock mailbox (sensor frame + actuator frame) in a mmapped region, host unit tests incl. torn-read test with threads
- [ ] ivshmem-plain device shared by vm-ctrl and vm-gw (memory-backend-file in L1 /dev/shm); guest maps BAR2 via sysfs resource
- [ ] `apps/plant-sim`: DC motor model (RK4 integration at 10 kHz), publishes speed/current to shm, reads voltage command
- [ ] Plant model unit tests: step response matches analytical first-order solution within tolerance
- [ ] `apps/ctrl-loop`: SCHED_FIFO 80, mlockall, clock_nanosleep absolute 1 ms period, reads sensor, writes command
- [ ] PID controller with anti-windup + derivative filter in ctrl-loop; unit tests against plant model on host
- [ ] ctrl-loop timing instrumentation: per-cycle wake-up latency + execution time histograms in shared ring buffer
- [ ] Package apps as Buildroot packages in br2-external/package; installed in the right guests
- [ ] e2e: closed loop runs, motor reaches setpoint within 0.5 s (asserted from telemetry)

## Phase 3 — Monitoring VM
- [ ] Telemetry protocol (UDP, versioned binary or CBOR) from ctrl-loop and plant-sim to vm-mon
- [ ] `apps/telemetry` collector in vm-mon: stores ring of last N minutes, computes p50/p99/max latency, deadline misses
- [ ] Minimal web dashboard served from vm-mon (static HTML + SSE), forwarded to the laptop browser through L1/L0 hostfwd
- [ ] Dashboard charts: speed vs setpoint, latency histogram, deadline-miss counter
- [ ] Watchdog: vm-mon detects stale heartbeat from vm-ctrl and restarts it via QMP through L1
- [ ] Safe-state: plant-sim applies zero voltage if controller heartbeat stops (fail-safe), e2e test kills ctrl-loop
- [ ] e2e: kill vm-ctrl → safe-state within 10 ms of missed heartbeat window → automatic recovery

## Phase 4 — Real-time tuning (the core experiment)
- [ ] `scripts/measure.sh`: run cyclictest in vm-ctrl for N minutes, export histogram CSV to docs/results
- [ ] Baseline measurement: untuned everything, idle neighbours → docs/results/00-baseline.md
- [ ] Noisy neighbours: stress-ng CPU/memory/IO load in vm-gw and vm-mon; measure again
- [ ] L1 tuning: isolcpus, nohz_full, rcu_nocbs for vCPU 2-4; housekeeping on 0-1
- [ ] Pin vm-ctrl vCPU threads (QMP query-cpus-fast → taskset) and QEMU I/O threads to housekeeping CPUs
- [ ] Run vCPU threads of vm-ctrl as SCHED_FIFO in L1; document priority layout (ksoftirqd, rcuc, ktimers)
- [ ] IRQ affinity: move all device IRQs off isolated CPUs in L1 and in vm-ctrl
- [ ] Guest-side tuning in vm-ctrl: isolcpus, idle=poll vs halt-polling comparison, `kvm-clock` notes
- [ ] Hugepages-backed guest memory for vm-ctrl, measure effect
- [ ] Disable/limit frequency transitions & C-states exposure, compare (document laptop limits honestly)
- [ ] Repeat full measurement matrix (idle/stressed × untuned/tuned) → docs/results/10-tuning-matrix.md with charts
- [ ] `scripts/tune-host.sh` idempotent tuning script + verification mode that reports current state

## Phase 5 — Robustness & features
- [ ] cgroup v2 CPU/memory limits for non-RT guests; prove they can't starve the RT guest
- [ ] Memory ballooning for vm-mon; show ctrl latency unaffected during balloon inflate
- [ ] Live-migration-free update: restart vm-gw with a new plant-sim while ctrl holds last safe command
- [ ] Ftrace/trace-cmd capture of worst-case latency event in L1 + analysis write-up (osnoise/timerlat tracers)
- [ ] `rtla timerlat` run inside vm-ctrl, compare with cyclictest
- [ ] Configurable control rate (1/2/5 kHz) and the max reliable rate found → results
- [ ] Event log + alarms in vm-mon (overshoot, saturation, deadline miss)
- [ ] Persistent results: every `make measure` run appends to docs/results/history.csv

## Phase 6 — Testing & CI
- [ ] Unit tests for all apps runnable on host with sanitizers (`make ci`)
- [ ] e2e suite runner with JUnit XML output, timeouts, log collection on failure
- [ ] Nightly-style long test (30 min) script, not part of check.sh, documented
- [ ] Fault-injection tests: drop telemetry packets, corrupt shm frame, pause vm-gw (QMP stop) → expected behaviour
- [ ] Reproducibility: pinned Buildroot + hashes; `make images` from clean clone documented with timing

## Phase 7 — Documentation & polish
- [ ] Architecture diagrams (Mermaid): boot flow, data flow, CPU/IRQ layout
- [ ] docs/design: why ivshmem over virtio-vsock for the control path (with measurements)
- [ ] docs/results/README: executive summary with the key charts and the nesting caveat
- [ ] README: GIF/screenshots of the dashboard, quick-start verified from scratch
- [ ] Optional bare-metal mode: run L1 image directly on the laptop with KVM (no nesting) and compare numbers
- [ ] Release v1.0.0 with prebuilt images as release assets and CHANGELOG

## Phase 8 — Extensions
- [ ] vsock-based control channel between L1 and guests (replace serial scraping in tests)
- [ ] Measure ivshmem vs vsock vs virtio-net round-trip latency → docs/results/20-ipc.md
- [ ] Second RT guest variant using Zephyr or a bare-metal x86 payload for vm-ctrl; compare latency vs Linux RT
- [ ] Jailhouse-style static partitioning research note: what changes vs KVM (doc only)
- [ ] OPC UA (open62541) server in vm-gw exposing plant variables
- [ ] OPC UA client in vm-mon reading the plant; dashboard shows both paths
- [ ] Time synchronisation: PTP (linuxptp) between guests over virtio-net, report offset statistics
- [ ] Time-triggered actuation: ctrl output applied at exact period boundaries using shared clock
- [ ] Deterministic networking experiment: SO_TXTIME / ETF qdisc for telemetry, measure jitter
- [ ] cgroup v2 cpuset partitions (isolated partition) as alternative to isolcpus; compare
- [ ] Core scheduling / SMT considerations doc + measurement with SMT siblings disabled for vm-ctrl
- [ ] Guest-side PREEMPT_RT priority layout tool: dump & verify thread priorities against a spec file
- [ ] Automatic regression gate: `make check` fails if p99 latency regresses > X % vs stored baseline
- [ ] Grafana-free lightweight trend chart of history.csv generated into docs/results
- [ ] Security: seccomp/sandboxing of QEMU processes in L1 (`-sandbox on`), run QEMU as unprivileged user
- [ ] Guest image signing + verification before start-cell launches them
- [ ] Config file (`cell.toml`) describing VMs, CPUs, memory, devices; start-cell.sh generated from it
- [ ] `cellctl` rewritten in Python with subcommands and JSON output; unit tests
- [ ] Failure drill doc: what happens on host overload, guest crash, shm corruption — with test evidence
- [ ] Energy/CPU-usage comparison: polling vs interrupt-driven ctrl loop
- [ ] Optional: port vm-gw rootfs to the Yocto EdgeOS image (cross-project integration)
- [ ] Optional: GitHub Actions job that builds images on a schedule and uploads them (weekly)
- [ ] Talk-style write-up: "Consolidating an RT cell on KVM — lessons learned" in docs/
- [ ] Final README polish with results table and reproducibility checklist
