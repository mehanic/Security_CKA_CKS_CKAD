### **Cilium Network Policy: `l7-visibility`**  

This **CiliumNetworkPolicy** enforces **Layer 7 (L7) visibility and control** on **egress (outgoing) traffic** for pods in the `default` namespace.

---

## **Policy Breakdown**
```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "l7-visibility"
spec:
  endpointSelector:
    matchLabels:
      "k8s:io.kubernetes.pod.namespace": default
```
- **Applies to:** All pods in the **`default` namespace**.  
- **Effect:** Controls outgoing (egress) traffic.

---

## **1️⃣ Allows All DNS Traffic**
```yaml
  - toPorts:
    - ports:
      - port: "53"
        protocol: ANY
      rules:
        dns:
        - matchPattern: "*"
```
✅ **Allows DNS queries** (port **53**) for **ANY protocol** (UDP or TCP).  
✅ **Permits DNS resolution for all domains (`*`).**  
💡 **Reason:** Required for pods to resolve domain names (e.g., `google.com` or `api.example.com`).

---

## **2️⃣ Allows HTTP(S) Egress to Other Pods in `default` Namespace**
```yaml
  - toEndpoints:
    - matchLabels:
        "k8s:io.kubernetes.pod.namespace": default
    toPorts:
    - ports:
      - port: "80"
        protocol: TCP
      - port: "8080"
        protocol: TCP
      rules:
        http: [{}]
```
✅ **Allows outgoing HTTP requests** to other pods **within the same `default` namespace**.  
✅ **Permits traffic to ports `80` (HTTP) and `8080` (commonly used for APIs).**  
✅ **Enforces Layer 7 (L7) visibility for HTTP requests** (`http: [{}]` means all HTTP requests are monitored).  
❌ **Blocks access to any other namespaces.**  
❌ **Blocks non-HTTP traffic on ports `80` and `8080`.**  

---

## **Summary of Policy Effects**
| **Traffic Type**         | **Allowed** | **Blocked** |
|--------------------------|------------|-------------|
| **DNS requests (port 53, any protocol)** | ✅ Allowed | ❌ None |
| **HTTP (port 80 & 8080) to other pods in `default` namespace** | ✅ Allowed | ❌ Other namespaces blocked |
| **Any other traffic (other ports/protocols)** | ❌ Blocked | ❌ Blocked |

---

## **Security & Benefits**
✅ **Ensures controlled egress traffic** while allowing essential DNS resolution.  
✅ **Monitors HTTP traffic using L7 rules for security insights.**  
✅ **Restricts communication to pods within the same namespace.**  
✅ **Prevents accidental access to external services or other namespaces.**  

Would you like to extend this policy to allow **HTTPS (port 443)** or external API calls? 🚀