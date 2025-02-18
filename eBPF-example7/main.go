package main

import (
	"C"
	"fmt"
	"log"
	"net"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/cilium/ebpf/link"
	"github.com/cilium/ebpf/rlimit"
)

//go:generate go run github.com/cilium/ebpf/cmd/bpf2go ebpf xdp_program.c

func main() {
	// Allow BPF to lock memory
	if err := rlimit.RemoveMemlock(); err != nil {
		log.Fatalf("failed to remove memlock: %v", err)
	}

	// Load the eBPF program
	objs := ebpfObjects{}
	if err := loadEbpfObjects(&objs, nil); err != nil {
		log.Fatalf("loading objects: %v", err)
	}
	defer objs.Close()

	// Get interface index for eth0
	ifaceName := "enp7s0"
	ifaceIndex, err := net.InterfaceByName(ifaceName)
	if err != nil {
		log.Fatalf("failed to get interface %s: %v", ifaceName, err)
	}

	// Attach the XDP program to the interface
	tp, err := link.AttachXDP(link.XDPOptions{
		Program:   objs.HelloPacket,
		Interface: ifaceIndex.Index,
	})
	if err != nil {
		log.Fatalf("attaching XDP: %v", err)
	}
	defer tp.Close()

	fmt.Printf("Listening for packets on interface %s...\n", ifaceName)

	// Handle termination signals
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)

	// Periodically print packet counts
	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			var key, value uint64
			iter := objs.Packets.Iterate()
			for iter.Next(&key, &value) {
				fmt.Printf("Protocol: %d -> Packets: %d\n", key, value)
			}
		case <-stop:
			fmt.Println("Stopping XDP program...")
			return
		}
	}
}