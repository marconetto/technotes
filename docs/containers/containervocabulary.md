# Container Vocabulary


- Physical Machine – real hardware server.
- VM – virtual machine running its own OS.
- Node – a VM or machine that runs Kubernetes components or workloads. A node can
run multiple pods.
- Pod – smallest deployable unit; one or more containers. K8s manages pods not
containers
- Cluster – group of nodes managed as one Kubernetes system.
- Control Plane Node – node running API server, scheduler, controllers.
- Worker Node – node that runs application pods.
- Container – lightweight isolated environment for applications.
- Container Runtime – engine that runs containers (containerd, CRI-O).
- Deployment – manages desired number of pod replicas.
- ReplicaSet – maintains a stable set of identical pods.
- DaemonSet – runs exactly one pod per node.
- Job – runs a finite/one-time workload.
- CronJob – runs jobs on a schedule.
- Service – stable networking endpoint to reach pods.
- ClusterIP – internal-only service endpoint.
- NodePort – exposes service on each node’s port.
- LoadBalancer – exposes service externally via cloud LB.
- Ingress – HTTP/HTTPS routing into services.
- CNI – plugin that provides pod networking.
- Volume – storage attached to a pod.
- PersistentVolume – actual physical/logical storage resource.
- PersistentVolumeClaim – request for persistent storage.
- ConfigMap – object used to store configuration data (plain text) that applications need, separate from container images.
- Secret – sensitive configuration data.
- API Server – entry point for all Kubernetes commands.
- Scheduler – picks which node a pod runs on.
- Controller Manager – ensures desired state is maintained.
- etcd – key-value store for cluster state. Stores all configuration, desired state, and current state for every resource.
- Namespace – logical grouping of resources.
- Label – key-value metadata for selecting resources.
- Node Selector – restricts pods to certain nodes.
- Affinity – rules for preferred node placement.
- Taint – marks a node to repel pods.
- Toleration – allows pod to run on tainted nodes.
- Probes - health checks performed by the Kubelet on containers to monitor their state. Types: liveness probes (restart a container if it's unhealthy), readiness probes (ensure a container is ready to serve traffic before it receives any), and startup probes (for slow-starting containers to give them time to initialize before readiness and liveness checks begin).
- kubeclt - CLI for k8s clusters. Communicates with API server
- kubelet - node agent that runs on every node and makes sure the containers and pods scheduled to that node are running correctly. kubelet receives a pod spec from the control plane and instructs the container runtime to create the containers that make up that pod. The pod is created first (as an object in the Kubernetes API), and then the containers inside that pod are created on a node.



---------------------
