# Complete Deployment Guide for phongmx.org

This guide will walk you through deploying your TodoApp to your VM with SSL certificate for phongmx.org domain.

## Prerequisites Checklist

### ✅ On Your VM:
- [ ] Windows Server with IIS installed
- [ ] .NET 8.0 Hosting Bundle installed
- [ ] Web Deploy 3.6+ installed
- [ ] PowerShell 5.1+ available
- [ ] Administrator access
- [ ] Firewall configured (ports 80, 443, 8172)

### ✅ On Your Development Machine:
- [ ] This TodoApp repository
- [ ] SSL certificate file: `.github\workflows\key\origin.pfx`
- [ ] Certificate password available
- [ ] Network access to your VM

### ✅ DNS Configuration:
- [ ] phongmx.org points to your VM IP address

## Step 1: Prepare Your VM

### 1.1 Install Prerequisites
Run this on your VM as Administrator:

```powershell
# Install IIS with ASP.NET support
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole, IIS-WebServer, IIS-CommonHttpFeatures, IIS-HttpErrors, IIS-HttpRedirect, IIS-ApplicationDevelopment, IIS-NetFxExtensibility45, IIS-ASPNET45, IIS-HealthAndDiagnostics, IIS-HttpLogging, IIS-Security, IIS-RequestFiltering, IIS-Performance, IIS-WebServerManagementTools, IIS-ManagementConsole

# Download and install .NET 8.0 Hosting Bundle
$url = "https://download.microsoft.com/download/8/c/8/8c8eb5c9-d737-4de5-9a94-5b2e527d9e7d/dotnet-hosting-8.0.0-win.exe"
Invoke-WebRequest -Uri $url -OutFile "dotnet-hosting.exe"
Start-Process -FilePath "dotnet-hosting.exe" -ArgumentList "/quiet" -Wait

# Download and install Web Deploy 3.6
$url = "https://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi"
Invoke-WebRequest -Uri $url -OutFile "WebDeploy.msi"
Start-Process -FilePath "WebDeploy.msi" -ArgumentList "/quiet" -Wait

# Restart IIS
iisreset
```

### 1.2 Configure Web Deploy Service
```powershell
# Start and configure Web Deploy service
Start-Service WMSVC
Set-Service WMSVC -StartupType Automatic

# Configure management service to allow remote connections
# This may require manual configuration through IIS Manager
```

### 1.3 Configure Firewall
```powershell
# Allow required ports
New-NetFirewallRule -DisplayName "HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
New-NetFirewallRule -DisplayName "HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow
New-NetFirewallRule -DisplayName "Web Deploy" -Direction Inbound -Protocol TCP -LocalPort 8172 -Action Allow
```

## Step 2: Set Up SSL Certificate

### 2.1 Copy Certificate to VM
First, copy your certificate file to the VM:

```powershell
# On your VM, create SSL directory
New-Item -ItemType Directory -Path "C:\SSL" -Force

# Copy the certificate file from your local machine to VM
# You can use RDP, SCP, or any file transfer method
# Target location: C:\SSL\origin.pfx
```

### 2.2 Import and Configure SSL
Run this on your VM:

```powershell
# Navigate to your project directory (copy scripts to VM first)
cd "C:\Deploy\MVCTodo"  # Adjust path as needed

# Run the quick SSL setup script
.\scripts\quick-ssl-setup.ps1 -CertPassword "your-certificate-password"
```

**OR** manually configure SSL:

```powershell
# Manual SSL configuration
Import-Module WebAdministration

# Import certificate
$password = ConvertTo-SecureString "your-certificate-password" -AsPlainText -Force
$cert = Import-PfxCertificate -FilePath "C:\SSL\origin.pfx" -CertStoreLocation "cert:\LocalMachine\My" -Password $password -Exportable

# Configure IIS bindings
Remove-WebBinding -Name "Default Web Site" -Protocol https -Port 443 -HostHeader "phongmx.org" -ErrorAction SilentlyContinue
New-WebBinding -Name "Default Web Site" -Protocol http -Port 80 -HostHeader "phongmx.org"
New-WebBinding -Name "Default Web Site" -Protocol https -Port 443 -HostHeader "phongmx.org" -SslFlags 1

# Assign certificate
$binding = Get-WebBinding -Name "Default Web Site" -Protocol https -Port 443 -HostHeader "phongmx.org"
$binding.AddSslCertificate($cert.Thumbprint, "my")

Write-Host "SSL configured for phongmx.org"
```

## Step 3: Build and Deploy Application

### 3.1 Build the Package (on your development machine)

```powershell
# In your project directory
cd "C:\Users\phongmx\Documents\GitHub\MVCTodo"

# Build the package
.\scripts\build-package.ps1 -Version "1.0.0" -Configuration Release

# This creates artifacts/TodoApp.1.0.0.zip and setParameters files
```

### 3.2 Deploy Using Web Deploy

#### Option A: Complete SSL + App Deployment
```powershell
# Deploy everything including SSL certificate
.\scripts\deploy-with-ssl.ps1 `
  -PackageFile "artifacts\TodoApp.1.0.0.zip" `
  -Environment production `
  -ServerUrl "https://YOUR_VM_IP:8172/msdeploy.axd" `
  -Username "Administrator" `
  -Password "your-vm-admin-password" `
  -CertificatePath ".github\workflows\key\origin.pfx" `
  -CertificatePassword "your-certificate-password"
