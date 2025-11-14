## container vocabulary

Physical Machine – real hardware server.
VM – virtual machine running its own OS.
Node – a VM or machine that runs Kubernetes components or workloads. A node can
run multiple pods.
Pod – smallest deployable unit; one or more containers. K8s manages pods not
containers
Cluster – group of nodes managed as one Kubernetes system.
Control Plane Node – node running API server, scheduler, controllers.
Worker Node – node that runs application pods.
Container – lightweight isolated environment for applications.
Container Runtime – engine that runs containers (containerd, CRI-O).
Deployment – manages desired number of pod replicas.
ReplicaSet – maintains a stable set of identical pods.
DaemonSet – runs exactly one pod per node.
Job – runs a finite/one-time workload.
CronJob – runs jobs on a schedule.
Service – stable networking endpoint to reach pods.
ClusterIP – internal-only service endpoint.
NodePort – exposes service on each node’s port.
LoadBalancer – exposes service externally via cloud LB.
Ingress – HTTP/HTTPS routing into services.
CNI – plugin that provides pod networking.
Volume – storage attached to a pod.
PersistentVolume – actual physical/logical storage resource.
PersistentVolumeClaim – request for persistent storage.
ConfigMap – non-sensitive configuration data.
Secret – sensitive configuration data.
API Server – entry point for all Kubernetes commands.
Scheduler – picks which node a pod runs on.
Controller Manager – ensures desired state is maintained.
etcd – key-value store for cluster state.
Namespace – logical grouping of resources.
Label – key-value metadata for selecting resources.
Node Selector – restricts pods to certain nodes.
Affinity – rules for preferred node placement.
Taint – marks a node to repel pods.
Toleration – allows pod to run on tainted nodes.

