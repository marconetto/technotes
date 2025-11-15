# K8s


Kubernetes (k8s) is an open-source platform for automating deployment, scaling, and
management of containerized applications. It was originally developed by Google
and is now maintained by the Cloud Native Computing Foundation (CNCF).

Kubernetes is designed to manage clusters of machines (physical or virtual) and
orchestrate containers such as Docker, ensuring applications run reliably and
efficiently.

Oview of operation:

- User defines desired state in YAML/JSON (e.g., 3 replicas of a web app).
- YAML is submitted to the API server.
- Scheduler decides which nodes will run the pods.
- kubelet on each node ensures the pod is running correctly.
- Controllers monitor the cluster and make corrections if the actual state deviates from desired state.
- Services provide networking and load balancing for pods.


## Goals


Kubernetes was designed with several goals in mind:

1. Automated Deployment and Scaling

    - Automatically deploy containerized applications across nodes.
    - Scale applications up or down based on demand.

2. Self-Healing

    - Automatically restarts failed containers.
    - Replaces or reschedules containers if nodes die.
    - Kills containers that don't respond to health checks.

3. Service Discovery and Load Balancing

    - Automatically exposes containers using DNS names or IP addresses.
    - Distributes network traffic evenly across containers.

4. Infrastructure Abstraction

    - Applications run the same way whether nodes are on-premises, in a cloud, or hybrid.

5. Declarative Configuration and Automation

    - Users describe the desired state of the system (e.g., "3 replicas of my app") in YAML/JSON.
    - Kubernetes automatically ensures the system matches the desired state.


## Components

A. Control Plane Components (master-level)

These manage the cluster and ensure the desired state.

- kube-apiserver: Exposes the Kubernetes API. All commands and external interactions go through this.
- etcd: Distributed key-value store for cluster state and configuration.
- kube-scheduler: Assigns pods to nodes based on resource requirements, policies, and constraints.
- kube-controller-manager: Runs controllers that handle routine tasks like replicating pods or managing node health.
- cloud-controller-manager: Interfaces with cloud providers to manage resources like load balancers, storage, or networking.

B. Node Components (worker-level)

These run the actual workloads (containers) and report back to the control plane.

- kubelet: Agent that runs on each node, ensures containers are running as described in PodSpecs.
- kube-proxy: Handles networking for pods, including service IPs and load balancing.
- Container Runtime: Software that runs containers (e.g., containerd, Docker, CRI-O).

C. Key Kubernetes Objects

These are abstractions for managing containers:

- Pod: Smallest deployable unit; a group of one or more containers sharing resources.
- Service: Exposes a set of pods to network traffic with a stable IP and DNS name.
- Deployment: Declaratively manages a set of pods, handling scaling, rolling updates, and self-healing.
- ConfigMap / Secret: Stores configuration data or sensitive information for pods.
- Namespace: Provides logical isolation of resources in a cluster.
- Volume / Persistent Volume: Handles storage that persists beyond container lifetimes.



## Example k8s on a single VM


Provision a single VM (example via Azure services). In this example we have an
almalinux VM being created. Once the VM is created, the following steps are used
to run the master and node processes on that VM and run a simple hello world
example. Here we won't be using `minikube`, but `kubeadm` to be more
closer to a multi-node setup.


The default behavior of a kubelet is to fail to start if swap memory is detected on a node. So it is recommended to disable swap:

```
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```


Disable SELinux (Security-Enhanced Linux) to allow containers to access the host filesystem; for example, some cluster network plugins require that.

```
# Set SELinux in permissive mode (effectively disabling it; violations logged)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
```

```
sudo dnf update -y
```


Update repos. Exclude is recommended to avoid these packages being updated with `dns update`.

```
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.34/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.34/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
```


- *kubeadm:* the command to bootstrap the cluster.
- *kubelet:* the component that runs on all of the machines in the cluster and does things like starting pods and containers.
- *kubectl:* the command line util to talk to the cluster.

```
sudo dnf install kubeadm kubelet kubectl --disableexcludes=kubernetes -y
```


Check containerd is running:

```
sudo systemctl status containerd --no-pager
```

Start `kubeadm`:

```
sudo kubeadm init \
  --apiserver-advertise-address=$(hostname -I | awk '{print $1}') \
  --pod-network-cidr=10.244.0.0/16
```

