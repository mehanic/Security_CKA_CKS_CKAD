#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>

// Define a hash map to store the clone counts by UID
struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __type(key, __u64);
    __type(value, __u64);
    __uint(max_entries, 1024);
} clones SEC(".maps");

// This is the kprobe handler for sys_clone
SEC("kprobe/sys_clone")
int hello_world(struct pt_regs *ctx) {
    __u64 uid = bpf_get_current_uid_gid() & 0xFFFFFFFF;  // Extract the UID
    __u64 counter = 0;

    // Look for the existing counter for this UID
    __u64 *p = bpf_map_lookup_elem(&clones, &uid);
    if (p) {
        counter = *p;
    }

    // Increment the counter for this UID
    counter++;
    bpf_map_update_elem(&clones, &uid, &counter, BPF_ANY);  // Store the updated count

    return 0;
}

// License declaration
char LICENSE[] SEC("license") = "Dual BSD/GPL";
