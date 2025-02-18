#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>

#define TYPE_ENTER 1
#define TYPE_DROP 2
#define TYPE_PASS 3

// Only keep processing time
struct {
    __uint(type, BPF_MAP_TYPE_PERF_EVENT_ARRAY);
    __uint(key_size, sizeof(int));
    __uint(value_size, sizeof(__u32));  // 4 bytes for processing_time_ns
    __uint(max_entries, 1024);
} output_map SEC(".maps");

SEC("xdp")
int xdp_dilih(struct xdp_md *ctx)
{
    __u32 processing_time_ns = 0;
    __u64 timestamp = bpf_ktime_get_ns();

    // Type 1: Enter event
    processing_time_ns = 0;
    bpf_perf_event_output(ctx, &output_map, BPF_F_CURRENT_CPU, &processing_time_ns, sizeof(processing_time_ns));

    if (bpf_get_prandom_u32() % 2 == 0) {
        // Type 2: Drop event
        __u64 ts = bpf_ktime_get_ns();
        processing_time_ns = ts - timestamp;
        bpf_perf_event_output(ctx, &output_map, BPF_F_CURRENT_CPU, &processing_time_ns, sizeof(processing_time_ns));
        bpf_printk("dropping packet");
        return XDP_DROP;
    }

    // Type 3: Pass event
    __u64 ts = bpf_ktime_get_ns();
    processing_time_ns = ts - timestamp;
    bpf_perf_event_output(ctx, &output_map, BPF_F_CURRENT_CPU, &processing_time_ns, sizeof(processing_time_ns));
    bpf_printk("passing packet");
    return XDP_PASS;
}

char _license[] SEC("license") = "GPL";
