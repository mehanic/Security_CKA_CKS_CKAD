#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>

// License declaration
char LICENSE[] SEC("license") = "Dual BSD/GPL";

// Declare a perf event array map named "map_name"
struct {
    __uint(type, BPF_MAP_TYPE_PERF_EVENT_ARRAY);
    __uint(max_entries, 1024);
    __type(key, int);
    __type(value, int);
} map_name SEC(".maps");

// Tracepoint for sys_enter_write
SEC("tp/syscalls/sys_enter_write")
int handle_tp(struct trace_event_raw_sys_enter *ctx)
{
    __u32 pid = bpf_get_current_pid_tgid() >> 32;

    // Retrieve syscall arguments
    int fd = ctx->args[0];
    char *buf = (char *)ctx->args[1];
    __u64 count = ctx->args[2];

    char data[128] = {};
    bpf_probe_read_user(data, sizeof(data) - 1, buf);

    // Print syscall info (use `sudo cat /sys/kernel/debug/tracing/trace` to see)
    bpf_printk("PID: %u, FD: %d, Data: %s, Count: %llu\n", pid, fd, data, count);

    return 0;
}
