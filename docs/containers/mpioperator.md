# AKS+MPIOperator

This tutorial demonstrates how to provision an Azure Kubernetes Service (AKS) cluster, install the MPI Operator, and run a simple MPI application.

## What is a Kubernetes Operator?

A **Kubernetes Operator** is a software extension that uses custom resources to manage applications and their components. Operators follow Kubernetes principles, notably the control loop pattern, to automate tasks beyond what Kubernetes provides out-of-the-box.

Key characteristics of operators:
- **Custom Resource Definitions (CRDs)**: Extend the Kubernetes API with domain-specific resources
- **Controllers**: Watch for changes to resources and reconcile the actual state with the desired state
- **Domain Knowledge**: Encode operational expertise (deployment, scaling, recovery) into software

Think of an operator as a robot sysadmin that understands how to deploy, configure, and manage a specific application on Kubernetes.

## What is the MPI Operator?

The **MPI Operator** is a Kubernetes operator developed by Kubeflow that simplifies running Message Passing Interface (MPI) applications on Kubernetes clusters. It introduces the `MPIJob` custom resource, which allows you to declaratively define MPI workloads.

The MPI Operator handles:
- **SSH Key Management**: Automatically generates and distributes SSH keys between launcher and worker pods
- **Pod Coordination**: Ensures workers are ready before the launcher starts
- **Hostfile Generation**: Creates the MPI hostfile with worker addresses
- **Job Lifecycle**: Manages job completion, failure, and cleanup

### MPIJob Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      MPIJob                             │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┐    SSH     ┌─────────────────────────┐ │
│  │  Launcher   │◄──────────►│       Workers           │ │
│  │    Pod      │            │  ┌───────┐ ┌───────┐    │ │
│  │             │   mpirun   │  │Worker │ │Worker │... │ │
│  │  (rank 0)   │───────────►│  │  0    │ │  1    │    │ │
│  └─────────────┘            │  └───────┘ └───────┘    │ │
│                             └─────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## MPI Operator vs. Slurm: A Comparison

| Aspect | MPI Operator (Kubernetes) | Slurm |
|--------|---------------------------|-------|
| **Infrastructure** | Cloud-native, containerized | Traditional HPC clusters, bare-metal |
| **Resource Management** | Kubernetes scheduler, dynamic scaling | Slurm scheduler, static partitions |
| **Job Definition** | YAML manifests (MPIJob CRD) | Batch scripts (sbatch) |
| **Environment** | Container images | Shared filesystems, modules |
| **Scaling** | Auto-scaling node pools, pay-per-use | Fixed cluster size |
| **Isolation** | Container-level isolation | Process-level isolation |
| **Networking** | Kubernetes CNI (overlay networks) | High-speed interconnects (InfiniBand) |
| **Learning Curve** | Requires Kubernetes knowledge | Familiar to HPC users |

### When to Use Each

**Choose MPI Operator when:**
- Running MPI workloads in cloud environments
- Need elastic scaling and cost optimization
- Integrating with cloud-native CI/CD pipelines
- Already invested in Kubernetes infrastructure

**Choose Slurm when:**
- Running on dedicated HPC hardware with InfiniBand
- Require maximum inter-node communication performance
- Existing HPC workflows and user familiarity
- Need fine-grained control over node placement and topology
- Running tightly-coupled simulations at extreme scale

### Example Comparison

**Slurm batch script:**
```bash
#!/bin/bash
#SBATCH --job-name=mpi-hello
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=2
#SBATCH --time=00:10:00

module load openmpi
mpirun ./hello_world
```

**MPI Operator equivalent:**
```yaml
apiVersion: kubeflow.org/v2beta1
kind: MPIJob
metadata:
  name: mpi-hello
spec:
  slotsPerWorker: 2
  mpiReplicaSpecs:
    Launcher:
      replicas: 1
      template:
        spec:
          containers:
          - name: launcher
            image: my-mpi-app:latest
            command: ["mpirun", "-n", "8", "./hello_world"]
    Worker:
      replicas: 4
      template:
        spec:
          containers:
          - name: worker
            image: my-mpi-app:latest
```

---

## Prerequisites

- Azure CLI installed and configured
- kubectl installed
- An active Azure subscription
- Helm 3.x installed

## Step 1: Set Environment Variables

```bash
export RESOURCE_GROUP="aks-mpi-rg"
export CLUSTER_NAME="aks-mpi-cluster"
export LOCATION="eastus"
export NODE_COUNT=3
export NODE_VM_SIZE="Standard_D4s_v3"
```

## Step 2: Create Resource Group

```bash
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION
```

## Step 3: Create AKS Cluster

Create an AKS cluster with multiple nodes to support MPI workloads:

