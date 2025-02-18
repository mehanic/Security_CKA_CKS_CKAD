#define BPF_NO_GLOBAL_DATA
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>

typedef unsigned int u32;
typedef int pid_t;
const pid_t pid_filter = 0;

char LICENSE[] SEC("license") = "Dual BSD/GPL";

SEC("tp/syscalls/sys_enter_write")
int handle_tp(void *ctx)
{
    pid_t pid = bpf_get_current_pid_tgid() >> 32;
    if (pid_filter && pid != pid_filter)
        return 0;

    bpf_printk("BPF triggered sys_enter_write from PID %d.\n", pid);
    return 0;
}


// Explanation of Each Line
// // #cgo CFLAGS: -I${SRCDIR}/include

// Tells the compiler to look for C headers in ./include relative to your Go source files.
// Needed for libbpf.h and other headers.
// // #cgo LDFLAGS: -L${SRCDIR}/lib -lbpf

// -L${SRCDIR}/lib → Looks for the libbpf.so file in the ./lib directory.
// -lbpf → Links the libbpf library with your Go application.
// #include <bpf/libbpf.h>

// Imports the libbpf C header for eBPF program manipulation.
