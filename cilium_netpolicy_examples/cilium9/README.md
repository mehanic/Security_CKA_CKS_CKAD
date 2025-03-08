This YAML configuration defines resources for deploying **Prometheus** in a Kubernetes cluster under the `cilium-monitoring` namespace. It sets up **ConfigMaps**, **Deployments**, **RBAC (Role-Based Access Control)** configurations, a **ServiceAccount**, and a **Service** to make Prometheus work effectively in the Kubernetes environment.

### Key Resources and Their Roles:

### **1. ConfigMap (Prometheus Configuration)**
```yaml
kind: ConfigMap
metadata:
  name: prometheus
  namespace: cilium-monitoring
apiVersion: v1
data:
  {{ (.Files.Glob "files/prometheus/*").AsConfig | indent 2 }}
```
- **Purpose**: This ConfigMap holds the configuration for Prometheus (the `prometheus.yaml` file and any additional configurations) that Prometheus will use at runtime.
- **Configuration Files**: It loads any files found in the `files/prometheus/` directory of the Helm chart. This is typically where the Prometheus scraping configuration, alerting rules, and any other configurations are stored.

### **2. Deployment (Prometheus Deployment)**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: prometheus
  name: prometheus
  namespace: cilium-monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
      name: prometheus-main
    spec:
      containers:
      - args:
        - --config.file=/etc/prometheus/prometheus.yaml
        - --storage.tsdb.path=/prometheus/
        - --log.level=info
        - --enable-feature=exemplar-storage
        image: "prom/prometheus:{{ .Values.image.prometheus.version }}"
        imagePullPolicy: IfNotPresent
        name: prometheus
        ports:
        - containerPort: 9090
          name: webui
          protocol: TCP
        volumeMounts:
        - mountPath: /etc/prometheus
          name: config-volume
          readOnly: true
        - mountPath: /prometheus/
          name: storage
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      serviceAccount: prometheus-k8s
      volumes:
      - configMap:
          name: prometheus
        name: config-volume
      - emptyDir: {}
        name: storage
```
- **Purpose**: This defines a **Deployment** that will deploy Prometheus in the `cilium-monitoring` namespace. The deployment ensures that Prometheus runs with the correct configuration and persists data in a storage volume.
- **Replicas**: The `replicas: 1` field ensures that only one instance of Prometheus is running.
- **Containers**:
  - The Prometheus container runs the `prom/prometheus` image and is configured with:
    - `--config.file`: Specifies the location of the Prometheus configuration file, which is mounted from the `ConfigMap`.
    - `--storage.tsdb.path`: Specifies where Prometheus will store its time-series database (TSDB). It uses the `/prometheus/` path (an empty directory).
    - `--log.level=info`: Prometheus will log at the "info" level.
    - `--enable-feature=exemplar-storage`: Enables exemplar storage for more detailed metric information.
  - **Ports**: The container exposes port `9090` for the Prometheus web UI (default).
  - **Volumes**:
    - `/etc/prometheus` is mounted from the `ConfigMap`, where Prometheus can find its configuration.
    - `/prometheus/` is an empty directory volume used for persistent storage of Prometheus data.

### **3. ClusterRoleBinding (RBAC for Prometheus)**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
- kind: ServiceAccount
  name: prometheus-k8s
  namespace: cilium-monitoring
```
- **Purpose**: The **ClusterRoleBinding** grants the **prometheus-k8s** service account the permissions specified in the `prometheus` **ClusterRole**.
- **Role**: The role gives Prometheus the ability to access resources like nodes, services, pods, and configmaps across the entire cluster (which Prometheus needs to scrape metrics from various Kubernetes resources).
- **Subjects**: The service account (`prometheus-k8s`) within the `cilium-monitoring` namespace is assigned the permissions defined in the `prometheus` **ClusterRole**.

### **4. ClusterRole (Permissions for Prometheus)**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
- apiGroups:
  - ""
  resources:
  - nodes
  - nodes/proxy
  - services
  - endpoints
  - pods
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - configmaps
  verbs:
  - get
- nonResourceURLs:
  - /metrics
  verbs:
  - get
```
- **Purpose**: This **ClusterRole** defines the permissions Prometheus needs in order to access resources within the Kubernetes cluster.
- **Permissions**:
  - **Nodes**: `get`, `list`, `watch` nodes and node proxies. This is essential for accessing node-level metrics.
  - **Services, Endpoints, Pods**: `get`, `list`, `watch` for services, endpoints, and pods to scrape metrics from them.
  - **ConfigMaps**: `get` permission on ConfigMaps to read the Prometheus configuration.
  - **Metrics**: Allows access to `/metrics`, a common endpoint for exposing metrics from applications and services.

### **5. ServiceAccount (Service Account for Prometheus)**
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus-k8s
  namespace: cilium-monitoring
```
- **Purpose**: This **ServiceAccount** is used by the Prometheus pod to authenticate and authorize API requests to the Kubernetes API server.
- **Role**: The Prometheus deployment uses this service account, which is granted the required permissions via the **ClusterRoleBinding**.

### **6. Service (Prometheus Service for Web UI Access)**
```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: prometheus
  name: prometheus
  namespace: cilium-monitoring
spec:
  ports:
  - name: webui
    port: 9090
    protocol: TCP
    targetPort: 9090
  selector:
    app: prometheus
  type: ClusterIP
```
- **Purpose**: This **Service** exposes Prometheus' web UI on port `9090` so that other services or users can access it within the Kubernetes cluster.
- **Selector**: It targets pods with the label `app: prometheus` to route traffic to the correct Prometheus instance.
- **Type**: `ClusterIP` ensures that the service is only accessible within the Kubernetes cluster (not externally).

### **Summary of the Deployment:**
1. **Prometheus ConfigMap** stores the configuration.
2. **Prometheus Deployment** deploys a single instance of Prometheus that uses the configuration and persists its data in an empty directory.
3. **ClusterRoleBinding** and **ClusterRole** grant Prometheus the necessary permissions to access Kubernetes resources.
4. **ServiceAccount** enables Prometheus to authenticate with the Kubernetes API.
5. **Service** exposes Prometheus' web UI inside the cluster on port `9090` to facilitate metric visualization.

This setup is typical for monitoring Kubernetes clusters using Prometheus, where Prometheus scrapes metrics from nodes, pods, services, and endpoints.