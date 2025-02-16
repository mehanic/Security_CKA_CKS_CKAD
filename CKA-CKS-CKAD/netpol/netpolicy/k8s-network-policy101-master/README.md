# Kubernetes network policy 101

You can find a related blog here：https://davidlovezoe.club/wordpress/archives/438

## Provision the kubernetes cluster with network policy enabled on GKE
```bash
# create the cluster
> gcloud container clusters create network-policy-demo101 --machine-type=n1-standard-1 --num-nodes=6 --preemptible --enable-network-policy --zone=your-target-zone

# check the cluster status
> gcloud container clusters describe network-policy-demo101 --zone your-target-zone |grep -i -C5 networkpolicy
...
networkPolicy:
  enabled: true
  provider: CALICO
...

```

## Create workload for test
- hello-client-pass
  - it is a deployment labeled with *`app=pass`*
- hello-client-fail
  - it is a deployment labeled with *`app=fail`*

Those two deployments are in one yaml: [hello-client.yaml](./workload/hello-client.yaml)

- hello-server
  - Deployment and service labeled with *`hello-server`*
  - The workload manifest is [hello-server.yaml](./workload/hello-server.yaml)

## Create network policy resource for pod level
Our goal is to make the *`hello-server`* workload only be accessed by the pod labeled with *`app=pass`*, aka pod "hello-client-pass".
Thus, the network policy can be created with the file: [network-policy-pod.yaml](./network-policy/network-policy-pod.yaml)

You should find the normal output in the "hello-client-pass" pod:
```bash
--2019-06-04 09:17:24--  http://hello-server.default.svc:8080/
Resolving hello-server.default.svc (hello-server.default.svc)... 10.19.250.137
Connecting to hello-server.default.svc (hello-server.default.svc)|10.19.250.137|:8080... connected.
HTTP request sent, awaiting response... 200 OK
Length: 68 [text/plain]
```
On the other hand, you should find the timeout message in the "hello-client-fail" pod:
```bash
--2019-06-04 09:26:58--  (try:100)  http://hello-server.default.svc:8080/
Connecting to hello-server.default.svc (hello-server.default.svc)|10.19.250.137|:8080... failed: Connection timed out.
Retrying.
```
## Create network policy resource for namespace level
This time, our goal is to make *`hello-server`* workload only be accessed by the workload of the specified namespace, which is labeled with *`team: green`*. You can find the resource file here: [network-policy-namespace.yaml](./network-policy/network-policy-namespace.yaml)

You should find:
- the workload of the **default** namesapce cannot access the *`hello-server`* service anymore
- the workload in the namespace labeled with *`team:green`* will have access to the *`hello-server`* service in the **default** namespace

## Combine two network policies together
I have recored a video to show how those two network policies work together:

[![2-np-work](https://img.youtube.com/vi/RI6034AfdTs/0.jpg)](https://www.youtube.com/watch?v=RI6034AfdTs)

It is found that:
- the network policy of pod level and namespace level can be combined to use
- new policy will take effect immediately once created

## Recommended default network policy
- deny all external traffic but allow internal traffic from other namespaces: [default-namespace-egress.yaml](./network-policy/default-namespace-egress.yaml)
  
  By default, we want the workload cannot access outside the cluster but can access inside the cluster(across the namespaces). We can use the network policy above.

- whitelist for namespace egress
  
  I have defined an example for namespace egress policy. It is found here:[ip-block-ns-egress.yaml](./network-policy/ip-block-ns-egress.yaml). You can use the command below to test:
```bash
# access the pod
kubectl exec -ti [pod-name] bash
# inside the pod
curl [target IP]
ping [target IP]
```
