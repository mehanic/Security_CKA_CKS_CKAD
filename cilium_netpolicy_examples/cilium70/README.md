### **Cilium Network Policy: `secure-empire-kafka`**  

This **CiliumNetworkPolicy** is designed to enforce strict access control for **Kafka communication** in the "Empire" infrastructure. It regulates which services can **produce** and **consume** messages on specific Kafka topics running on **port 9092**.  

---

## **Policy Breakdown**
```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "secure-empire-kafka"
specs:
```
- The policy applies **to multiple rules** under the `specs` field.
- The key objective is **controlling Kafka traffic** between specific components.

---

## **Ingress Rules for Kafka Broker (`app: kafka`)**  

### **1️⃣ Allow `empire-hq` to Produce Kafka Messages**
```yaml
  - description: Allow only permitted Kafka requests to empire Kafka broker
    endpointSelector:
      matchLabels:
        app: kafka
    ingress:
    - fromEndpoints:
      - matchLabels:
          app: empire-hq
      toPorts:
      - ports:
        - port: "9092"
          protocol: TCP
        rules:
          kafka:
          - role: "produce"
            topic: "deathstar-plans"
          - role: "produce"
            topic: "empire-announce"
```
- **Applies to:** `app: kafka` (Kafka broker)
- **Allows ingress from:** `app: empire-hq` (Headquarters)  
- **Permits:** **Producing** (writing messages) to Kafka **topics:**
  - `"deathstar-plans"`
  - `"empire-announce"`
- **On port:** **9092 (TCP)** (Kafka communication)

🔹 **Effect:**  
  - Only **`empire-hq`** can produce messages to **these two Kafka topics**.
  - Other services **cannot produce messages** to Kafka.

---

### **2️⃣ Allow Kafka Brokers to Talk to Each Other**
```yaml
    - fromEndpoints:
      - matchLabels:
          app: kafka
```
- **Allows Kafka-to-Kafka communication** (for replication, coordination).
- Ensures Kafka brokers in a distributed system can **synchronize**.

---

### **3️⃣ Allow `empire-outpost` to Consume Messages from `empire-announce`**
```yaml
  - endpointSelector:
      matchLabels:
        app: kafka
    ingress:
    - fromEndpoints:
      - matchLabels:
          app: empire-outpost
      toPorts:
      - ports:
        - port: "9092"
          protocol: TCP
        rules:
          kafka:
          - role: "consume"
            topic: "empire-announce"
```
- **Applies to:** `app: kafka` (Kafka broker)
- **Allows ingress from:** `app: empire-outpost`
- **Permits:** **Consuming** (reading messages) from Kafka **topic:**
  - `"empire-announce"`
- **On port:** **9092 (TCP)**

🔹 **Effect:**  
  - **`empire-outpost` can read** messages from `"empire-announce"` **but not from other topics**.

---

### **4️⃣ Allow `empire-backup` to Consume Messages from `deathstar-plans`**
```yaml
  - endpointSelector:
      matchLabels:
        app: kafka
    ingress:
    - fromEndpoints:
      - matchLabels:
          app: empire-backup
      toPorts:
      - ports:
        - port: "9092"
          protocol: TCP
        rules:
          kafka:
          - role: "consume"
            topic: "deathstar-plans"
```
- **Applies to:** `app: kafka`
- **Allows ingress from:** `app: empire-backup`
- **Permits:** **Consuming** messages from:
  - `"deathstar-plans"`
- **On port:** **9092 (TCP)**

🔹 **Effect:**  
  - **`empire-backup` can read `deathstar-plans`** messages.
  - **It cannot consume** from other Kafka topics.

---

## **Overall Summary**
| **Component**      | **Allowed Action**            | **Kafka Topic**       | **Port** |
|--------------------|-----------------------------|----------------------|----------|
| `empire-hq`       | **Produce** messages        | `deathstar-plans`, `empire-announce` | 9092 |
| `empire-outpost`  | **Consume** messages       | `empire-announce`    | 9092 |
| `empire-backup`   | **Consume** messages       | `deathstar-plans`    | 9092 |
| `kafka` brokers   | **Communicate with each other** | All topics | 9092 |

---

## **Security Benefits of This Policy**
✅ **Restricts access** to Kafka topics based on service roles.  
✅ **Prevents unauthorized production or consumption** of Kafka messages.  
✅ **Allows Kafka broker communication** for internal synchronization.  
✅ **Minimizes attack surface** by isolating Kafka topics per service.  

Would you like to add **logging or monitoring** for better visibility into Kafka traffic? 🚀