This command sets up the control plane and writes the admin’s kubeconfig file here (owned by root): `/etc/kubernetes/admin.conf`
This file tells `kubectl`:

- where to find the API server,
- which user credentials to use,
- what certificates to trust.


To start the cluster:

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

If you run the following command, it will show the control-plane node is not
ready as it requires a pod network plugin---Kubernetes depends on a CNI
(Container Network Interface) plugin for inter-pod communication.

```
kubectl get nodes
```


```
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
kubectl -n kube-flannel get pods -o wide
```

After this is done the `kubectl get nodes` will show the control plane node as
ready.

```
kubectl get nodes
NAME          STATUS   ROLES           AGE   VERSION
vmnetto3160   Ready    control-plane   42m   v1.34.1
```

One can also see all pods running:

```
kubectl get pods -A
NAMESPACE      NAME                                  READY   STATUS    RESTARTS   AGE
kube-flannel   kube-flannel-ds-hd7gw                 1/1     Running   0          11m
kube-system    coredns-66bc5c9577-s2vpb              1/1     Running   0          52m
kube-system    coredns-66bc5c9577-vnpb8              1/1     Running   0          52m
kube-system    etcd-vmnetto3160                      1/1     Running   0          52m
kube-system    kube-apiserver-vmnetto3160            1/1     Running   0          52m
kube-system    kube-controller-manager-vmnetto3160   1/1     Running   0          52m
kube-system    kube-proxy-v7kc6                      1/1     Running   0          52m
kube-system    kube-scheduler-vmnetto3160            1/1     Running   0          52m
```


As we are running everything on a single VM, the following command would not be
used; as it is for additional VMs. The `kubeadm init` command already starts
`kubelet` on the node.

```
sudo kubeadm join <control-plane-host>:<control-plane-port> --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```


To allow regular nodes to be scheduled in control-plane node (okay for single
node tests).

```
# see the taint there in control-plane
kubectl describe node vmnetto3160 | grep Taints

# remove it
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```


Deplay a pod:

```
kubectl run nginx --image=nginx --restart=Never
```


## Example k8s on multi-node cluster

Assuming there is a master node running (with all the steps above) and a new
almalinux VM is available; here is what it takes to have that second VM join the
k8s cluster as a worker node.

- Disable swap (see above)
- Install kubernetes package (see above)

The use the join command (replace xxx with actual token/cert):
```
kubeadm join 10.31.0.4:6443 --token xxxxxx.xxxxxxxxxxxxxxxx \
>         --discovery-token-ca-cert-hash sha256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

On the master node one should see the new worker node:

```
kubectl get nodes -o wide
```


### Test multi-node

Or create a DaemonSet. Create a file:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-ip-printer
spec:
  selector:
    matchLabels:
      app: node-ip-printer
  template:
    metadata:
      labels:
        app: node-ip-printer
    spec:
      containers:
      - name: printer
        image: busybox
        command:
          - sh
          - -c
          - |
            echo "Node: $(hostname) Host IP: $NODE_IP"
            sleep 3600
        env:
        - name: NODE_IP
          valueFrom:
            fieldRef:
              fieldPath: status.hostIP
      restartPolicy: Always
```

Run:

```
kubectl apply -f node-ip-printer.yaml
```

Check log
```
kubectl get pods -o wide
kubectl logs <pod-name>
```

Get more info about the pod


```
kubectl describe pod <pod-name>
```

To delete the pod

```
kubectl delete -f node-ip-printer.yaml
```

Or

```
kubectl delete pod <pod-name>
```





### Appendix

Check `kubelet` logs:

```
sudo journalctl -u kubelet -n 20 --no-pager
```


If you lose the command to join the worker (by creating a new token):

```
kubeadm token create --print-join-command
```

To use existing one:

```
# get token
sudo kubeadm token list

# get discovery-token-ca-cert-hash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \
openssl rsa -pubin -outform der 2>/dev/null | \
openssl dgst -sha256 -hex | \
sed 's/^.* //'
```






### References
- <https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/>
- <https://kubernetes.io/docs/reference/networking/ports-and-protocols/>
- tutorial (ubuntu install k8s 1.33):
<https://www.youtube.com/watch?v=j3a2Sr2n8eQ>
