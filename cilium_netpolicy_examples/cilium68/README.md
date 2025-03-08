### **CiliumNetworkPolicy: Cross-Cluster Communication**  
This **CiliumNetworkPolicy** enables **cross-cluster** communication by allowing traffic from **x-wing (in cluster1)** to reach **rebel-base (in cluster2)**.

---

## **Policy Breakdown**
```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "allow-cross-cluster"
  description: "Allow x-wing in cluster1 to contact rebel-base in cluster2"
spec:
  endpointSelector:
    matchLabels:
      name: x-wing
      io.cilium.k8s.policy.cluster: cluster1
  egress:
  - toEndpoints:
    - matchLabels:
        name: rebel-base
        io.kubernetes.pod.namespace: default
        io.cilium.k8s.policy.cluster: cluster2
```

---

## **Explanation**
1. **Applies to Pods with `name: x-wing` in `cluster1`**
   - The `endpointSelector` ensures that **this rule applies only to** pods labeled:
     - `name: x-wing`
     - `io.cilium.k8s.policy.cluster: cluster1` (ensuring it applies only to cluster1)

2. **Allows Outbound (Egress) Traffic to `rebel-base` in `cluster2`**
   - The `egress` rule allows `x-wing` to communicate **only with** pods that match:
     - `name: rebel-base`
     - `io.kubernetes.pod.namespace: default` (ensuring it is in the `default` namespace)
     - `io.cilium.k8s.policy.cluster: cluster2` (ensuring it's in cluster2)

---

## **What This Means**
✅ **Allows cross-cluster communication** between `x-wing` in **cluster1** and `rebel-base` in **cluster2**.  
✅ **Traffic is explicitly allowed only to `rebel-base`**; other destinations remain blocked.  
✅ **Namespace & cluster-level security** ensures policies apply correctly across different clusters.  

---

## **Use Case**
This policy is useful for **multi-cluster Kubernetes deployments** where specific services in one cluster need to talk to services in another. For example:
- **Microservices spanning multiple clusters** (e.g., a frontend in cluster1 calling an API in cluster2).
- **Federated Kubernetes clusters** needing **controlled** cross-cluster communication.
- **Enforcing security & isolation** while still allowing necessary traffic.