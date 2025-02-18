package main

import (
	"C"
	"encoding/binary"
	"fmt"
	"net"
	"os"
	"os/exec"
	"os/signal"
	"syscall"

	"github.com/cilium/ebpf"
	"github.com/cilium/ebpf/link"
	"github.com/cilium/ebpf/perf"
)

const (
	TYPE_ENTER = 1
	TYPE_DROP  = 2
	TYPE_PASS  = 3
)

const ringBufferSize = 128
type ringBuffer struct {
	data   [ringBufferSize]uint32
	start  int
	pointer int
	filled bool
}

func (rb *ringBuffer) add(val uint32) {
	if rb.pointer < ringBufferSize {
		rb.pointer++
	} else {
		rb.filled = true
		rb.pointer = 1
	}
	rb.data[rb.pointer-1] = val
}

func (rb *ringBuffer) avg() float32 {
	if rb.pointer == 0 {
		return 0
	}
	sum := uint32(0)
	for _, val := range rb.data {
		sum += val
	}
	if rb.filled {
		return float32(sum) / float32(ringBufferSize)
	}
	return float32(sum) / float32(rb.pointer)
}

func compileBPF() error {
	cmd := exec.Command("clang", "-target", "bpf", "-O2", "-g", "-Wall", "-c", "xdp_dilih.c", "-o", "xdp_dilih.o")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func main() {
	err := compileBPF()
	if err != nil {
		panic(fmt.Sprintf("Failed to compile BPF C program: %v", err))
	}

	spec, err := ebpf.LoadCollectionSpec("xdp_dilih.o")
	if err != nil {
		panic(err)
	}

	coll, err := ebpf.NewCollection(spec)
	if err != nil {
		panic(fmt.Sprintf("Failed to create new collection: %v\n", err))
	}
	defer coll.Close()

	prog := coll.Programs["xdp_dilih"]
	if prog == nil {
		panic("No program named 'xdp_dilih' found in collection")
	}

	iface := os.Getenv("INTERFACE")
	if iface == "" {
		panic("No interface specified. Please set the INTERFACE environment variable to the name of the interface to be used")
	}
	iface_idx, err := net.InterfaceByName(iface)
	if err != nil {
		panic(fmt.Sprintf("Failed to get interface %s: %v\n", iface, err))
	}

	opts := link.XDPOptions{
		Program:   prog,
		Interface: iface_idx.Index,
	}
	lnk, err := link.AttachXDP(opts)
	if err != nil {
		panic(err)
	}
	defer lnk.Close()

	fmt.Println("Successfully loaded and attached BPF program.")

	outputMap, ok := coll.Maps["output_map"]
	if !ok {
		panic("No map named 'output_map' found in collection")
	}

	perfEvent, err := perf.NewReader(outputMap, 4096)
	if err != nil {
		panic(fmt.Sprintf("Failed to create perf event reader: %v\n", err))
	}
	defer perfEvent.Close()

	// In the Go code, ensure you're reading 4 bytes from the perf event
	go func() {
		for {
			record, err := perfEvent.Read()
			if err != nil {
				fmt.Println(err)
				continue
			}

			// Check if the RawSample has at least 4 bytes (since we're sending only 4 bytes)
			if len(record.RawSample) < 4 {
				fmt.Println("Invalid sample size")
				continue
			}

			// Read the 4-byte processing time from the event
			processingTime := binary.LittleEndian.Uint32(record.RawSample[:4])

			// Handle the event type as needed
			fmt.Print("\033[H\033[2J")
			fmt.Printf("Processing time: %d ns\n", processingTime)
		}
	}()

	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
	<-c
}

//export INTERFACE="enp7s0"
//sudo -E ./example9