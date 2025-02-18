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
	"github.com/cilium/ebpf/rlimit"
)

//go:generate go run github.com/cilium/ebpf/cmd/bpf2go ebpf clone_counter.c

func main() {
	// Remove memory limits for BPF programs
	if err := rlimit.RemoveMemlock(); err != nil {
		log.Fatalf("failed to remove memlock: %v", err)
	}

	// Load the BPF object file
	coll, err := ebpf.LoadCollection("ebpf_bpfel.o")
	if err != nil {
		log.Fatalf("loading objects: %v", err)
	}
	defer coll.Close()

	// Extract the HelloWorld program and Clones map from the loaded collection
	helloWorldProg := coll.Programs["hello_world"]
	if helloWorldProg == nil {
		log.Fatal("failed to find hello_world program in collection")
	}
	defer helloWorldProg.Close()

	clonesMap := coll.Maps["clones"]
	if clonesMap == nil {
		log.Fatal("failed to find clones map in collection")
	}
	defer clonesMap.Close()

	// Attach the kprobe to the sys_clone syscall
	kp, err := link.Kprobe("sys_clone", helloWorldProg, nil)
	if err != nil {
		log.Fatalf("attaching kprobe: %v", err)
	}
	defer kp.Close()

	// Monitor clone syscalls
	fmt.Println("Monitoring clone syscalls...")
	ticker := time.NewTicker(2 * time.Second)
	defer ticker.Stop()

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)

	for {
		select {
		case <-ticker.C:
			var uid, count uint64
			iter := clonesMap.Iterate()
			for iter.Next(&uid, &count) {
				fmt.Printf("UID %d: %d clones\n", uid, count)
			}
		case <-stop:
			fmt.Println("Exiting...")
			return
		}
	}
}
