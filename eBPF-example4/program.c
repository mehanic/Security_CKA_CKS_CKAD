#include <linux/bpf.h>
#include <linux/ptrace.h>
#include <linux/types.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>

char LICENSE[] SEC("license") = "Dual BSD/GPL";

// For accessing syscall arguments via registers
struct sys_enter_write_args {
    unsigned long unused;
    long syscall_nr;
    long fd;
    long buf;
    long count;
};

SEC("tracepoint/syscalls/sys_enter_write")
int handle_tp(struct sys_enter_write_args *ctx)
{
    __u32 pid = bpf_get_current_pid_tgid() >> 32;

    // Retrieve syscall arguments directly
    int fd = ctx->fd;
    char *buf = (char *)ctx->buf;
    __u64 count = (__u64)ctx->count;

    char data[128] = {};
    bpf_probe_read_user(data, sizeof(data) - 1, buf);

    bpf_printk("PID: %u, FD: %d, Data: %s, Count: %lu\n", pid, fd, data, count);

    return 0;
}
