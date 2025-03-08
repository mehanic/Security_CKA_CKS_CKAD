helm repo add cilium https://helm.cilium.io/

helm install cilium cilium/cilium --version 1.10.0 --namespace kube-system --set kubeProxyReplacement=probe

global:
  kubeProxyReplacement: "probe"
  tunnel: "disabled"
  nativeRoutingCIDR: "10.0.0.0/8"
  devices: "eth0"
  encryption:
    enabled: true

helm install cilium cilium/cilium --version 1.10.0 --namespace kube-system -f cilium-values.yaml

go get -u github.com/cilium/ebpf

helm install cilium cilium/cilium --namespace kube-system \
  --set cluster.id=1 \
  --set cluster.name=cluster1 \
  --set global.etcd.enabled=true


cilium clustermesh enable


cilium clustermesh connect --context cluster1 --remote-context cluster2

kubectl exec -it pod-A -- curl http://pod-B.cluster2.svc.cluster.local

hubble observe --namespace kube-system

# Benefits of Cilium Multi-Cluster Networking
# ✔ Low latency and high performance – Uses eBPF for efficient packet processing.
# ✔ Identity-aware security policies – Enforces security across clusters.
# ✔ Scalable and dynamic – Supports large-scale multi-cluster environments.
# ✔ Service mesh integration – Works with or without sidecars (e.g., Istio, Linkerd).
cilium hubble enable
HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
HUBBLE_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then HUBBLE_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
sha256sum --check hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum
sudo tar xzvfC hubble-linux-${HUBBLE_ARCH}.tar.gz /usr/local/bin
rm hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}


cilium hubble port-forward&

hubble status

hubble observe

kubectl exec tiefighter -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing
Ship landed

kubectl exec tiefighter -- curl -s -XPUT deathstar.default.svc.cluster.local/v1/exhaust-port
Access denied

kubectl exec xwing -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing
command terminated with exit code 28

hubble observe --pod deathstar --protocol http

hubble observe --pod deathstar --verdict DROPPED

cilium hubble enable --ui

cilium hubble ui

while true; do cilium connectivity test; done


helm install cilium cilium/cilium --version 1.17.0 \
   --set hubble.enabled=true \
   --set hubble.export.static.enabled=true \
   --set hubble.export.static.filePath=/var/run/cilium/hubble/events.log

kubectl -n kube-system rollout status ds/cilium

kubectl -n kube-system exec ds/cilium -- tail -f /var/run/cilium/hubble/events.log

cilium config delete hubble-export-file-path

hubble observe --verdict DROPPED --verdict ERROR --print-raw-filters

kubectl -n kube-system patch cm cilium-config --patch-file=/dev/stdin <<-EOF
data:
  hubble-export-allowlist: '{"verdict":["DROPPED","ERROR"]}'
EOF

helm upgrade cilium cilium/cilium --version 1.17.0 \
   --set hubble.enabled=true \
   --set hubble.export.static.enabled=true \
   --set hubble.export.static.allowList[0]='{"verdict":["DROPPED","ERROR"]}'

hubble observe --not --namespace kube-system --print-raw-filters

kubectl -n kube-system patch cm cilium-config --patch-file=/dev/stdin <<-EOF
data:
  hubble-export-denylist: '{"source_pod":["kube-system/"]},{"destination_pod":["kube-system/"]}'
EOF

helm upgrade cilium cilium/cilium --version 1.17.0 \
   --set hubble.enabled=true \
   --set hubble.export.static.enabled=true \
   --set hubble.export.static.filePath=/var/run/cilium/hubble/events.log \
   --set hubble.export.static.allowList[0]='{"verdict":["DROPPED","ERROR"]}'
   --set hubble.export.static.denyList[0]='{"source_pod":["kube-system/"]}' \
   --set hubble.export.static.denyList[1]='{"destination_pod":["kube-system/"]}' \
   --set "hubble.export.static.fieldMask={time,source.namespace,source.pod_name,destination.namespace,destination.pod_name,l4,IP,node_name,is_reply,verdict,drop_reason_desc}"

kubectl -n kube-system exec ds/cilium -- tail -f /var/run/cilium/hubble/events.log

helm upgrade cilium cilium/cilium --version 1.17.0 \
   --set hubble.enabled=true \
   --set hubble.export.dynamic.enabled=true \
   --set hubble.export.dynamic.config.content[0].name=system \
   --set hubble.export.dynamic.config.content[0].filePath=/var/run/cilium/hubble/events-system.log \
   --set hubble.export.dynamic.config.content[0].includeFilters[0].source_pod[0]='kube_system/' \
   --set hubble.export.dynamic.config.content[0].includeFilters[1].destination_pod[0]='kube_system/'

  kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/1.17.0/examples/kubernetes/addons/prometheus/monitoring-example.yaml


  helm install cilium cilium/cilium --version 1.17.0 \
   --namespace kube-system \
   --set prometheus.enabled=true \
   --set operator.prometheus.enabled=true \
   --set hubble.enabled=true \
   --set hubble.metrics.enableOpenMetrics=true \
   --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip\,source_namespace\,source_workload\,destination_ip\,destination_namespace\,destination_workload\,traffic_direction}"

   kubectl -n cilium-monitoring port-forward service/grafana --address 0.0.0.0 --address :: 3000:3000

   kubectl -n cilium-monitoring port-forward service/prometheus --address 0.0.0.0 --address :: 9090:9090

   helm install cilium cilium/cilium --version 1.17.0 \
  --namespace kube-system \
  --set clustermesh.useAPIServer=true \
  --set clustermesh.apiserver.metrics.enabled=true \
  --set clustermesh.apiserver.metrics.kvstoremesh.enabled=true \
  --set clustermesh.apiserver.metrics.etcd.enabled=true

helm install cilium cilium/cilium --version 1.17.0 \
  --namespace kube-system \
  --set prometheus.enabled=true \
  --set operator.prometheus.enabled=true \
  --set hubble.enabled=true \
  --set hubble.metrics.enableOpenMetrics=true \
  --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip\,source_namespace\,source_workload\,destination_ip\,destination_namespace\,destination_workload\,traffic_direction}"

mount | grep /sys/fs/bpf


helm template cilium/cilium --version 1.17.0 \
  --namespace=kube-system \
  --set preflight.enabled=true \
  --set agent=false \
  --set operator.enabled=false \
  > cilium-preflight.yaml
kubectl create -f cilium-preflight.yaml


kubectl get daemonset -n kube-system | sed -n '1p;/cilium/p'

kubectl get deployment -n kube-system cilium-pre-flight-check -w


