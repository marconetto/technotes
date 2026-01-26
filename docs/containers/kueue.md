# AKS+Kueue

This tutorial walks you through provisioning an AKS cluster with [Kueue](https://kueue.sigs.k8s.io/) for managing batch workloads with fair queuing, resource quotas, and priority scheduling.

## What is Kueue?

**Kueue** is a Kubernetes-native job queueing system that provides:

- **Resource Quotas**: Limit resources consumed by jobs per namespace/team
- **Fair Sharing**: Distribute resources fairly across multiple tenants
- **Priority & Preemption**: Higher priority jobs can preempt lower priority ones
- **Borrowing**: Teams can borrow unused quota from others
- **Batch Scheduling**: Jobs wait in queue until resources are available

### Kueue vs Standard Kubernetes Jobs

| Aspect | Standard K8s Jobs | Kueue |
|--------|-------------------|-------|
| Resource Management | First-come, first-served | Quota-based with fair sharing |
| Queuing | No native queuing | Jobs queue until resources available |
| Multi-tenancy | Manual namespace quotas | Built-in cohorts and borrowing |
| Priority | Basic priority classes | Advanced preemption policies |
| Visibility | Limited job status | Queue depth, wait times, borrowing status |

### Why LocalQueue and ClusterQueue? (Kueue vs Slurm)

In **Slurm**, queues (partitions) are simple and flat:
- One level of queues defined by the admin
- Users submit directly to a partition
- No namespace isolation—all users share the same view

**Kueue uses a two-level queue hierarchy** because Kubernetes is fundamentally multi-tenant:

| Concept | Kueue | Slurm Equivalent |
|---------|-------|------------------|
| **ClusterQueue** | Cluster-wide resource pool with quotas | Partition (e.g., `gpu`, `batch`) |
| **LocalQueue** | Namespace-scoped entry point | No equivalent—users submit directly |
| **Namespace** | Isolation boundary for teams | No equivalent—shared system |

**Why this design?**

1. **Multi-tenancy by default**: Kubernetes namespaces isolate teams. Users only see their LocalQueue, not the cluster-wide ClusterQueue. In Slurm, all users see all partitions.

2. **Delegation without cluster access**: Team leads can manage their LocalQueue without cluster-admin privileges. Slurm requires admin access to modify partitions.

3. **Mapping flexibility**: Multiple LocalQueues can point to one ClusterQueue (shared pool), or each can have dedicated ClusterQueues (isolated pools).

4. **Kubernetes-native RBAC**: Permissions are per-namespace. A user in `team-a` namespace can submit to `team-a-queue` but cannot access `team-b` resources.

```
┌─────────────────────────────────────────────────────────────┐
│                     ClusterQueue                            │
│                  (8 CPU, 16Gi memory)                       │
└─────────────────────────────────────────────────────────────┘
         ▲                    ▲                    ▲
         │                    │                    │
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   LocalQueue    │  │   LocalQueue    │  │   LocalQueue    │
│   (team-a ns)   │  │   (team-b ns)   │  │   (team-c ns)   │
└─────────────────┘  └─────────────────┘  └─────────────────┘
         ▲                    ▲                    ▲
         │                    │                    │
      Team A               Team B               Team C
      (isolated)           (isolated)           (isolated)
```

In Slurm, this would be:

```
┌─────────────────────────────────────────────────────────────┐
│                       Partition                             │
│                  (shared by all users)                      │
└─────────────────────────────────────────────────────────────┘
         ▲                    ▲                    ▲
         │                    │                    │
      User A               User B               User C
      (no isolation)       (no isolation)       (no isolation)
```

## Prerequisites

- Azure CLI installed
- `kubectl` installed
- An Azure subscription

## Step 1: Create the AKS Cluster

```bash
# Login to Azure
az login

# Set variables
RESOURCE_GROUP="myKueueResourceGroup"
CLUSTER_NAME="myKueueCluster"
LOCATION="eastus"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create AKS cluster optimized for batch workloads
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --node-count 3 \
  --node-vm-size Standard_D4s_v3 \
  --enable-managed-identity \
  --network-plugin azure \
  --generate-ssh-keys

# Add options   --enable-private-cluster --disable-public-fqdn for production systems


# Get credentials (so kubetctl starts to work with this k8s cluster)
az aks get-credentials \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME
```
Confirm your context and connectivity:
```bash
kubectl config current-context
kubectl config get-contexts
kubectl cluster-info
kubectl get ns
kubectl get nodes
```



## Step 2: Install Kueue


Install the latest stable version of Kueue:

```bash
# Install Kueue (check https://kueue.sigs.k8s.io for latest version)
KUEUE_VERSION=v0.6.2
kubectl apply --server-side -f https://github.com/kubernetes-sigs/kueue/releases/download/${KUEUE_VERSION}/manifests.yaml

# Wait for Kueue to be ready
kubectl wait --for=condition=Available deployment/kueue-controller-manager \
  -n kueue-system --timeout=300s
```

Verify the installation:

```bash
kubectl get pods -n kueue-system
```

Expected output:

```
NAME                                        READY   STATUS    RESTARTS   AGE
kueue-controller-manager-xxxxxxxxx-xxxxx    1/1     Running   0          60s
```

## Step 3: Configure Kueue Resources

Kueue uses three main concepts:

1. **ResourceFlavor**: Defines types of resources (e.g., on-demand vs spot nodes)
2. **ClusterQueue**: Cluster-level queue that manages resource quotas
3. **LocalQueue**: Namespace-level queue that points to a ClusterQueue

### Create a ResourceFlavor

```bash
kubectl apply -f - <<EOF
apiVersion: kueue.x-k8s.io/v1
kind: ResourceFlavor
metadata:
  name: default-flavor
EOF
```

### Create a ClusterQueue

```bash
kubectl apply -f - <<EOF
apiVersion: kueue.x-k8s.io/v1
kind: ClusterQueue
metadata:
  name: cluster-queue
spec:
  namespaceSelector: {}  # Allow all namespaces
  resourceGroups:
  - coveredResources: ["cpu", "memory"]
    flavors:
    - name: default-flavor
      resources:
      - name: "cpu"
        nominalQuota: 8        # 8 CPU cores total
      - name: "memory"
        nominalQuota: 16Gi     # 16GB memory total
EOF
```

### Create a LocalQueue

```bash
# Create namespace for batch jobs
kubectl create namespace batch-jobs

# Create LocalQueue in the namespace
kubectl apply -f - <<EOF
apiVersion: kueue.x-k8s.io/v1
kind: LocalQueue
metadata:
  namespace: batch-jobs
  name: user-queue
spec:
  clusterQueue: cluster-queue
EOF
```

Verify the queue status:

```bash
kubectl get clusterqueues
kubectl get localqueues -n batch-jobs
```

## Step 4: Submit a Batch Job

Jobs must include a `kueue.x-k8s.io/queue-name` label to be managed by Kueue:

```bash
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: sample-batch-job
  namespace: batch-jobs
  labels:
    kueue.x-k8s.io/queue-name: user-queue
spec:
  parallelism: 3
  completions: 3
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command: ["sh", "-c", "echo 'Processing batch item...' && sleep 30 && echo 'Done!'"]
        resources:
          requests:
            cpu: "500m"
            memory: "256Mi"
      restartPolicy: Never
  backoffLimit: 4
EOF
```

## Step 5: Monitor Job Progress

### Check Workload Status

Kueue creates a `Workload` object for each job:

```bash
kubectl get workloads -n batch-jobs
```

Example output:

```
NAME                     QUEUE        ADMITTED BY     AGE
job-sample-batch-job     user-queue   cluster-queue   30s
```

### View Queue Status

```bash
# Check ClusterQueue status (shows used vs available resources)
kubectl describe clusterqueue cluster-queue

# Check pending workloads
kubectl get workloads -n batch-jobs -o custom-columns=\
'NAME:.metadata.name,QUEUE:.spec.queueName,ADMITTED:.status.admission.clusterQueue,STATE:.status.conditions[-1].type'
```

### Watch Job Progress

```bash
kubectl get jobs -n batch-jobs --watch
kubectl get pods -n batch-jobs
```

### View Job Logs

```bash
kubectl logs -n batch-jobs -l job-name=sample-batch-job --follow
```

## Step 6: Example - Multiple Jobs with Queuing

Submit multiple jobs to see Kueue's queuing behavior:

```bash
# Submit 5 jobs that each request 2 CPUs
for i in {1..5}; do
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: batch-job-$i
  namespace: batch-jobs
  labels:
    kueue.x-k8s.io/queue-name: user-queue
spec:
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command: ["sh", "-c", "echo 'Job $i started' && sleep 60 && echo 'Job $i complete'"]
        resources:
          requests:
            cpu: "2"
            memory: "1Gi"
      restartPolicy: Never
  backoffLimit: 2
EOF
done
```

Watch how Kueue queues jobs based on available quota:

```bash
# Some jobs will be "Admitted", others will be "Pending"
kubectl get workloads -n batch-jobs

# Watch as jobs complete and queued jobs get admitted
watch kubectl get workloads -n batch-jobs
```

## Useful Commands

```bash
# View all Kueue resources
kubectl get resourceflavors,clusterqueues,localqueues,workloads -A

# Check queue utilization
kubectl describe clusterqueue cluster-queue | grep -A 20 "Status:"

# List pending workloads (not yet admitted)
kubectl get workloads -A -o jsonpath='{range .items[?(@.status.admission==null)]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}'

# Delete completed jobs
kubectl delete jobs -n batch-jobs --field-selector status.successful=1
```

## Cleanup

Delete the sample jobs:

```bash
kubectl delete jobs --all -n batch-jobs
```

Delete Kueue:

```bash
kubectl delete -f https://github.com/kubernetes-sigs/kueue/releases/download/${KUEUE_VERSION}/manifests.yaml
```

Delete the AKS cluster:

```bash
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

## Additional Resources

- [Kueue Documentation](https://kueue.sigs.k8s.io/)
- [Kueue GitHub Repository](https://github.com/kubernetes-sigs/kueue)
- [AKS Best Practices for Batch Workloads](https://docs.microsoft.com/azure/aks/best-practices)
- [Kubernetes Jobs Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/job/)

