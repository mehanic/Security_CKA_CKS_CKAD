/* SPDX-License-Identifier: (LGPL-2.1 OR BSD-2-Clause) */
#define BPF_NO_GLOBAL_DATA
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>
#include <linux/types.h>  // Make sure this is present

typedef unsigned int u32;
typedef int pid_t;

// Define the event structure (matches Go code)
struct event {
    __u64 time_since_boot;   // __u64 instead of u64
    __u32 processing_time;   // __u32 instead of u32
    __u8 event_type;         // __u8 instead of u8
    __u8 _pad[3];            // Padding for alignment
};

const pid_t pid_filter = 0;

// Define the perf event map
struct {
    __uint(type, BPF_MAP_TYPE_PERF_EVENT_ARRAY);
    __uint(max_entries, 128);
} output_map SEC(".maps");

// XDP program
SEC("xdp")
int xdp_prog(struct xdp_md *ctx) {
    struct event e = {};
    e.time_since_boot = bpf_ktime_get_boot_ns();
    e.processing_time = 42;  // Placeholder value
    e.event_type = 1;

    bpf_perf_event_output(ctx, &output_map, BPF_F_CURRENT_CPU, &e, sizeof(e));
    return XDP_PASS;  // Pass the packet
}

// Tracepoint program
SEC("tp/syscalls/sys_enter_write")
int handle_tp(void *ctx) {
    pid_t pid = bpf_get_current_pid_tgid() >> 32;
    if (pid_filter && pid != pid_filter)
        return 0;

    bpf_printk("BPF triggered sys_enter_write from PID %d.\n", pid);
    return 0;
}

char LICENSE[] SEC("license") = "Dual BSD/GPL";
