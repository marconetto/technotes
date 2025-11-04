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
example.

sudo kubeadm init --pod-network-cidr=10.244.0.0/16

