param(
    [switch]$UpdateHosts,
    [switch]$Cleanup
)

$VMName = "k3s-demo"

# Cleanup hosts file if requested
if ($Cleanup) {
    Write-Host "Cleaning up hosts file..."
    $hostsPath = "$env:windir\System32\drivers\etc\hosts"
    $hostsContent = Get-Content $hostsPath
    if ($hostsContent -match "nginx.local") {
        $newContent = $hostsContent | Where-Object { $_ -notmatch "nginx.local" }
        Set-Content -Path $hostsPath -Value $newContent -Force
        Write-Host "Removed nginx.local from hosts file"
    } else {
        Write-Host "No nginx.local entry found in hosts file"
    }
    Write-Host "Cleaning up VM..."
    multipass delete --purge $VMName
    exit 0
}

Write-Host "Launching VM '$VMName'..."

multipass launch --name $VMName --cpus 2 --mem 2G --disk 10G 22.04 --cloud-init .\init\cloud-init.yaml

Write-Host "`nVM '$VMName' created. To access:"
Write-Host "  multipass shell $VMName"

# Wait for k3s to be ready
Write-Host "`nWaiting for k3s to be ready..."
Start-Sleep -Seconds 30

# Get VM IP and display dashboard information
$VMInfo = multipass info $VMName --format json | ConvertFrom-Json
$VMIP = $VMInfo.info.$VMName.ipv4[0]

Write-Host "`nKubernetes Dashboard Information:"
Write-Host "Dashboard URL: https://$VMIP:30443"
Write-Host "To get the access token, run:"
Write-Host "  multipass exec $VMName -- kubectl -n kubernetes-dashboard create token admin-user"
Write-Host "`nNote: You may need to accept the self-signed certificate warning in your browser"

# Copy examples to VM
Write-Host "`nCopying example files to VM..."
multipass mount examples "$VMName:/home/ubuntu/examples"

Write-Host "`nExample files have been copied to /home/ubuntu/examples in the VM"
Write-Host "To deploy the nginx example, run:"
Write-Host "  multipass shell $VMName"
Write-Host "Then follow the instructions in /home/ubuntu/examples/nginx/README.md"

# Update hosts file if requested
if ($UpdateHosts) {
    Write-Host "`nUpdating hosts file..."
    $hostsPath = "$env:windir\System32\drivers\etc\hosts"
    $hostsContent = Get-Content $hostsPath
    $nginxEntry = "$VMIP nginx.local"

    if (-not ($hostsContent -match "nginx.local")) {
        Add-Content -Path $hostsPath -Value "`n$nginxEntry" -Force
        Write-Host "Added nginx.local to hosts file"
    } else {
        $newContent = $hostsContent -replace ".*nginx.local", $nginxEntry
        Set-Content -Path $hostsPath -Value $newContent -Force
        Write-Host "Updated nginx.local in hosts file"
    }
    Write-Host "`nYou can now access the cluster using at: https://nginx.local:30443"
} else {
    Write-Host "`nTo access the cluster via nginx.local (required for the nginx example), add this line to your hosts file:"
    Write-Host "$VMIP nginx.local"
}

Write-Host "`nTo clean up the vm run: multipass delete --purge $VMName"
Write-Host "To clean up the hosts file run: .\create-k3s-node.ps1 -Cleanup"
