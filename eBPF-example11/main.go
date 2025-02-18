
package main

import (
	"C"
	"encoding/binary"
	"fmt"
	"log"
	"os"
	"net" 
	"os/signal"
	"syscall"
	"sync"       
	"time"   

	"github.com/cilium/ebpf"
	"github.com/cilium/ebpf/perf"
	"github.com/cilium/ebpf/link"
	"github.com/cilium/ebpf/rlimit"
)
//go:generate go run github.com/cilium/ebpf/cmd/bpf2go ebpf hello_ebpf.c

const pidFilter = 0 // Set to the PID you want to filter on, 0 means no filter

// Define the tracepoint event structure

type event struct {
	TimeSinceBoot  uint64
	ProcessingTime uint32
	Type           uint8
}

func main() {
	// Set up the rlimit to allow loading BPF programs
	if err := rlimit.RemoveMemlock(); err != nil {
		log.Fatalf("Failed to remove memlock rlimit: %v", err)
	}

	// Load the eBPF program
	spec, err := ebpf.LoadCollectionSpec("ebpf_bpfel.o")
	if err != nil {
		log.Fatalf("Failed to load BPF program: %v", err)
	}

	// Create a new BPF collection
	coll, err := ebpf.NewCollection(spec)
	if err != nil {
		log.Fatalf("Failed to create new BPF collection: %v", err)
	}
	defer coll.Close()

	// Get the XDP program
	xdpProg, ok := coll.Programs["xdp_prog"]
	if !ok {
		log.Fatalf("XDP program not found in BPF collection")
	}

	// Attach XDP program to interface
	iface := "enp7s0"
	ifaceIdx, err := net.InterfaceByName(iface)
	if err != nil {
		log.Fatalf("Failed to get interface %s: %v", iface, err)
	}

	lnk, err := link.AttachXDP(link.XDPOptions{
		Program:   xdpProg,
		Interface: ifaceIdx.Index,
	})
	if err != nil {
		log.Fatalf("Failed to attach XDP program: %v", err)
	}
	defer lnk.Close()

	fmt.Println("Successfully loaded BPF programs")

	// Set up perf events
	outputMap, ok := coll.Maps["output_map"]
	if !ok {
		log.Fatalf("No map named 'output_map' found in collection")
	}

	perfEvent, err := perf.NewReader(outputMap, 4096)
	if err != nil {
		log.Fatalf("Failed to create perf event reader: %v", err)
	}
	defer perfEvent.Close()

	// Use a wait group for clean shutdown
	var wg sync.WaitGroup
	stop := make(chan struct{})

	wg.Add(1)
	go func() {
		defer wg.Done()
		for {
			select {
			case <-stop:
				return
			default:
				record, err := perfEvent.Read()
				if err != nil {
					if err.Error() != "perf ringbuffer: file already closed" {
						log.Printf("Error reading perf event: %v", err)
					}
					return
				}

				var e event
				if len(record.RawSample) < 12 {
					log.Println("Invalid sample size")
					continue
				}
				e.TimeSinceBoot = binary.LittleEndian.Uint64(record.RawSample[:8])
				e.ProcessingTime = binary.LittleEndian.Uint32(record.RawSample[8:12])
				e.Type = uint8(record.RawSample[12])

				fmt.Printf("Received event: Type: %d, TimeSinceBoot: %d, ProcessingTime: %d\n",
					e.Type, e.TimeSinceBoot, e.ProcessingTime)
			}
		}
	}()

	// Wait for termination signal
	c := make(chan os.Signal, 1)
	signal.Notify(c, syscall.SIGINT, syscall.SIGTERM)
	<-c

	// Signal the goroutine to stop and wait for it
	close(stop)
	wg.Wait()

	fmt.Println("Exiting cleanly")
	time.Sleep(1 * time.Second) // Allow graceful exit
}

// 1️ -type event
// The -type event flag tells bpf2go to look for a struct event in the C code and generate Go bindings for it.
// 2️ bpf2go Codegen
// This generates files like ebpf_hello_ebpf_bpfel.go, which contains Go representations of your C structs and maps.
// 3️ bpf_printk
// bpf_printk logs messages accessible via:
// bash
// Copy
// Edit
// sudo cat /sys/kernel/debug/tracing/trace



// The two //go:generate directives you provided are similar but differ in a key way. Let’s break them down:

// 1. //go:generate go run github.com/cilium/ebpf/cmd/bpf2go ebpf hello_ebpf.c
// This command tells bpf2go to:

// Generate Go bindings for all of the C code in hello_ebpf.c without specifying a struct type to generate bindings for.

// This means bpf2go will try to generate Go representations for all types and structures in hello_ebpf.c, including maps, structs, and BPF programs.

// What it does:

// It will automatically try to generate Go bindings for every BPF-related object in hello_ebpf.c, such as eBPF maps, programs, and types.
// 2. //go:generate go run github.com/cilium/ebpf/cmd/bpf2go -type event ebpf hello_ebpf.c
// This command is more specific:

// The -type event flag tells bpf2go to only generate Go bindings for the event struct type in hello_ebpf.c.

// What it does:

// It will only generate Go bindings for the event struct, which is the struct you've defined in your C code. This restricts bpf2go to mapping that specific struct to a Go struct.
// The reason you'd use this is if you're only interested in generating Go bindings for a specific struct (in this case, event), and not all C code.
// Key Differences:
// Targeted Binding Generation:

// First Command (ebpf hello_ebpf.c): Generates Go bindings for everything in hello_ebpf.c, which could include all the structs, maps, and programs.
// Second Command (-type event): Only generates Go bindings for the struct event. This means it will ignore other structs, maps, or programs in your C code.
// Use Case:

// First Command: Useful when you want to generate all possible Go bindings for all types in your C code, without specifying a particular type.
// Second Command: Useful when you only want to generate Go bindings for a specific struct (like event) and not other parts of your C code. You can specify other types as well if needed.
