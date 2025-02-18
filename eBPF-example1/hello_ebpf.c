// +build ignore

#include "vmlinux.h"
#include <bpf/bpf_helpers.h>

#define TASK_COMM_SIZE 100

char __license[] SEC("license") = "Dual MIT/GPL";
// Define an event structure
struct event {
    u32 pid;
    u8  comm[TASK_COMM_SIZE];
};
// Define a ring buffer map for transferring data to user space
struct {
	__uint(type, BPF_MAP_TYPE_RINGBUF);
	__uint(max_entries, 1 << 24);
} events SEC(".maps");

// Force emitting struct event into the ELF.  Declare an unused variable to emit the struct into the ELF
const struct event *unused __attribute__((unused));
// eBPF program triggered on sys_execve
SEC("kprobe/sys_execve")
int hello_execve(struct pt_regs *ctx) {
    // Get the current process ID (PID) and thread ID (TID)
    u64 id = bpf_get_current_pid_tgid();
    pid_t pid = id >> 32;
    pid_t tid = (u32)id;
     // Only log if PID == TID (main thread)
    if (pid != tid)
        return 0;
  // Allocate memory for an event
    struct event *e;

	e = bpf_ringbuf_reserve(&events, sizeof(struct event), 0);
	if (!e) {
		return 0;
	}
// Populate the event structure
	e->pid = pid;
	bpf_get_current_comm(&e->comm, TASK_COMM_SIZE);

// Submit the event to the ring buffer
	bpf_ringbuf_submit(e, 0);

	return 0;
}


// 1.Hooking sys_execve:
// The program attaches to the kprobe for the sys_execve function (executes new processes).
// 2.Event Allocation:
// Allocates a struct event from the ringbuf.
// 3.Data Collection:
// Fills comm with the command name and pid with the process ID.
// 4.Ring Buffer Submission:
// The event is sent to user space.