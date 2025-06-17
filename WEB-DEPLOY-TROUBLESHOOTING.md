# Web Deploy Troubleshooting Guide

This guide helps resolve common Web Deploy issues encountered during deployment.

## Common Issues and Solutions

### 1. Package Creation Fails - "Cannot read configuration file due to insufficient permissions"

**Error Message:**
```
Error: An error occurred when reading the IIS Configuration File 'MACHINE/REDIRECTION'
Error: Filename: redirection.config
Error: Cannot read configuration file due to insufficient permissions
```

**Root Cause:**
- Web Deploy requires Administrator privileges to access IIS configuration files
- The `redirection.config` file is protected and needs elevated permissions

**Solutions:**

#### Option A: Run with Administrator Privileges (Recommended)
1. Stop the GitHub Actions runner service:
   ```powershell
   # Find and stop the runner service
   Get-Service -Name "*actions.runner*" | Stop-Service
   ```

2. Run PowerShell as Administrator and restart runner:
   ```powershell
   # Navigate to runner directory
   cd C:\actions-runner  # or your runner path
   
   # Run the runner with admin privileges
   .\run.cmd
   ```

3. Or install runner as Windows service with admin privileges:
   ```powershell
   # Install as service (run as Administrator)
   .\svc.sh install
   .\svc.sh start
   ```

#### Option B: Use Folder Deployment (Fallback)
If you cannot run with admin privileges, the workflow automatically falls back to folder deployment:
- Package creation is skipped
- Direct folder synchronization is used
- File copy method as final fallback

### 2. Target Directory Does Not Exist

**Error Message:**
```
Access to the path 'TodoApp' is denied
Could not find a part of the path 'C:\inetpub\wwwroot\TodoApp'
```

**Solutions:**

#### Manual Directory Creation
```powershell
# Run as Administrator
New-Item -ItemType Directory -Path "C:\inetpub\wwwroot\TodoApp" -Force

# Set permissions for IIS
icacls "C:\inetpub\wwwroot\TodoApp" /grant "IIS_IUSRS:(OI)(CI)F" /T
icacls "C:\inetpub\wwwroot\TodoApp" /grant "IUSR:(OI)(CI)R" /T
```

#### Use Setup Script
```powershell
# Run the setup script as Administrator
.\scripts\setup-webdeploy.ps1
```

### 3. Web Deploy Service Not Found

**Error Message:**
```
Web Deploy (msdeploy.exe) not found
```

**Solutions:**

#### Install Web Deploy V3
1. **Using Web Platform Installer:**
   - Download from: https://www.microsoft.com/web/downloads/platform.aspx
   - Search for "Web Deploy 3.6"
   - Install "Web Deploy 3.6 for Hosting Servers"

2. **Using Chocolatey:**
   ```powershell
   # Install Chocolatey if not installed
   Set-ExecutionPolicy Bypass -Scope Process -Force
   [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
   iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
   
   # Install Web Deploy
   choco install webdeploy -y
   ```

3. **Manual Download:**
   - Download from: https://www.iis.net/downloads/microsoft/web-deploy
   - Install "Web Deploy 3.6" with all features

#### Verify Installation
```powershell
# Check if Web Deploy is installed
$msdeployPath = "${env:ProgramFiles}\IIS\Microsoft Web Deploy V3\msdeploy.exe"
if (Test-Path $msdeployPath) {
    & $msdeployPath -version
} else {
    Write-Host "Web Deploy not found at: $msdeployPath"
}
```

### 4. IIS Not Configured Properly

**Error Message:**
```
Cannot create IIS application pool
Cannot create IIS website
```

**Solutions:**

#### Enable IIS Features
```powershell
# Run as Administrator
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole, IIS-WebServer, IIS-CommonHttpFeatures, IIS-HttpErrors, IIS-HttpLogging, IIS-RequestFiltering, IIS-StaticContent, IIS-DefaultDocument, IIS-DirectoryBrowsing, IIS-ASPNET45

# For .NET 8.0 support
Enable-WindowsOptionalFeature -Online -FeatureName IIS-NetFxExtensibility45, IIS-ISAPIExtensions, IIS-ISAPIFilter, IIS-AspNet45
```

#### Install .NET 8.0 Hosting Bundle
```powershell
# Download and install .NET 8.0 Hosting Bundle
$url = "https://download.microsoft.com/download/8/4/8/848f28ae-72af-4b8f-a1c8-a6d52c4f5a9b/dotnet-hosting-8.0.0-win.exe"
$output = "$env:TEMP\dotnet-hosting-8.0.0-win.exe"
Invoke-WebRequest -Uri $url -OutFile $output
Start-Process -FilePath $output -ArgumentList "/quiet" -Wait
```

