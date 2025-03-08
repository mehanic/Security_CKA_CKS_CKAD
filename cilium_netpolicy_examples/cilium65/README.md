These two **CiliumNetworkPolicy** examples illustrate how to enforce **logical OR and AND** conditions using `matchExpressions` in Kubernetes network policies.

---

## **1. OR Condition (`or-statement-policy`)**
```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "or-statement-policy"
spec:
  endpointSelector: {}
  ingress:
  - fromEndpoints:
    - matchExpressions:
      - key: "k8s:io.kubernetes.pod.namespace"
        operator: "in"
        values:
        - "production"
    - matchExpressions:
      - key: "k8s:cilium.example.com/policy"
        operator: "in"
        values:
        - "strict"
```

### **Explanation**
- The `endpointSelector: {}` applies this rule to **all pods**.
- The `ingress` rule **allows incoming traffic** if the source pod satisfies **either** of these conditions (**OR logic**):
  1. The pod belongs to the **"production"** namespace (`k8s:io.kubernetes.pod.namespace = production`).
  2. The pod has the label `k8s:cilium.example.com/policy=strict`.

Since the `fromEndpoints` section contains **two separate `matchExpressions`**, it means:
- A pod from **either** the `production` namespace **OR** a pod with the label `policy=strict` is allowed.

---

## **2. AND Condition (`and-statement-policy`)**
```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "and-statement-policy"
spec:
  endpointSelector: {}
  ingress:
  - fromEndpoints:
    - matchExpressions:
      - key: "k8s:io.kubernetes.pod.namespace"
        operator: "in"
        values:
        - "production"
      - key: "k8s:cilium.example.com/policy"
        operator: "in"
        values:
        - "strict"
```

### **Explanation**
- Similar to the previous policy, this rule applies to **all pods** (`endpointSelector: {}`).
- The `ingress` rule **only allows traffic** from pods that meet **both conditions** (**AND logic**):
  1. The pod must be in the **"production"** namespace.
  2. The pod must have the label `k8s:cilium.example.com/policy=strict`.

Since both conditions are **inside the same `matchExpressions` block**, **both conditions must be met simultaneously** for a pod to be allowed.

---

## **Key Differences:**
| Policy Type | Condition Type | Allowed Traffic |
|-------------|---------------|----------------|
| **or-statement-policy** | **OR** | Pods from `production` namespace **or** pods with label `policy=strict` |
| **and-statement-policy** | **AND** | Only pods that are in `production` namespace **and** have the label `policy=strict` |

### **Use Cases:**
- Use **OR logic (`or-statement-policy`)** when you want to allow traffic from multiple categories of pods independently.
- Use **AND logic (`and-statement-policy`)** when you need stricter enforcement, ensuring that only a very specific subset of pods can communicate.

These logical conditions help define **fine-grained network security policies** in Kubernetes with Cilium. 🚀