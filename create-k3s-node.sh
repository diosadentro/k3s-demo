#!/bin/bash
set -e

# Parse command line arguments
UPDATE_HOSTS=false
CLEANUP=false
VM_NAME="k3s-demo"
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --update-hosts) UPDATE_HOSTS=true ;;
        --cleanup) CLEANUP=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Cleanup hosts file if requested
if [ "$CLEANUP" = true ]; then
    echo "Cleaning up hosts file..."
    if grep -q "nginx.local" /etc/hosts; then
        sudo sed -i.bak "/nginx.local/d" /etc/hosts
        echo "Removed nginx.local from hosts file"
    else
        echo "No nginx.local entry found in hosts file"
    fi
    echo "Cleaning up VM..."
    multipass delete --purge "$VM_NAME"
    exit 0
fi

echo "Launching VM '$VM_NAME'..."

multipass launch --name "$VM_NAME" --cpus 2 --mem 2G --disk 10G 22.04 \
  --cloud-init init/cloud-init.yaml

echo "VM '$VM_NAME' created. To access:"
echo "  multipass shell $VM_NAME"

# Wait for k3s to be ready
echo "Waiting for k3s to be ready..."
sleep 30

# Get VM IP and display dashboard information
VM_IP=$(multipass info "$VM_NAME" --format json | jq -r '.info["'"$VM_NAME"'"].ipv4[0]')
echo -e "\nKubernetes Dashboard Information:"
echo "Dashboard URL: https://$VM_IP:30443"
echo "To get the access token, run:"
echo "  multipass exec $VM_NAME -- kubectl -n kubernetes-dashboard create token admin-user"
echo -e "\nNote: You may need to accept the self-signed certificate warning in your browser"

# Copy examples to VM
echo -e "\nCopying example files to VM..."
multipass mount examples "$VM_NAME:/home/ubuntu/examples"

echo -e "\nExample files have been copied to /home/ubuntu/examples in the VM"
echo "To deploy the nginx example, run:"
echo "  multipass shell $VM_NAME"
echo "Then follow the instructions in /home/ubuntu/examples/nginx/README.md"

# Update hosts file if requested
if [ "$UPDATE_HOSTS" = true ]; then
    echo -e "\nUpdating hosts file..."
    if ! grep -q "nginx.local" /etc/hosts; then
        echo "$VM_IP nginx.local" | sudo tee -a /etc/hosts
        echo "Added nginx.local to hosts file"
    else
        sudo sed -i.bak "s/.*nginx.local/$VM_IP nginx.local/" /etc/hosts
        echo "Updated nginx.local in hosts file"
    fi
    echo -e "\nYou can now access the cluster using at: https://nginx.local:30443"
else
    echo -e "\nTo access the cluster via nginx.local (required for the nginx example), add this line to your hosts file:"
    echo "$VM_IP nginx.local"
fi

echo "To clean up the vm run: multipass delete --purge $VM_NAME"
echo "To clean up the hosts file run: $0 --cleanup"