### 5. Permission Issues During Deployment

**Error Message:**
```
Access denied to deployment directory
Cannot write to target location
```

**Solutions:**

#### Set Proper Permissions
```powershell
# Run as Administrator
$sitePath = "C:\inetpub\wwwroot\TodoApp"

# Grant permissions to IIS users
icacls $sitePath /grant "IIS_IUSRS:(OI)(CI)F" /T
icacls $sitePath /grant "IUSR:(OI)(CI)R" /T
icacls $sitePath /grant "IIS AppPool\TodoMVCAppPool:(OI)(CI)F" /T

# Grant permissions to deployment user (if using specific user)
icacls $sitePath /grant "$env:USERNAME:(OI)(CI)F" /T
```

#### Alternative: Use Different Target Directory
If C:\inetpub\wwwroot has permission issues, use a different location:
```yaml
# In .github/workflows/deploy-webdeploy.yml
env:
  IIS_SITE_PATH: 'C:\WebApps\TodoApp'  # Alternative location
```

## Debugging Steps

### 1. Test Local Deployment
```powershell
# Use the test script to debug locally
.\scripts\test-webdeploy-local.ps1

# Test with different methods
.\scripts\test-webdeploy-local.ps1 -Method folder
.\scripts\test-webdeploy-local.ps1 -Method package
```

### 2. Check System Requirements
```powershell
# Check .NET installation
dotnet --version

# Check IIS status
Get-WindowsFeature -Name IIS-*

# Check Web Deploy installation
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*Web Deploy*"}
```

### 3. Verify Workflow Environment
```powershell
# Check runner privileges
[Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent() | Select-Object IsInRole

# Check paths
Test-Path "C:\inetpub\wwwroot"
Test-Path "${env:ProgramFiles}\IIS\Microsoft Web Deploy V3\msdeploy.exe"
```

## Deployment Method Comparison

| Method | Admin Required | Speed | Reliability | Use Case |
|--------|----------------|-------|-------------|----------|
| Package | Yes | Fast | High | Production deployments |
| Folder Sync | Partial | Medium | Medium | Development/staging |
| File Copy | No | Slow | Low | Emergency deployments |

## Best Practices

### 1. Runner Configuration
- **Production**: Install runner as Windows service with admin privileges
- **Development**: Run runner interactively with admin privileges
- **CI/CD**: Use dedicated deployment user with minimal required permissions

### 2. Security Considerations
- Use least privilege principle
- Create dedicated deployment user account
- Regularly update Web Deploy and IIS
- Monitor deployment logs for security issues

### 3. Performance Optimization
- Use package deployment for large applications
- Enable compression in web.config
- Use differential sync for frequent deployments
- Clean up old deployment backups regularly

## Alternative Solutions

### 1. Use Traditional Deployment Workflow
If Web Deploy continues to cause issues:
```yaml
# Use the traditional PowerShell deployment
uses: ./.github/workflows/deploy-iis.yml
```

### 2. Use Azure DevOps
Consider using Azure DevOps with IIS deployment tasks:
- More mature IIS integration
- Better permission handling
- Built-in rollback capabilities

### 3. Use Docker
For complex deployment scenarios:
- Containerize the application
- Use Docker for Windows
- Deploy containers to IIS or standalone

## Getting Help

### 1. Enable Verbose Logging
Add to your workflow:
```yaml
env:
  MSDEPLOY_VERBOSE: true
```

### 2. Check Event Logs
```powershell
# Check Windows Event Logs
Get-EventLog -LogName Application -Source "Web Deploy*" -Newest 10
Get-EventLog -LogName System -Source "IIS*" -Newest 10
```

### 3. Web Deploy Documentation
- Official docs: https://docs.microsoft.com/en-us/iis/publish/using-web-deploy
- Error codes: https://docs.microsoft.com/en-us/iis/publish/troubleshooting-web-deploy

### 4. Community Resources
- IIS Forums: https://forums.iis.net/
- Stack Overflow: Search for "web deploy" + your error message
- GitHub Issues: Check the repository issues for similar problems

---

**Remember**: Most Web Deploy issues are related to permissions. When in doubt, verify that:
1. The runner has Administrator privileges
2. The target directory exists and has proper permissions
3. IIS is properly configured with .NET support
4. Web Deploy V3 is correctly installed 