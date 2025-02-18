package main

import (
	"C"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/cilium/ebpf"
	"github.com/cilium/ebpf/link"
)

//go:generate clang -target bpf -g -O2 -Wall -Werror -D__TARGET_ARCH_x86 -mcpu=v3 -c file.c -o unlinkat.bpf.o

// Paths
const bpfObjPath = "unlinkat.bpf.o"

func main() {
	// Load the eBPF program from the compiled object file
	spec, err := ebpf.LoadCollectionSpec(bpfObjPath)
	if err != nil {
		log.Fatalf("Failed to load eBPF spec: %v", err)
	}

	// Load the collection into the kernel
	coll, err := ebpf.NewCollection(spec)
	if err != nil {
		log.Fatalf("Failed to create eBPF collection: %v", err)
	}
	defer coll.Close()

	// Print all programs in the collection to debug
	for name := range coll.Programs {
		fmt.Println("Program found:", name)
	}

	// Retrieve the correct program names from the collection
	kprobe, ok := coll.Programs["handle_do_unlinkat"]
	if !ok {
		log.Fatalf("Failed to find kprobe program")
	}
	kretprobe, ok := coll.Programs["handle_do_unlinkat_exit"]
	if !ok {
		log.Fatalf("Failed to find kretprobe program")
	}

	// Attach the kprobe to the entry of do_unlinkat
	entryLink, err := link.Kprobe("do_unlinkat", kprobe, nil)
	if err != nil {
		log.Fatalf("Failed to attach kprobe: %v", err)
	}
	defer entryLink.Close()

	// Attach the kretprobe to the exit of do_unlinkat
	exitLink, err := link.Kretprobe("do_unlinkat", kretprobe, nil)
	if err != nil {
		log.Fatalf("Failed to attach kretprobe: %v", err)
	}
	defer exitLink.Close()

	fmt.Println("eBPF program loaded and running... Press Ctrl+C to exit.")

	// Handle termination signals gracefully
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)
	<-sigChan

	fmt.Println("\nShutting down...")

	// Sleep briefly to allow any final logs to print
	time.Sleep(1 * time.Second)
}
