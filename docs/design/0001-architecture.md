# 0001 — System architecture: three-guest RT cell on a single KVM host

**Context.** Industrial automation cells typically use three separate boxes: an RT controller, a
plant/gateway, and a monitoring station. This project demonstrates that one PREEMPT_RT Linux host
(itself running as a KVM guest for portability) can replace all three without the RT guest missing
deadlines.

**Decision.** Three L2 KVM guests share a single L1 "cell host" VM:

```
L0  laptop (Ubuntu, KVM)
└─ L1  cell host — qemu-system-x86_64 -enable-kvm -cpu host, 6 vCPU, 6 GB
       Buildroot rootfs, Linux 6.18 LTS + PREEMPT_RT, isolcpus/nohz_full on vCPU 2-4
       ├─ L2 vm-ctrl   RT controller  2 vCPU pinned to isolated cores, SCHED_FIFO 1 kHz loop
       ├─ L2 vm-gw     gateway        plant simulator + field-I/O
       └─ L2 vm-mon    monitoring     telemetry, latency stats, web dashboard, watchdog

   vm-ctrl ⇄ vm-gw  : ivshmem shared-memory mailbox (seqlock, zero-copy)
   vm-gw/vm-ctrl → vm-mon : virtio-net UDP telemetry
```

**Communication paths chosen:**
- Control path (vm-ctrl ↔ vm-gw): ivshmem because a single page-flip avoids the virtio queue
  overhead; at 1 kHz every microsecond counts.
- Telemetry (→ vm-mon): UDP over virtio-net; loss-tolerant, no latency requirement.

**Alternatives considered:**
- virtio-vsock for the control path — adds ~10 µs of copy overhead per frame, rejected.
- Three real boxes — eliminates nesting overhead but defeats the consolidation goal.

**Nesting caveat.** L0 → L1 → L2 adds latency that bare-metal L1 would not have. All results
are reported as *relative* (untuned vs tuned, idle vs stressed), not as absolute numbers. The
nesting caveat is stated in every results document.

**Consequences.** CPU pinning and PREEMPT_RT in both L1 and L2 are required to control latency.
Phase 4 of the roadmap quantifies the tuning impact.
