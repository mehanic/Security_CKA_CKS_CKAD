sudo ./bpf_program
echo "hello pppppffg" > testfile.txt
sudo cat /sys/kernel/debug/tracing/trace_pipe  | grep testfile.txt

  bash-551601  [011] ...21 159569.575214: bpf_trace_printk: PID: 551601, FD: 2, Data:[Co "hello pppppffg" > testfile.txtnic (79.254.26.113) [No SSH] [No VPN] [🔹 no_active_playbook] [ansible_core:2.17.8, Count: 1
            bash-551601  [001] ...21 159571.503320: bpf_trace_printk: PID: 551601, FD: 2, Data:[Co "hello pppppffg" > testfile.txtnic (79.254.26.113) [No SSH] [No VPN] [🔹 no_active_playbook] [ansible_core:2.17.8, Count: 1
            bash-551601  [001] ...21 159572.350953: bpf_trace_printk: PID: 551601, FD: 2, Data:[Co "hello pppppffg" > testfile.txtnic (79.254.26.113) [No SSH] [No VPN] [🔹 no_active_playbook] [ansible_core:2.17.8, Count: 1
            bash-551601  [001] ...21 159572.798874: bpf_trace_printk: PID: 551601, FD: 2, Data:[Co "hello pppppffg" > testfile.txtnic (79.254.26.113) [No SSH] [No VPN] [🔹 no_active_playbook] [ansible_core:2.17.8, Count: 1
            bash-551601  [001] ...21 159573.186816: bpf_trace_printk: PID: 551601, FD: 2, Data:[Co "hello pppppffg" > testfile.txtnic (79.254.26.113) [No SSH] [No VPN] [🔹 no_active_playbook] [ansible_core:2.17.8, Count: 1
            bash-551601  [001] ...21 159574.047022: bpf_trace_printk: PID: 551601, FD: 2, Data:[Co "hello pppppffg" > testfile.txtnic (79.254.26.113) [No SSH] [No VPN] [🔹 no_active_playbook] [ansible_core:2.17.8, Count: 1
            bash-551601  [001] ...21 159574.446997: bpf_trace_printk: PID: 551601, FD: 2, Data:[Co "hello pppppffg" > testfile.txtnic (79.254.26.113) [No SSH] [No VPN] [🔹 no_active_playbook] [ansible_core:2.17.8, Count: 1


I move coursor only