This YAML configuration is used to deploy **Grafana** in a Kubernetes cluster within the `cilium-monitoring` namespace. It defines the necessary **ConfigMaps**, **Service**, **Deployment**, and **Namespace** resources for the Grafana setup. Let's break down each part:

### **1. ConfigMap for Grafana Configuration**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    app: grafana
  name: grafana-config
  namespace: cilium-monitoring
data:
{{ (.Files.Glob "files/grafana-config/*").AsConfig | indent 2 }}
```
- **Purpose**: This `ConfigMap` contains the main configuration for Grafana. The `grafana-config.ini` and other related files will be loaded dynamically from the directory `files/grafana-config/`.
- **Template Expansion**: The `{{ (.Files.Glob "files/grafana-config/*").AsConfig }}` expression allows you to include all files from `files/grafana-config/` into the ConfigMap. The `AsConfig` function takes these files and adds them as key-value pairs in the `ConfigMap`, where each file is represented by a key (file name) and the file's contents as the value.
- **Namespace**: The `ConfigMap` is created in the `cilium-monitoring` namespace.

### **2. Create Multiple ConfigMaps for Dashboards**
```yaml
{{- range $path, $bytes := .Files.Glob "files/grafana-dashboards/*" }}
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    app: grafana
  name: grafana-{{ $path | base | trimSuffix (ext $path) }}
  namespace: cilium-monitoring
data:
  {{ $path | base }}: |
{{ $bytes | toString | indent 4}}
---
{{- end }}
```
- **Purpose**: This block creates a separate `ConfigMap` for each Grafana dashboard in the `files/grafana-dashboards/` directory.
- **Template Expansion**: 
  - The `range` function iterates over the dashboard files.
  - For each file, a new `ConfigMap` is created with the file's content as the `data`. The `name` of the ConfigMap is derived from the filename (excluding the file extension).
  - This setup avoids hitting the **256KB ConfigMap size limit** that Kubernetes imposes by breaking large dashboards into smaller, individual ConfigMaps.
  
### **3. Grafana Service**
```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: grafana
  name: grafana
  namespace: cilium-monitoring
spec:
  ports:
    - port: 3000
      protocol: TCP
      targetPort: 3000
  selector:
    app: grafana
  type: ClusterIP
```
- **Purpose**: This creates a Kubernetes **Service** for Grafana, which allows other components in the cluster to access the Grafana dashboard.
- **Ports**: The service exposes port `3000` (the default Grafana port).
- **Selector**: The service targets pods labeled with `app: grafana` (this label is used to select the Grafana pods).
- **Service Type**: The service is of type `ClusterIP`, meaning it is only accessible within the Kubernetes cluster.

### **4. Grafana Deployment**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: grafana
    component: core
  name: grafana
  namespace: cilium-monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
        - env:
            - name: GF_PATHS_CONFIG
              value: /configmap/grafana/grafana-config.ini
            - name: GF_PATHS_PROVISIONING
              value: /configmap/grafana/provisioning
          image: "docker.io/grafana/grafana:{{ .Values.image.grafana.version }}"
          imagePullPolicy: IfNotPresent
          name: grafana-core
          readinessProbe:
            failureThreshold: 3
            httpGet:
              path: /login
              port: 3000
              scheme: HTTP
          volumeMounts:
            - mountPath: /configmap/grafana
              name: grafana-config
              readOnly: true
{{- range $path, $_ := .Files.Glob "files/grafana-dashboards/*" }}
{{- $name := $path | base | trimSuffix (ext $path) }}
            - mountPath: /configmap/dashboards/{{ $name }}
              name: {{ $name }}
              readOnly: true
{{- end }}
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      volumes:
        - configMap:
            defaultMode: 420
            items:
              - key: grafana.ini
                path: grafana-config.ini
              - key: prometheus-datasource.yaml
                path: provisioning/datasources/prometheus.yaml
              - key: config.yaml
                path: provisioning/dashboards/config.yaml
            name: grafana-config
          name: grafana-config
{{- range $path, $_ := .Files.Glob "files/grafana-dashboards/*" }}
{{- $name := $path | base | trimSuffix (ext $path) }}
        - configMap:
            defaultMode: 420
            name: grafana-{{ $name }}
          name: {{ $name }}
{{- end }}
```
- **Purpose**: This defines a **Deployment** for Grafana. It creates a single replica (Grafana pod) of the Grafana container.
- **Container Setup**:
  - **Environment Variables**:
    - `GF_PATHS_CONFIG`: Points to the configuration file for Grafana.
    - `GF_PATHS_PROVISIONING`: Points to the directory containing provisioning files.
  - **Image**: Grafana uses the `docker.io/grafana/grafana` image, with the version dynamically pulled from the values (`.Values.image.grafana.version`).
  - **Readiness Probe**: A probe to check if Grafana is ready by accessing the `/login` page at port `3000`.
  - **Volume Mounts**:
    - Mounts the `grafana-config` ConfigMap to `/configmap/grafana`.
    - Mounts individual dashboard ConfigMaps to `/configmap/dashboards/{dashboard_name}`.
  - **Volumes**: Defines the `ConfigMap` volumes for both Grafana's configuration (`grafana-config.ini`, `prometheus-datasource.yaml`, `config.yaml`) and the individual dashboard files.

### **5. Namespace Creation**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: cilium-monitoring
```
- **Purpose**: This creates a **Namespace** named `cilium-monitoring`, which is used to isolate all Grafana-related resources (ConfigMaps, Service, Deployment) from other Kubernetes resources.
  
---

### **Summary of Flow**

- **ConfigMaps for Grafana Config and Dashboards**: 
  - A `ConfigMap` is created for the main Grafana configuration and dynamically for each dashboard from the `files/grafana-config/` and `files/grafana-dashboards/` directories.
  
- **Grafana Service**: A service is created to expose Grafana within the cluster on port `3000`.

- **Grafana Deployment**: 
  - The Grafana pod is deployed with the necessary configuration files and dashboards. These are mounted into the container from the `ConfigMaps` created earlier.
  - The Grafana container uses the official Grafana Docker image, and a readiness probe ensures that the Grafana service is fully initialized before traffic is sent to it.

- **Namespace**: The entire setup is created in the `cilium-monitoring` namespace, which is dedicated to Grafana in this case.

This configuration is flexible, allowing you to dynamically manage Grafana dashboards and configuration while avoiding size limitations with individual ConfigMaps.