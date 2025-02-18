package main
import "C"
import (
	"bytes"
	"fmt"
	"log"
	"os"

	"github.com/cilium/ebpf"
	"github.com/cilium/ebpf/link"
	"github.com/cilium/ebpf/perf"
)

//go:generate go run github.com/cilium/ebpf/cmd/bpf2go ebpf bpf_program.c

func main() {
	// Load the compiled BPF program
	bpfObj, err := os.ReadFile("./ebpf_bpfel.o") // Correct file for little-endian systems
	if err != nil {
		log.Fatalf("Failed to read BPF program: %v", err)
	}

	// Load the BPF object file into a collection
	spec, err := ebpf.LoadCollectionSpecFromReader(bytes.NewReader(bpfObj))
	if err != nil {
		log.Fatalf("Failed to load BPF object: %v", err)
	}

	// Load the collection (programs + maps)
	coll, err := ebpf.NewCollection(spec)
	if err != nil {
		log.Fatalf("Failed to create BPF collection: %v", err)
	}
	defer coll.Close()

	// Retrieve the handle_tp program
	prog := coll.Programs["handle_tp"]
	if prog == nil {
		log.Fatalf("Failed to find handle_tp program")
	}

	// Attach the program to the syscalls tracepoint for sys_enter_write
	tp, err := link.Tracepoint("syscalls", "sys_enter_write", prog, nil)
	if err != nil {
		log.Fatalf("Failed to attach eBPF program to tracepoint: %v", err)
	}
	defer tp.Close()

	// Retrieve the map named "map_name"
	mapObj := coll.Maps["map_name"]
	if mapObj == nil {
		log.Fatalf("Failed to find map_name map")
	}

	// Create a perf reader for the map
	perfReader, err := perf.NewReader(mapObj, os.Getpagesize())
	if err != nil {
		log.Fatalf("Failed to create perf reader: %v", err)
	}
	defer perfReader.Close()

	// Listen for events from the BPF program
	for {
		record, err := perfReader.Read()
		if err != nil {
			log.Fatalf("Failed to read perf record: %v", err)
		}
		fmt.Printf("Perf Record: %+v\n", record)
	}
}


// ebpf_bpfel.o (for little-endian machines)
// ebpf_bpfeb.o (for big-endian machines)
// Since you're likely on a little-endian machine (like x86_64 or ARM64), you should use: ebpf_bpfel.o