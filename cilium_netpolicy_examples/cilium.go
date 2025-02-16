package main

import (
    "github.com/cilium/ebpf"
    "github.com/cilium/ebpf/link"
)
//Load an eBPF program from a C file:
func main() {
    // Load the eBPF program from a C file
    spec, err := ebpf.LoadCollectionSpec("path/to/your/ebpf_program.c")
    if err != nil {
        panic(err)
    }

    // Compile the eBPF program
    coll, err := ebpf.NewCollection(spec)
    if err != nil {
        panic(err)
    }
    defer coll.Close()
}

//Attach the eBPF program to a network interface:

package main

import (
    "github.com/cilium/ebpf"
    "github.com/cilium/ebpf/link"
)

func main() {
    // Load and compile the eBPF program (see previous step)

    // Attach the eBPF program to a network interface
    iface, err := net.InterfaceByName("eth0")
    if err != nil {
        panic(err)
    }

    xdp, opts := link.XDPAttachOptions{}
    prog := coll.Programs["my_xdp_program"] // Replace "my_xdp_program" with the name of your eBPF program
    if prog == nil {
        panic("Failed to find eBPF program")
    }

    xdp, err := link.AttachXDP(*iface, prog, &opts)
    if err != nil {
        panic(err)
    }
    defer xdp.Remove()

    // Use the eBPF program as needed
}

#Interact with eBPF maps:

package main

import (
    "github.com/cilium/ebpf"
)

func main() {
    // Load and compile the eBPF program (see previous steps)

    // Access eBPF maps from the compiled program
    myMap := coll.Maps["my_map"] // Replace "my_map" with the name of your eBPF map
    if myMap == nil {
        panic("Failed to find eBPF map")
    }

    // Interact with the eBPF map (e.g., insert, delete, or lookup elements)
    key := uint32(1)
    value := uint64(42)

    if err := myMap.Put(key, value); err != nil {
        panic(err)
    }

    var retrievedValue uint64
    if found, err := myMap.Lookup(key, &retrievedValue); err != nil {
        panic(err)
    } else if !found {
        panic("Key not found in eBPF map")
    }
}