```bash
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --node-count $NODE_COUNT \
  --node-vm-size $NODE_VM_SIZE \
  --generate-ssh-keys \
  --enable-managed-identity
```

## Step 4: Get AKS Credentials

```bash
az aks get-credentials \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --overwrite-existing
```

Verify the cluster is running:

```bash
kubectl get nodes
```

Expected output:
```
NAME                                STATUS   ROLES   AGE   VERSION
aks-nodepool1-12345678-vmss000000   Ready    agent   5m    v1.28.x
aks-nodepool1-12345678-vmss000001   Ready    agent   5m    v1.28.x
aks-nodepool1-12345678-vmss000002   Ready    agent   5m    v1.28.x
```

## Step 5: Install MPI Operator

The MPI Operator makes it easy to run MPI jobs on Kubernetes.

### Option A: Install using kubectl

```bash
kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/kubeflow/mpi-operator/v0.7.0/deploy/v2beta1/mpi-operator.yaml
```

> **Note:** The `--server-side` flag is required because the MPI Operator's CustomResourceDefinition (CRD) is too large for client-side apply. By default, `kubectl apply` stores the last-applied-configuration as an annotation, which has a 262KB limit. Server-side apply avoids this limitation by having the API server track field ownership instead of using annotations. The `--force-conflicts` flag is needed to resolve field ownership conflicts with Kubernetes' built-in clusterrole-aggregation-controller.

### Option B: Install using Helm (Alternative)

```bash
helm repo add mpi-operator https://kubeflow.github.io/mpi-operator
helm repo update
helm install mpi-operator mpi-operator/mpi-operator \
  --namespace mpi-operator \
  --create-namespace
```

### Verify MPI Operator Installation

```bash
kubectl get pods -n mpi-operator
```

Expected output:
```
NAME                            READY   STATUS    RESTARTS   AGE
mpi-operator-xxxxxxxxxx-xxxxx   1/1     Running   0          1m
```

## Step 6: Create a Simple MPI Application

Create a file named `mpi-hello-world.yaml`:

```yaml
apiVersion: kubeflow.org/v2beta1
kind: MPIJob
metadata:
  name: mpi-hello-world
spec:
  slotsPerWorker: 2
  runPolicy:
    cleanPodPolicy: Running
  sshAuthMountPath: /home/mpiuser/.ssh
  mpiReplicaSpecs:
    Launcher:
      replicas: 1
      template:
        spec:
          containers:
          - name: mpi-launcher
            image: mpioperator/mpi-pi:openmpi
            securityContext:
              runAsUser: 1000
            command:
            - mpirun
            args:
            - --oversubscribe
            - -n
            - "4"
            - /home/mpiuser/pi
            resources:
              limits:
                cpu: "1"
                memory: "1Gi"
    Worker:
      replicas: 2
      template:
        spec:
          containers:
          - name: mpi-worker
            image: mpioperator/mpi-pi:openmpi
            securityContext:
              runAsUser: 1000
            command:
            - /usr/sbin/sshd
            args:
            - -De
            - -f
            - /home/mpiuser/.sshd_config
            resources:
              limits:
                cpu: "2"
                memory: "2Gi"
```

## Step 7: Deploy the MPI Job

```bash
kubectl apply -f mpi-hello-world.yaml
```

## Step 8: Monitor the MPI Job

### Check job status

```bash
kubectl get mpijob mpi-hello-world
```

### Watch pods

```bash
kubectl get pods -l training.kubeflow.org/job-name=mpi-hello-world -w
```

### Check launcher logs

```bash
kubectl logs -f -l training.kubeflow.org/job-name=mpi-hello-world --max-log-requests=10
```

Expected output (Pi calculation example):
```
Workers: 4
Rank 0 on host mpi-hello-world-launcher
Rank 1 on host mpi-hello-world-launcher
Rank 2 on host mpi-hello-world-launcher
Rank 3 on host mpi-hello-world-launcher
pi is approximately 3.1412433000000002
```

> **Note:** Once the job completes successfully, the launcher pod is terminated. If you try to retrieve logs after completion, you'll get an error because the pod no longer exists. Use `kubectl logs` while the job is running, or check the job status with `kubectl get mpijob`.

## Step 9: Custom MPI Application Example

Here's an example running a custom "Hello World" MPI program:

Create `mpi-custom-hello.yaml`:

