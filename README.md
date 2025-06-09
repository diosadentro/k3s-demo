# K3s Demo with Nginx Example

This project demonstrates setting up a single-node K3s cluster using Multipass and includes a complete Nginx deployment example.

## Prerequisites

- [Multipass](https://multipass.run/) installed on your system
- For Windows users: PowerShell
- For Linux/Mac users: Bash

## Quick Start

### Creating the K3s Cluster

1. Run the appropriate script for your system:

   **Linux/Mac:**
   ```bash
   ./create-k3s-node.sh --update-hosts
   ```

   **Windows (NOTE: I have not tested this script.):**
   ```powershell
   .\create-k3s-node.ps1 -UpdateHosts
   ```

   This will:
   - Create a VM with K3s installed
   - Set up the Kubernetes Dashboard
   - Mount the example files
   - Update your hosts file (if --update-hosts/-UpdateHosts is specified)

2. Access the Kubernetes Dashboard:
   - URL: `https://<vm-ip>:30443` or `https://nginx.local:30443` if you updated your hosts file
   - Get the access token:
     ```bash
     multipass exec k3s-demo -- kubectl -n kubernetes-dashboard create token admin-user
     ```

### Deploying the Nginx Example

The example is located in the `examples/nginx` directory and demonstrates:
- Namespace creation
- Deployment with health checks
- Service configuration
- Ingress setup with Traefik

1. SSH into the VM:
   ```bash
   multipass shell k3s-demo
   ```

2. Deploy the Nginx example:
   ```bash
   cd /home/ubuntu/examples/nginx
   kubectl apply -f base/namespace.yaml
   kubectl apply -f base/deployment.yaml
   kubectl apply -f base/service.yaml
   kubectl apply -f base/ingress.yaml
   ```

3. Access the Nginx application:
   - URL: `http://nginx.local`
   - The hosts file entry should have been added automatically if you used --update-hosts

## Project Structure

```
.
├── init/                      # Cloud-init configuration
│   └── cloud-init.yaml        # K3s and dashboard setup
│   └── dashboard-admin.yaml   # Sets up dashboard admin user
├── examples/                  # Kubernetes examples
│   └── nginx/                 # Nginx deployment example
│       └── base/              # Base Kubernetes manifests
│           ├── namespace.yaml
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── ingress.yaml
│           ├── secret.yaml
│           └── configmap.yaml
├── create-k3s-node.sh     # Linux/Mac setup script
└── create-k3s-node.ps1    # Windows setup script
```

## Script Options

Both scripts support the following options:

### Linux/Mac (create-k3s-node.sh)
```bash
./create-k3s-node.sh [--update-hosts] [--cleanup]
```

### Windows (create-k3s-node.ps1)
```powershell
.\create-k3s-node.ps1 [-UpdateHosts] [-Cleanup]
```

Options:
- `--update-hosts` / `-UpdateHosts`: Automatically update the hosts file
- `--cleanup` / `-Cleanup`: Remove the nginx.local entry from the hosts file

## Cleanup

1. Remove the VM:
   ```bash
   multipass delete --purge k3s-demo
   ```

2. Clean up the hosts file:
   ```bash
   # Linux/Mac
   ./create-k3s-node.sh --cleanup

   # Windows
   .\create-k3s-node.ps1 -Cleanup
   ```

## Troubleshooting

### Dashboard Access
- If you can't access the dashboard, verify the VM is running:
  ```bash
  multipass list
  ```
- Check if the dashboard pods are running:
  ```bash
  multipass exec k3s-demo -- kubectl get pods -n kubernetes-dashboard
  ```

### Nginx Example
- Verify Traefik is running:
  ```bash
  multipass exec k3s-demo -- kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik
  ```
- Check the ingress configuration:
  ```bash
  multipass exec k3s-demo -- kubectl describe ingress nginx -n nginx-demo
  ```
- View Traefik logs:
  ```bash
  multipass exec k3s-demo -- kubectl logs -n kube-system -l app.kubernetes.io/name=traefik
  ```