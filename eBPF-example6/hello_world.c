#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>

SEC("kprobe/__x64_sys_execve")
int hello_world(struct pt_regs *ctx) {
    int pid = bpf_get_current_pid_tgid() >> 32;
    char comm[16] = {};

    // Get the name of the current command
    bpf_get_current_comm(comm, sizeof(comm));

    // Print the process ID and command name
    bpf_printk("PID: %d executed command: %s\n", pid, comm);

    return 0;
}

char LICENSE[] SEC("license") = "Dual BSD/GPL";