```yaml
apiVersion: kubeflow.org/v2beta1
kind: MPIJob
metadata:
  name: mpi-custom-hello
spec:
  slotsPerWorker: 2
  runPolicy:
    cleanPodPolicy: Running
  sshAuthMountPath: /home/mpiuser/.ssh
  mpiReplicaSpecs:
    Launcher:
      replicas: 1
      template:
        spec:
          containers:
          - name: mpi-launcher
            image: mpioperator/mpi-pi:openmpi
            securityContext:
              runAsUser: 1000
            command:
            - mpirun
            args:
            - --oversubscribe
            - -n
            - "6"
            - bash
            - -c
            - |
              if [ $OMPI_COMM_WORLD_RANK -eq 0 ]; then
                echo "=== Hostfile ===" && cat /etc/mpi/hostfile && echo "================"
              fi
              echo "Hello from rank $OMPI_COMM_WORLD_RANK of $OMPI_COMM_WORLD_SIZE on $(hostname)"
            resources:
              limits:
                cpu: "500m"
                memory: "512Mi"
    Worker:
      replicas: 3
      template:
        spec:
          containers:
          - name: mpi-worker
            image: mpioperator/mpi-pi:openmpi
            securityContext:
              runAsUser: 1000
            command:
            - /usr/sbin/sshd
            args:
            - -De
            - -f
            - /home/mpiuser/.sshd_config
            resources:
              limits:
                cpu: "1"
                memory: "1Gi"
```

Deploy the custom job:

```bash
kubectl apply -f mpi-custom-hello.yaml
```

## Step 10: Running Real HPC Applications (e.g., LAMMPS)

Running real HPC applications like LAMMPS with the MPI Operator is **not straightforward**. Unlike traditional HPC environments where you simply load a module and run `mpirun`, the MPI Operator requires specially prepared container images.

### Why Standard HPC Images Don't Work

The official LAMMPS Docker image (`lammps/lammps:stable`) **will not work** with the MPI Operator because:

1. **No SSH daemon**: MPI Operator uses SSH to coordinate between launcher and worker pods
2. **No mpiuser setup**: The operator expects a specific user configuration with SSH keys
3. **Wrong SSH paths**: The `sshAuthMountPath` must match where the image expects SSH keys

### What You Need to Build

To run LAMMPS (or any HPC application) with MPI Operator, you must build a custom Docker image that includes:

```dockerfile
# Example Dockerfile structure (not complete)
FROM mpioperator/mpi-pi:openmpi

# Install LAMMPS dependencies
RUN apt-get update && apt-get install -y \
    build-essential cmake libfftw3-dev ...

# Build LAMMPS with MPI support
RUN git clone https://github.com/lammps/lammps.git && \
    cd lammps && mkdir build && cd build && \
    cmake ../cmake -DPKG_MOLECULE=yes -DBUILD_MPI=yes ... && \
    make -j$(nproc) && make install

# The base image already has SSH daemon configured for mpiuser
```

### The Hidden Complexity

This illustrates a key limitation of MPI Operator: **you cannot easily use existing HPC container images**. Each application requires:

- Rebuilding on top of an MPI Operator-compatible base image
- Ensuring SSH daemon runs as the worker command
- Matching user IDs and SSH paths with the operator's expectations
- Testing the full launcher/worker coordination

For teams already using containerized HPC workflows (e.g., with Singularity/Apptainer on Slurm), this is significant rework.

## Step 11: Job Completion and Cleanup

### Check job completion status

```bash
kubectl get mpijob mpi-hello-world -o jsonpath='{.status.conditions[-1].type}'
```

### Delete MPI jobs

```bash
kubectl delete mpijob mpi-hello-world
kubectl delete mpijob mpi-custom-hello
```

### Uninstall MPI Operator

```bash
# If installed via kubectl
kubectl delete --ignore-not-found -f https://raw.githubusercontent.com/kubeflow/mpi-operator/v0.7.0/deploy/v2beta1/mpi-operator.yaml

# If installed via Helm
helm uninstall mpi-operator -n mpi-operator
```

## Step 12: Clean Up Azure Resources

```bash
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

## Troubleshooting

### Common Issues

1. **Pods stuck in Pending state**
   ```bash
   kubectl describe pod <pod-name>
   ```
   Check for resource constraints or node availability.

2. **SSH connection failures between workers**
   ```bash
   kubectl logs <launcher-pod-name>
   ```
   Ensure the SSH auth mount path is correctly configured.

3. **MPI Operator not creating jobs**
   ```bash
   kubectl logs -n mpi-operator deployment/mpi-operator
   ```

### Useful Commands

```bash
# Get all MPI jobs
kubectl get mpijob

# Describe MPI job details
kubectl describe mpijob mpi-hello-world

# Get events related to MPI job
kubectl get events --field-selector involvedObject.name=mpi-hello-world
```

## Additional Resources

- [MPI Operator GitHub Repository](https://github.com/kubeflow/mpi-operator)
- [Kubeflow MPI Training Documentation](https://www.kubeflow.org/docs/components/training/mpi/)
- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Open MPI Documentation](https://www.open-mpi.org/doc/)
- [MPI Operator overview](https://medium.com/kubeflow/introduction-to-kubeflow-mpi-operator-and-industry-adoption-296d5f2e6edc)

