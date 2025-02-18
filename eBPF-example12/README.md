llvm-objdump -t unlinkat.bpf.o | grep probe
0000000000000000 l    d  kprobe/do_unlinkat	0000000000000000 kprobe/do_unlinkat
00000000000000d0 l       kprobe/do_unlinkat	0000000000000000 LBB0_3
00000000000000f8 l       kprobe/do_unlinkat	0000000000000000 LBB0_4
0000000000000000 l    d  kretprobe/do_unlinkat	0000000000000000 kretprobe/do_unlinkat
0000000000000000 g     F kprobe/do_unlinkat	0000000000000108 handle_do_unlinkat
0000000000000000 g     F kretprobe/do_unlinkat	0000000000000090 handle_do_unlinkat_exit


Explanation of the Columns:
Address (e.g., 0000000000000000): This is the memory address of the symbol.

Type (e.g., l, d, g):

l (local symbol): The symbol is only used inside the object file.
d (defined symbol): The symbol is defined in this object.
g (global symbol): The symbol is globally available and can be used in other object files or linked programs.
F indicates that this is a function symbol.
Size (e.g., 0000000000000000): The size of the symbol. In most cases, the size will be 0 for kprobe and kretprobe since these are probe points rather than data or code segments.

Symbol Name (e.g., kprobe/do_unlinkat, handle_do_unlinkat): This is the name of the symbol. This is where the actual kprobe and kretprobe are defined or referred to.

Function Location (for function symbols): For symbols of type F (functions), the function's address is shown (e.g., handle_do_unlinkat at address 0x108).

Key Symbols in the Output:
kprobe/do_unlinkat and kretprobe/do_unlinkat are the probe points you are defining for the function do_unlinkat. These are essentially entry and exit points of the do_unlinkat function in the kernel.

handle_do_unlinkat and handle_do_unlinkat_exit are the functions that handle the actual logic when the kprobe and kretprobe are triggered. These are the names of your BPF programs that will be attached to these probes.

How to Use This Information:
Kprobe and Kretprobe:

Kprobe is a mechanism to attach to a specific function entry point in the kernel (in this case, do_unlinkat), and Kretprobe is used to attach to the exit point of the same function.
Attach the Kprobes to the Kernel: To use these probes, you would typically attach them to the kernel using a BPF library (e.g., bpf or cilium/ebpf in Go) or manually via the bpf() system call. This is done in the Go code (as shown in your earlier example) where the kprobe and kretprobe programs are attached to the do_unlinkat function.

Map the Functions to the Probes:

handle_do_unlinkat: This function is mapped to the kprobe/do_unlinkat entry probe. When do_unlinkat is called in the kernel, this function will execute.
handle_do_unlinkat_exit: This function is mapped to the kretprobe/do_unlinkat exit probe. When do_unlinkat finishes executing, this function will be triggered.