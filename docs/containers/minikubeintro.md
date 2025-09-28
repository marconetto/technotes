# Minikube intro


Minikube is a tool that simplifies running a local Kubernetes cluster by
launching a single-node cluster on a laptop/desktop/server using virtual
machines, containers, or bare metal (depending on OS). It uses the same upstream
Kubernetes binaries as production environments, making it ideal for development,
testing, and learning Kubernetes without the overhead of managing a full-scale
cluster. Minikube is not a separate version or subset of Kubernetes—it doesn't
modify Kubernetes core functionality or APIs. Instead, it is a setup and
convenience layer around Kubernetes that streamlines installation, networking,
and basic tooling for local use. It is not intended for production use, nor does
it replicate the performance or complexity of multi-node, cloud-native
Kubernetes clusters.

## Install minikube (macos)

```
brew install minikube
brew install kubectl
```

## Start minikube

```
minikube start --driver=docker
```

This launches a local Kubernetes cluster (in a docker container). This will download the VM
image too in case it does not exist.

## Interact with the cluster

Start minikube dashboard

```
minikube dashboard
```

See all pods in all namespaces (`get po` short for `get pods` and `-A` short for
`--all-namespaces`).

```
$ kubectl get po -A
NAMESPACE              NAME                                         READY   STATUS    RESTARTS        AGE
kube-system            coredns-674b8bbfcf-sgpsl                     1/1     Running   0               5m16s
kube-system            etcd-minikube                                1/1     Running   0               5m23s
kube-system            kube-apiserver-minikube                      1/1     Running   0               5m22s
kube-system            kube-controller-manager-minikube             1/1     Running   0               5m22s
kube-system            kube-proxy-n55xw                             1/1     Running   0               5m17s
kube-system            kube-scheduler-minikube                      1/1     Running   0               5m23s
kube-system            storage-provisioner                          1/1     Running   1 (4m46s ago)   5m20s
kubernetes-dashboard   dashboard-metrics-scraper-5d59dccf9b-724xl   1/1     Running   0               3m5s
kubernetes-dashboard   kubernetes-dashboard-7779f9b69b-7mvvp        1/1     Running   0               3m5s
```

<br>

##### Quick description of the pods

- **coredns**: Provides DNS resolution inside the cluster so services can find and communicate with each other.

- **etcd**: A distributed key-value store used to hold all cluster data and configuration.

- **kube-apiserver**: Serves as the front end of the Kubernetes control plane, exposing the Kubernetes API.

- **kube-controller-manager**: Runs controller processes that handle routine cluster tasks such as replication and node lifecycle management.

- **kube-proxy**: Maintains network rules on nodes, enabling network communication between pods and services.

- **kube-scheduler**: Assigns newly created pods to nodes based on resource availability and constraints.

- **storage-provisioner**: Automatically provisions persistent volumes for pods based on PersistentVolumeClaims (PVCs).

- **dashboard-metrics-scraper**: Collects resource usage metrics (CPU, memory) for display in the Kubernetes Dashboard.

- **kubernetes-dashboard**: A web-based UI for managing and monitoring Kubernetes resources.


## Deploy a hello world app

Create and expose deployment.

```
kubectl create deployment hello-minikube --image=kicbase/echo-server:1.0
kubectl expose deployment hello-minikube --type=NodePort --port=8080
```

To see the service is running:

```
kubectl get services hello-minikube
```

To access the service by allowing minikube to launch a webserver:

```
minikube service hello-minikube
```

In macos you may get this error (in case you are using qemu driver):

```
Exiting due to MK_UNIMPLEMENTED: minikube service is not currently implemented with the builtin network on QEMU, try starting minikube with '--network=socket_vmnet'
```

One way to overcome this is:

```
kubectl port-forward service/hello-minikube 7080:8080
```

Then open the browser: `http://localhost:7080/`


Another is to install `socket_vmnet` ([see instructions](https://minikube.sigs.k8s.io/docs/drivers/qemu/#networking)), then start the process to create minikube again, as it will detect the `socket_vmnet` installation.


## Delete cluster

This will stop the VM running minikube and delete the cluster state.

```
minikube delete
```

## References

- [Minikube](https://minikube.sigs.k8s.io/docs/)
- [Kubernetes 101](https://minikube.sigs.k8s.io/docs/tutorials/kubernetes_101/)
- [Minikube macos tutorial](https://devopscube.com/minikube-mac/)


