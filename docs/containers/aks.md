# AKS

**Azure Kubernetes Service (AKS)** is Microsoft's managed Kubernetes offering. It simplifies deploying and operating Kubernetes by offloading operational overhead to Azure. Here is a quick example on how to deploy a small aks cluster in azure.

## Prerequisites

- An active Azure subscription
- Azure CLI installed ([Install guide](https://docs.microsoft.com/cli/azure/install-azure-cli))
- `kubectl` installed (can be installed via Azure CLI)

## Step 1: Login to Azure

```bash
az login
```

This opens a browser for authentication. For non-interactive login (CI/CD), use:

```bash
az login --service-principal -u <app-id> -p <password> --tenant <tenant-id>
```

## Step 2: Set Your Subscription (Optional)

If you have multiple subscriptions, set the one you want to use:

```bash
az account set --subscription "<subscription-name-or-id>"
```

Verify the current subscription:

```bash
az account show --output table
```

## Step 3: Create a Resource Group

Create a resource group to hold your AKS cluster:

```bash
az group create \
  --name myAKSResourceGroup \
  --location eastus
```

## Step 4: Create the AKS Cluster

Create a basic AKS cluster with default settings:

```bash
az aks create \
  --resource-group myAKSResourceGroup \
  --name myAKSCluster \
  --node-count 2 \
  --generate-ssh-keys
```

### Common Options

| Option | Description |
|--------|-------------|
| `--node-count` | Number of nodes in the default node pool |
| `--node-vm-size` | VM size for nodes (e.g., `Standard_DS2_v2`) |
| `--kubernetes-version` | Specific Kubernetes version |
| `--enable-managed-identity` | Use managed identity (recommended) |
| `--network-plugin` | Network plugin: `azure` or `kubenet` |
| `--zones` | Availability zones (e.g., `1 2 3`) |

### Example with More Options

```bash
az aks create \
  --resource-group myAKSResourceGroup \
  --name myAKSCluster \
  --node-count 3 \
  --node-vm-size Standard_DS2_v2 \
  --kubernetes-version 1.28.3 \
  --enable-managed-identity \
  --network-plugin azure \
  --zones 1 2 3 \
  --generate-ssh-keys
```

### Private Cluster (No Public IPs)

If your organization restricts public IP usage, create a private AKS cluster:

```bash
az aks create \
  --resource-group myAKSResourceGroup \
  --name myAKSCluster \
  --node-count 3 \
  --enable-managed-identity \
  --enable-private-cluster \
  --disable-public-fqdn \
  --network-plugin azure \
  --generate-ssh-keys
```

**Note:** Private clusters require access from within the VNet (e.g., via VPN, ExpressRoute, or a jump box VM).

## Step 5: Install kubectl (If Not Installed)

```bash
az aks install-cli
```

## Step 6: Connect to the Cluster

Get credentials and configure `kubectl`:

```bash
az aks get-credentials \
  --resource-group myAKSResourceGroup \
  --name myAKSCluster
```

## Step 7: Verify the Connection

Check the cluster nodes:

```bash
kubectl get nodes
```

Expected output:

```
NAME                                STATUS   ROLES   AGE   VERSION
aks-nodepool1-12345678-vmss000000   Ready    agent   5m    v1.28.3
aks-nodepool1-12345678-vmss000001   Ready    agent   5m    v1.28.3
```

## Step 8: Deploy a Sample Application (Optional)

Test your cluster with a sample deployment:

```bash
kubectl create deployment nginx --image=nginx
```

### Expose with Internal Load Balancer (Private IP Only)

Create a service with an internal load balancer (no public IP):

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: nginx
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: nginx
EOF
```

Get the internal IP:

```bash
kubectl get service nginx --watch
```

The `EXTERNAL-IP` will be a private IP from your VNet subnet.

### Test the Application

Since there's no public IP, use port forwarding to access the service from your local machine:

```bash
kubectl port-forward service/nginx 8080:80
```

**Command Breakdown:**

| Part | Description |
|------|-------------|
| `kubectl port-forward` | Creates a tunnel between your local machine and the cluster |
| `service/nginx` | The target resource (service named "nginx"). Can also use `pod/<pod-name>` or `deployment/<name>` |
| `8080:80` | `<local-port>:<remote-port>` - Maps your local port 8080 to the service's port 80 |

**How It Works:**

1. kubectl opens a connection to the Kubernetes API server
2. The API server forwards traffic to the specified service/pod
3. Your local port 8080 becomes a tunnel to port 80 on the nginx service
4. Traffic flows: `localhost:8080` → `API Server` → `Service` → `Pod`

**Test the Connection:**

In a new terminal (keep port-forward running):

```bash
curl http://localhost:8080
```

Or open `http://localhost:8080` in your browser.

**Expected Output:**

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
</html>
```

**Stop Port Forwarding:**

Press `Ctrl+C` in the terminal running the port-forward command.

**Additional Options:**

```bash
# Listen on all interfaces (access from other machines on your network)
kubectl port-forward service/nginx 8080:80 --address 0.0.0.0

# Use a random local port
kubectl port-forward service/nginx :80

# Forward directly to a pod
kubectl port-forward pod/nginx-xxxxxx-xxxxx 8080:80
```

### Alternative: ClusterIP (No Load Balancer)

For cluster-internal access only:

```bash
kubectl expose deployment nginx --port=80 --type=ClusterIP
```

Access using port-forward or from within the cluster:

```bash
kubectl port-forward service/nginx 8080:80
```

## Useful Commands

### View Cluster Information

```bash
az aks show \
  --resource-group myAKSResourceGroup \
  --name myAKSCluster \
  --output table
```

### Scale the Cluster

```bash
az aks scale \
  --resource-group myAKSResourceGroup \
  --name myAKSCluster \
  --node-count 5
```

### Upgrade the Cluster

Check available upgrades:

```bash
az aks get-upgrades \
  --resource-group myAKSResourceGroup \
  --name myAKSCluster \
  --output table
```

Perform the upgrade:

```bash
az aks upgrade \
  --resource-group myAKSResourceGroup \
  --name myAKSCluster \
  --kubernetes-version <version>
```

### Stop the Cluster (Save Costs)

```bash
az aks stop \
  --resource-group myAKSResourceGroup \
  --name myAKSCluster
```

### Start the Cluster

```bash
az aks start \
  --resource-group myAKSResourceGroup \
  --name myAKSCluster
```

## Cleanup

Delete the cluster and all associated resources:

```bash
az group delete \
  --name myAKSResourceGroup \
  --yes \
  --no-wait
```

**About the Node Resource Group:**

When AKS is created, Azure automatically creates a second resource group named `MC_<resource-group>_<cluster-name>_<location>` (e.g., `MC_myAKSResourceGroup_myAKSCluster_eastus`). This contains the underlying infrastructure:

- Virtual Machine Scale Sets (nodes)
- Virtual Network / Subnet
- Network Security Groups
- Load Balancers
- Managed Disks
- Public IPs (if applicable)

**What happens when you delete the main resource group:**

| Action | Node Resource Group (MC_*) |
|--------|---------------------------|
| Delete main resource group | ✅ Automatically deleted |
| Delete AKS cluster only | ✅ Automatically deleted |
| Stop AKS cluster | ❌ Not deleted (VMs deallocated) |

You do **not** need to stop the cluster before deleting—the node resource group is cleaned up automatically.

**Warning:** Never manually delete resources inside the `MC_*` resource group. AKS manages it and manual changes can break your cluster.

## Additional Resources

- [AKS Documentation](https://docs.microsoft.com/azure/aks/)
- [AKS Best Practices](https://docs.microsoft.com/azure/aks/best-practices)
- [Azure CLI AKS Reference](https://docs.microsoft.com/cli/azure/aks)

