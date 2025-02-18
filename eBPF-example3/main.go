package main

// #cgo CFLAGS: -I${SRCDIR}/include
// #cgo LDFLAGS: -L${SRCDIR}/lib -lbpf
// #include <bpf/libbpf.h>
import "C"

import (
	"log"
	"os"
	"os/signal"

	"github.com/cilium/ebpf/link"
	"github.com/cilium/ebpf/rlimit"
)

//go:generate go run github.com/cilium/ebpf/cmd/bpf2go myebpf program.c

func main() {
	// Remove memory limits for eBPF maps
	if err := rlimit.RemoveMemlock(); err != nil {
		log.Fatalf("failed to remove memlock: %v", err)
	}

	// Load pre-compiled eBPF program
	objs := myebpfObjects{}
	if err := loadMyebpfObjects(&objs, nil); err != nil {
		log.Fatalf("loading eBPF objects: %v", err)
	}
	defer objs.Close()

	// Attach eBPF program to syscall write tracepoint
	tp, err := link.Tracepoint("syscalls", "sys_enter_write", objs.HandleTp, nil)
	if err != nil {
		log.Fatalf("failed to attach tracepoint: %v", err)
	}
	defer tp.Close()

	log.Println("Attached eBPF program, waiting for sys_enter_write events...")

	// Handle termination signals
	stopper := make(chan os.Signal, 1)
	signal.Notify(stopper, os.Interrupt)
	<-stopper

	log.Println("Received signal, exiting...")
}
