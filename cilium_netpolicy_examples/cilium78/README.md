### **Cilium Network Policy: `default-deny-example`**  

This policy **implements a default deny rule** for both **ingress (incoming) and egress (outgoing) traffic** in the namespace.

---

## **Policy Breakdown**
```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "default-deny-example"
spec:
  endpointSelector: {}  # Applies to all pods in the namespace
```
- **Applies to:** **All pods** in the namespace (no specific label filtering).  
- **Effect:** This policy **blocks all traffic** unless explicitly allowed by other policies.

---

## **1️⃣ Deny All Ingress Traffic**
```yaml
  enableDefaultDeny:
    ingress: true
```
❌ **Blocks all incoming traffic** to the pods in this namespace.  
✅ To allow specific ingress traffic, a separate **`CiliumNetworkPolicy`** must be created.

---

## **2️⃣ Deny All Egress Traffic**
```yaml
  enableDefaultDeny:
    egress: true
```
❌ **Blocks all outgoing traffic** from the pods in this namespace.  
✅ To allow external communication (e.g., accessing APIs, DNS resolution, or databases), a separate policy must be defined.

---

## **Summary of Policy Effects**
| **Traffic Type**       | **Allowed?** |
|------------------------|-------------|
| Ingress (incoming)     | ❌ Blocked |
| Egress (outgoing)      | ❌ Blocked |
| Internal pod-to-pod communication | ❌ Blocked |

---

## **Why Use This Policy?**
✅ **Security Hardening** – Enforces **zero-trust networking** by default.  
✅ **Explicit Allow Rules** – Ensures only permitted communication is enabled via separate policies.  
✅ **Prevents Unauthorized Access** – Protects against unintended service exposure.  

---

## **Next Steps**
To allow traffic, create additional **CiliumNetworkPolicies**:  
- 🔹 Allow **specific ingress traffic** (e.g., HTTP on port 80).  
- 🔹 Allow **specific egress traffic** (e.g., DNS resolution on port 53, external API access).  

Would you like help creating these additional rules? 🚀