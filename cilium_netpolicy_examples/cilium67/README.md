This **CiliumNetworkPolicy** enforces an **ingress rule** based on **Kubernetes service accounts**, allowing fine-grained access control.

---

## **Policy Breakdown**
```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "k8s-svc-account"
spec:
  endpointSelector:
    matchLabels:
      io.cilium.k8s.policy.serviceaccount: leia
  ingress:
  - fromEndpoints:
    - matchLabels:
        io.cilium.k8s.policy.serviceaccount: luke
    toPorts:
    - ports:
      - port: '80'
        protocol: TCP
      rules:
        http:
        - method: GET
          path: "/public$"
```

### **Explanation**
1. **Applies to Pods Using Service Account "leia"**
   - The `endpointSelector` ensures that this policy applies **only to pods running with the service account `leia`**.
   
2. **Ingress Rule: Allow Incoming Requests from "luke"**
   - The `fromEndpoints` block **only allows traffic** from pods running with the **"luke"** service account (`io.cilium.k8s.policy.serviceaccount: luke`).

3. **Allowed Traffic**
   - **Port:** `80` (TCP) → Only HTTP traffic on port 80 is permitted.
   - **HTTP Method:** `GET` → The request must be an HTTP `GET` request.
   - **Path:** `/public$` → The requested URL must match `/public` exactly (due to the `$` which signifies end of the string).

---

## **What Does This Mean?**
- Only pods running under the **Kubernetes service account** `"luke"` can access pods using the `"leia"` service account.
- The `"luke"` pods **can only send** `GET` requests to `/public` over port `80` (TCP).
- Other traffic (e.g., `POST` requests or access to different paths) **is blocked**.

---

## **Use Case**
This is useful for **zero-trust security models** where access is controlled **at the service account level**, rather than just by pod labels. It ensures:
✅ **Fine-grained access control** between workloads.  
✅ **Service-to-service authentication** using Kubernetes service accounts.  
✅ **Least privilege enforcement**, preventing unintended access.  

Would you like to extend this policy to allow more actions, like `POST` requests or additional paths? 🚀