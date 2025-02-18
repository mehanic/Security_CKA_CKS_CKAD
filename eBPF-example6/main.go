package main

import (
	"C"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/cilium/ebpf"
	"github.com/cilium/ebpf/link"
	"github.com/cilium/ebpf/rlimit"
)

//go:generate go run github.com/cilium/ebpf/cmd/bpf2go ebpf hello_world.c

func main() {
	if err := rlimit.RemoveMemlock(); err != nil {
		log.Fatalf("failed to remove memlock: %v", err)
	}

	objs := struct {
		HelloWorld *ebpf.Program `ebpf:"hello_world"`
	}{}
	if err := loadObjects(&objs); err != nil {
		log.Fatalf("loading objects: %v", err)
	}
	defer objs.HelloWorld.Close()

	kp, err := link.Kprobe("__x64_sys_execve", objs.HelloWorld, nil)
	if err != nil {
		log.Fatalf("attaching kprobe: %v", err)
	}
	defer kp.Close()

	log.Println("Waiting for execve syscalls...")

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)
	<-stop
}

func loadObjects(objs interface{}) error {
	spec, err := ebpf.LoadCollectionSpec("ebpf_bpfel.o")
	if err != nil {
		return err
	}
	return spec.LoadAndAssign(objs, nil)
}
