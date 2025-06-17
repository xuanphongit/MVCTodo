# Web Deploy V3 Deployment Guide

This guide explains how to use Microsoft Web Deploy V3 with GitHub Actions for automated IIS deployment.

## 🚀 Overview

Web Deploy (MSDeploy) V3 is Microsoft's official deployment tool for IIS applications. It provides:

- **Atomic deployments** with rollback capabilities
- **Differential sync** - only changed files are deployed
- **Built-in backup** and restore functionality
- **Application offline** handling during deployment
- **Robust error handling** and logging
- **Multiple deployment methods** (package, folder sync, etc.)

## 📋 Prerequisites

### On Your Azure VM/Server

1. **Windows Server 2019+** or **Windows 10+**
2. **IIS with ASP.NET Core support**
3. **Web Deploy V3** installed
4. **.NET 8.0 Runtime** and **Hosting Bundle**
5. **Administrator privileges** for initial setup

### GitHub Repository

1. **Self-hosted runner** configured on your server
2. **Repository access** for the runner
3. **GitHub Actions** enabled

## 🛠️ Installation & Setup

### Step 1: Run the Setup Script

```powershell
# Download and run the setup script as Administrator
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/your-repo/MVC/main/scripts/setup-webdeploy.ps1" -OutFile "setup-webdeploy.ps1"
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\setup-webdeploy.ps1
```

Or run with custom parameters:
```powershell
.\setup-webdeploy.ps1 -SiteName "MyApp" -AppPoolName "MyAppPool" -SitePath "C:\inetpub\wwwroot\MyApp"
```

### Step 2: Manual Installation (Alternative)

If the script fails, install manually:

1. **Download Web Deploy V3**:
   - Visit: https://www.microsoft.com/en-us/download/details.aspx?id=43717
   - Download `WebDeploy_amd64_en-US.msi`
   - Run as Administrator with "Complete" installation

2. **Install ASP.NET Core Hosting Bundle**:
   - Visit: https://dotnet.microsoft.com/download/dotnet/8.0
   - Download "ASP.NET Core Runtime 8.0.x - Windows Hosting Bundle"
   - Run as Administrator

3. **Enable IIS Features**:
   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET45 -All
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerManagementTools -All
   ```

### Step 3: Verify Installation

```powershell
# Check Web Deploy installation
& "${env:ProgramFiles}\IIS\Microsoft Web Deploy V3\msdeploy.exe" -version

# Check .NET installation
dotnet --version

# Check IIS
Get-Service W3SVC
```

## 🔧 Configuration

### GitHub Actions Workflow

The repository includes two workflow options:

1. **`deploy-iis.yml`** - Traditional PowerShell/appcmd approach
2. **`deploy-webdeploy.yml`** - Web Deploy V3 approach ⭐

### Web Deploy Workflow Features

```yaml
# Deployment methods
web_deploy_method:
  - auto      # Try package first, fallback to folder sync
  - package   # Use Web Deploy packages (.zip)
  - folder    # Direct folder synchronization
  - inproc    # In-process deployment
```

### Environment Variables

```yaml
env:
  IIS_SITE_NAME: 'TodoMVCApp'
  IIS_APP_POOL: 'TodoMVCAppPool'
  IIS_SITE_PATH: 'C:\inetpub\wwwroot\TodoApp'
  WEB_DEPLOY_SERVER: 'localhost'
  WEB_DEPLOY_USERNAME: 'Administrator'
```

## 🚀 Deployment Process

### Automatic Deployment

Triggers on:
- Push to `main`/`master` branch
- Manual workflow dispatch

### Manual Deployment

1. Go to **GitHub Actions** → **Deploy to IIS using Web Deploy**
2. Click **"Run workflow"**
3. Select options:
   - **Environment**: production/staging
   - **Web Deploy Method**: auto/package/folder
   - **Force Deploy**: Skip health checks

## 📊 Deployment Methods Comparison

| Method | Description | Pros | Cons |
|--------|-------------|------|------|
| **Package** | Creates .zip package and deploys | Fast, atomic, includes metadata | Requires MSBuild |
| **Folder Sync** | Direct folder synchronization | Simple, reliable | No atomic deployment |
| **Auto** | Try package first, fallback to folder | Best of both worlds | More complex |

## 🔍 Web Deploy Advantages

### vs Traditional PowerShell Deployment

| Feature | Web Deploy | PowerShell/appcmd |
|---------|------------|-------------------|
| **Atomic Deployment** | ✅ Yes | ❌ No |
| **Differential Sync** | ✅ Yes | ❌ No |
| **Built-in Backup** | ✅ Yes | ⚠️ Manual |
| **App Offline Handling** | ✅ Automatic | ⚠️ Manual |
| **Rollback Support** | ✅ Built-in | ⚠️ Manual |
| **Admin Privileges** | ⚠️ Required | ⚠️ Required |
| **Learning Curve** | ⚠️ Moderate | ✅ Simple |

## 🛡️ Security & Permissions

### Required Permissions

Web Deploy requires:
- **Administrator privileges** on the target server
- **IIS_IUSRS** permissions on the deployment directory
- **Web Deploy** service permissions

### Security Best Practices

1. **Run GitHub Actions runner as Administrator**
2. **Use service accounts** for production
3. **Limit Web Deploy permissions** to specific sites
4. **Enable HTTPS** for remote deployments
5. **Regular security updates** for Web Deploy

## 🔧 Troubleshooting

### Common Issues

**1. Web Deploy Not Found**
```
ERROR: Web Deploy V3 not found!
```
**Solution**: Install Web Deploy V3 using the setup script or manually

**2. Permission Denied**
```
ERROR: Access denied during deployment
```
**Solution**: Ensure runner has Administrator privileges

**3. Site Already Exists**
```
WARNING: Site already exists
```
**Solution**: This is normal - Web Deploy will update the existing site

**4. Package Creation Failed**
```
WARNING: Package creation via MSBuild failed
```
**Solution**: Workflow will fallback to folder sync automatically

### Debugging Commands

```powershell
# Test Web Deploy connectivity
& "${env:ProgramFiles}\IIS\Microsoft Web Deploy V3\msdeploy.exe" -verb:dump -source:webServer

