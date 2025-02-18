 If your Linux distribution (e.g. Ubuntu) does not have the tracing subsystem enabled by default, you may not see any output. Use the following command to enable this feature:

$ sudo su
# echo 1 > /sys/kernel/debug/tracing/tracing_on

sudo cat /sys/kernel/debug/tracing/trace_pipe | grep "BPF triggered sys_enter_write"


bpf_trace_printk: This is the message that was printed by your eBPF program via bpf_printk().
sys_enter_write: Indicates the specific tracepoint that was triggered – in this case, the system call write was called.
PID 1458594: The process ID of the program that triggered the event. This could be any process that performs a write operation, such as echo, your terminal program, etc.
What Does This Mean?
It means your eBPF program is correctly hooked into the kernel and is logging the sys_enter_write events triggered by the kernel. The output from the tracepoint confirms that the write() system call (via the sys_enter_write tracepoint) was intercepted by your eBPF program, and it's printing the message that your program triggered.