```

#### Option B: App Only (SSL already configured)
```powershell
# Deploy just the application
.\scripts\deploy-package.ps1 `
  -PackageFile "artifacts\TodoApp.1.0.0.zip" `
  -Environment production `
  -ServerUrl "https://YOUR_VM_IP:8172/msdeploy.axd" `
  -Username "Administrator" `
  -Password "your-vm-admin-password"
```

#### Option C: Using GitHub Actions
1. Configure secrets in your repository:
   ```
   DEPLOY_USERNAME=Administrator
   DEPLOY_PASSWORD=your-vm-admin-password
   PROD_SERVER_URL=https://YOUR_VM_IP:8172/msdeploy.axd
   CERT_PASSWORD=your-certificate-password
   ```

2. Run the deployment workflow:
   - Go to **Actions** → **"Build and Deploy"**
   - Click **"Run workflow"**
   - Select:
     - Environment: **production**
     - Server URL: `https://YOUR_VM_IP:8172/msdeploy.axd`
     - WhatIf: **false**

## Step 4: Verify Deployment

### 4.1 Check IIS Configuration
On your VM:

```powershell
# Check if site is running
Get-Website | Where-Object Name -eq "Default Web Site"

# Check bindings
Get-WebBinding -Name "Default Web Site"

# Check application pool
Get-IISAppPool | Where-Object Name -eq "DefaultAppPool"

# Check deployed files
Get-ChildItem "C:\inetpub\wwwroot\TodoApp" -ErrorAction SilentlyContinue
```

### 4.2 Test Application Access

```powershell
# Test local access on VM
Invoke-WebRequest -Uri "https://phongmx.org/TodoApp" -UseBasicParsing
Invoke-WebRequest -Uri "http://phongmx.org/TodoApp" -UseBasicParsing  # Should redirect to HTTPS

# Test from your development machine
Invoke-WebRequest -Uri "https://phongmx.org/TodoApp" -UseBasicParsing
```

### 4.3 Browser Testing
Open your browser and navigate to:
- `https://phongmx.org/TodoApp`
- `http://phongmx.org/TodoApp` (should redirect to HTTPS)

You should see the TodoApp login page with:
- Username: `admin`
- Password: `SecurePassword@2024`

## Step 5: Troubleshooting

### Common Issues and Solutions

#### 1. Web Deploy Connection Failed
**Error**: "Could not connect to the remote computer"

**Solutions**:
```powershell
# Check Web Deploy service
Get-Service WMSVC
Start-Service WMSVC

# Test connection
msdeploy -verb:dump -source:webServer,computerName="https://YOUR_VM_IP:8172/msdeploy.axd",userName="Administrator",password="your-password"
```

#### 2. SSL Certificate Issues
**Error**: "SSL certificate not found"

**Solutions**:
```powershell
# Check certificate installation
Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -like "*phongmx.org*" }

# Re-import certificate
$password = ConvertTo-SecureString "your-cert-password" -AsPlainText -Force
Import-PfxCertificate -FilePath "C:\SSL\origin.pfx" -CertStoreLocation "cert:\LocalMachine\My" -Password $password -Exportable
```

#### 3. Application Not Starting
**Error**: HTTP 500 errors

**Solutions**:
```powershell
# Check Event Logs
Get-EventLog -LogName Application -Source "ASP.NET*" -Newest 10

# Check application pool
Start-WebAppPool -Name "DefaultAppPool"

# Verify .NET hosting bundle
dotnet --info

# Check file permissions
icacls "C:\inetpub\wwwroot\TodoApp" /grant "IIS_IUSRS:(OI)(CI)F"
```

#### 4. Domain Not Accessible
**Error**: "This site can't be reached"

**Solutions**:
```powershell
# Check DNS resolution
nslookup phongmx.org

# Check firewall
Test-NetConnection -ComputerName phongmx.org -Port 443
Test-NetConnection -ComputerName phongmx.org -Port 80

# Check IIS bindings
Get-WebBinding -Name "Default Web Site"
```

### Useful Commands

```powershell
# Check deployment status
Get-Website
Get-WebApplication
Get-IISAppPool

# Check SSL certificate
Get-ChildItem Cert:\LocalMachine\My

# Check logs
Get-EventLog -LogName System -Newest 20
Get-EventLog -LogName Application -Newest 20

# Restart services
iisreset
Restart-Service WMSVC
```

## Step 6: Post-Deployment Tasks

### 6.1 Configure Monitoring
```powershell
# Enable IIS logging
Set-WebConfiguration -Filter "/system.webServer/httpLogging" -Value @{dontLog="False"}
```

### 6.2 Set Up Backups
```powershell
# Create backup of application
$backupPath = "C:\Backups\TodoApp_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupPath -Force
Copy-Item "C:\inetpub\wwwroot\TodoApp" $backupPath -Recurse
```

### 6.3 Performance Optimization
```powershell
# Enable compression
Set-WebConfiguration -Filter "/system.webServer/httpCompression" -Value @{doDynamicCompression="True"; doStaticCompression="True"}

# Configure caching
Set-WebConfiguration -Filter "/system.webServer/caching" -Value @{enabled="True"}
```

## Summary

Your TodoApp should now be successfully deployed to your VM with:

- ✅ **Domain**: phongmx.org
- ✅ **SSL**: HTTPS encryption enabled
- ✅ **Application**: TodoApp accessible at https://phongmx.org/TodoApp
- ✅ **Authentication**: admin/SecurePassword@2024
- ✅ **Redirection**: HTTP automatically redirects to HTTPS

**Test URLs**:
- Main app: https://phongmx.org/TodoApp
- Login: https://phongmx.org/TodoApp/Account/Login

If you encounter any issues, refer to the troubleshooting section or check the logs for specific error details. 