# Check site status
& "${env:ProgramFiles}\IIS\Microsoft Web Deploy V3\msdeploy.exe" -verb:dump -source:iisApp="TodoMVCApp"

# Verify permissions
icacls "C:\inetpub\wwwroot\TodoApp"
```

## 📈 Performance Tips

### Optimize Deployment Speed

1. **Use Package Method** for large applications
2. **Enable Compression** in Web Deploy settings
3. **Exclude Unnecessary Files** using skip rules
4. **Use Differential Sync** to deploy only changes

### Skip Rules Example

```powershell
# Skip logs and temporary files
-skip:Directory="\\logs$"
-skip:Directory="\\temp$"
-skip:File="\\.*\.log$"
-skip:File="\\.*\.tmp$"
```

## 🔄 Rollback Process

### Automatic Rollback (if deployment fails)

Web Deploy automatically maintains backups and can rollback on failure.

### Manual Rollback

```powershell
# List available backups
Get-ChildItem "C:\Deployments\Backups" | Sort-Object CreationTime -Descending

# Restore from backup
$latestBackup = Get-ChildItem "C:\Deployments\Backups" | Sort-Object CreationTime -Descending | Select-Object -First 1
& "${env:ProgramFiles}\IIS\Microsoft Web Deploy V3\msdeploy.exe" -verb:sync -source:contentPath="$($latestBackup.FullName)" -dest:contentPath="C:\inetpub\wwwroot\TodoApp"
```

## 🎯 Advanced Configuration

### Custom Web Deploy Parameters

```yaml
# In workflow file
- name: Advanced Web Deploy
  run: |
    & "$env:MSDEPLOY_PATH" `
      -verb:sync `
      -source:package="app.zip" `
      -dest:iisApp="MySite" `
      -setParam:name="IIS Web Application Name",value="MySite" `
      -enableRule:AppOffline `
      -enableRule:DoNotDeleteRule `
      -skip:Directory="\\App_Data$" `
      -allowUntrusted:true `
      -verbose
```

### Remote Deployment

For deploying to remote servers:

```yaml
env:
  WEB_DEPLOY_SERVER: 'remote-server.domain.com'
  WEB_DEPLOY_USERNAME: 'deploy-user'
  WEB_DEPLOY_PASSWORD: ${{ secrets.WEB_DEPLOY_PASSWORD }}
```

## 📞 Support & Resources

### Official Documentation
- [Web Deploy Documentation](https://docs.microsoft.com/en-us/iis/publish/using-web-deploy)
- [MSDeploy Command Reference](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/dd568996(v=ws.10))

### Community Resources
- [Web Deploy GitHub](https://github.com/microsoft/webdeploy)
- [IIS Forums](https://forums.iis.net/)

### Getting Help

1. **Check GitHub Actions logs** for detailed error messages
2. **Review Web Deploy logs** in Event Viewer
3. **Test Web Deploy manually** using command line
4. **Verify permissions** and prerequisites

## 🎉 Conclusion

Web Deploy V3 provides a robust, enterprise-grade deployment solution for IIS applications. While it requires more setup than traditional methods, it offers superior reliability, performance, and features for production deployments.

Choose Web Deploy when you need:
- ✅ **Atomic deployments** with rollback
- ✅ **Differential sync** for large applications
- ✅ **Built-in backup** and restore
- ✅ **Enterprise-grade** reliability
- ✅ **Advanced deployment** features

For simple deployments or development environments, the traditional PowerShell approach in `deploy-iis.yml` may be sufficient. 