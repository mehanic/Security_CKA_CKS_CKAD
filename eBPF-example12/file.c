#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>
#include <bpf/bpf_core_read.h>

char LICENSE[] SEC("license") = "Dual BSD/GPL";

// Kprobe for do_unlinkat
SEC("kprobe/do_unlinkat")
int handle_do_unlinkat(struct pt_regs *ctx) {
    pid_t pid = bpf_get_current_pid_tgid() >> 32;
    struct filename *name_ptr;
    const char *filename;

    // Read the second argument (filename) from the stack
    bpf_probe_read(&name_ptr, sizeof(name_ptr), (void *)(ctx->sp + 16));
    if (name_ptr && bpf_probe_read_user(&filename, sizeof(filename), &name_ptr->name) == 0) {
        bpf_printk("KPROBE ENTRY: PID=%d, filename=%s\n", pid, filename);
    } else {
        bpf_printk("KPROBE ENTRY: PID=%d, failed to read filename\n", pid);
    }

    return 0;
}

// Kretprobe for do_unlinkat
SEC("kretprobe/do_unlinkat")
int handle_do_unlinkat_exit(struct pt_regs *ctx) {
    pid_t pid = bpf_get_current_pid_tgid() >> 32;
    long ret;

    // Read the return value
    bpf_probe_read(&ret, sizeof(ret), (void *)(ctx->sp + 8));
    bpf_printk("KPROBE EXIT: PID=%d, ret=%ld\n", pid, ret);

    return 0;
}
