package main

import "C"
import (
	"fmt"
	"log"
	"os"
	"os/signal"

	"github.com/cilium/ebpf"
	"github.com/cilium/ebpf/link"
	"github.com/cilium/ebpf/rlimit"
)

//go:generate go run github.com/cilium/ebpf/cmd/bpf2go ebpf program.c

// Define a struct for holding eBPF objects
type myebpfObjects struct {
	HandleTp *ebpf.Program `ebpf:"handle_tp"`
}

func loadMyebpfObjects(objs *myebpfObjects) error {
	// Open the eBPF object file and load it into memory
	coll, err := ebpf.LoadCollection("ebpf_bpfel.o")
	if err != nil {
		return err
	}

	// Load the handle_tp program from the collection
	if prog, ok := coll.Programs["handle_tp"]; ok {
		objs.HandleTp = prog
	} else {
		return fmt.Errorf("handle_tp program not found in the collection")
	}

	return nil
}

func main() {
	// Remove memory limits for eBPF maps
	if err := rlimit.RemoveMemlock(); err != nil {
		log.Fatalf("failed to remove memlock: %v", err)
	}

	// Load pre-compiled eBPF program
	objs := myebpfObjects{}
	if err := loadMyebpfObjects(&objs); err != nil {
		log.Fatalf("loading eBPF objects: %v", err)
	}
	defer objs.HandleTp.Close()

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
