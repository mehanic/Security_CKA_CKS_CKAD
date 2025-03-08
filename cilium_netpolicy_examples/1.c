// Простой пример фильтра на eBPF, который логирует HTTP-трафик:

// #include 
// #include 
// #include 

// int log_http(struct __sk_buff *skb) {
//     char msg[] = "HTTP request detected\n";
//     bpf_trace_printk(msg, sizeof(msg));
//     return 0;
// }


// // Компилируем и загружаем:

// // ebpf-loader -o http_filter.o -s log_http.c
// // Загружаем программу через Cilium:

// // cilium bpf install http_filter.o
// // Теперь каждый HTTP-запрос будет логироваться на уровне ядра.

// // Фильтрация по IP
// // Добавим фильтр, который блокирует трафик с определённого IP-адреса:

// #include 
// #include 
// #include 

// int block_ip(struct __sk_buff *skb) {
//     struct iphdr *ip = bpf_hdr_pointer(skb);
//     if (ip-&gt;saddr == htonl(0xC0A80001)) { // 192.168.0.1
//         return TC_ACT_SHOT; // Drop packet
//     }
//     return TC_ACT_OK;
// }
// // Загружаем этот фильтр аналогично:

// // ebpf-loader -o block_ip.o -s block_ip.c
// // cilium bpf install block_ip.o
// // Теперь пакеты с заданного IP-адреса будут блокироваться.