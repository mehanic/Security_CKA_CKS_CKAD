### **Cilium Network Policy: `l7-visibility-tls`**  

This **CiliumNetworkPolicy** applies **Layer 7 (L7) filtering with TLS** to control outbound traffic from **mediabot** services in the "Empire" organization. It enforces **TLS termination and origination**, allowing encrypted communication to a specific external domain (`httpbin.org`).

---

## **Policy Breakdown**
```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "l7-visibility-tls"
spec:
  description: L7 policy with TLS
  endpointSelector:
    matchLabels:
      org: empire
      class: mediabot
```
- **Applies to:** Pods with labels:
  - `org: empire`
  - `class: mediabot`
- **Effect:** Controls **egress (outgoing) traffic**.

---

## **1️⃣ Allow HTTPS Traffic to `httpbin.org` with TLS Enforcement**
```yaml
  egress:
  - toFQDNs:
    - matchName: "httpbin.org"
    toPorts:
    - ports:
      - port: "443"
        protocol: "TCP"
```
- **Allows outbound HTTPS traffic (port `443` on TCP)** to `httpbin.org` (external API).
- **FQDN-based policy**: Ensures only traffic to this exact domain is allowed.

### **🔐 TLS Handling**
```yaml
      terminatingTLS:
        secret:
          namespace: "kube-system"
          name: "httpbin-tls-data"
      originatingTLS:
        secret:
          namespace: "kube-system"
          name: "tls-orig-data"
```
- **`terminatingTLS`**:  
  - Specifies a **TLS secret** (`httpbin-tls-data`) stored in the **`kube-system`** namespace.  
  - Used when **decrypting inbound TLS connections** (if a service inside the cluster were to act as a TLS server).
  
- **`originatingTLS`**:  
  - Specifies a **TLS secret** (`tls-orig-data`) for **establishing outbound TLS connections**.  
  - Ensures that `mediabot` services can securely **initiate HTTPS requests**.

### **L7 HTTP Rule (Empty)**
```yaml
      rules:
        http:
        - {}
```
- **This means:**  
  - HTTP traffic is **observed and enforced** at L7.  
  - But **no specific HTTP method, path, or header constraints** are applied.  
  - If rules were specified (e.g., `method: GET, path: "/status/200"`), only those requests would be allowed.

---

## **2️⃣ Allow DNS Lookups (`port 53`)**
```yaml
  - toPorts:
    - ports:
      - port: "53"
        protocol: ANY
      rules:
        dns:
          - matchPattern: "*"
```
- **Allows outbound traffic to DNS servers on port `53`**.
- **`matchPattern: "*"`** → Permits **any DNS query**, ensuring `mediabot` can resolve domains.

---

## **Summary of Policy Effects**
| **Component**       | **Action**              | **Protocol/Port** | **TLS Handling** |
|---------------------|------------------------|-------------------|------------------|
| `mediabot` pods    | **Egress to `httpbin.org`** | HTTPS (443/TCP) | TLS termination & origination enforced |
| `mediabot` pods    | **Perform DNS lookups** | DNS (53/ANY) | No TLS |

---

## **Security Benefits**
✅ **Fine-grained Layer 7 filtering:** Observes HTTP traffic at the application level.  
✅ **Strict FQDN-based control:** Only allows HTTPS traffic to `httpbin.org`.  
✅ **TLS encryption enforced:** Protects outbound connections with controlled certificate usage.  
✅ **DNS resolution allowed:** Ensures services can look up domain names while restricting outbound traffic.  

---

## **Potential Enhancements**
🔹 **Define HTTP rules:** Restrict traffic to specific endpoints (e.g., only `GET /status/200`).  
🔹 **Monitor TLS secrets:** Ensure they are rotated securely.  
🔹 **Enable logging:** For better visibility into TLS and DNS traffic.
