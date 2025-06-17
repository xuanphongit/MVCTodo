# IIS Deployment Guide

This guide explains how to deploy the Todo MVC application to IIS using GitHub Actions and a self-hosted runner.

## 🚀 Quick Overview

The deployment process uses GitHub Actions to automatically:
1. Build the .NET 8 application
2. Publish it for production
3. Deploy to IIS on your Azure VM
4. Configure IIS application pool and website
5. Perform health checks

## 📋 Prerequisites

### On Your Azure VM

1. **Windows Server** (2019 or later recommended)
2. **PowerShell 5.1+** 
3. **Internet connectivity** for downloading dependencies
4. **Administrator privileges** for IIS setup

### GitHub Repository

1. **Self-hosted runner** configured on your VM
2. **Repository access** for the runner
3. **GitHub Actions** enabled

## 🛠️ Setup Instructions

### Step 1: Prepare Your Azure VM

1. **Run the IIS Setup Script** (as Administrator):
   ```powershell
   # Download and run the setup script
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/your-repo/MVC/main/scripts/setup-iis.ps1" -OutFile "setup-iis.ps1"
   .\setup-iis.ps1
   ```

   Or manually copy the `scripts/setup-iis.ps1` file to your VM and run it.

2. **Verify IIS Installation**:
   ```powershell
   # Check IIS is running
   Get-Service W3SVC
   
   # Check .NET is installed
   dotnet --version
   ```

### Step 2: Configure GitHub Self-Hosted Runner

1. **Go to your GitHub repository** → Settings → Actions → Runners
2. **Click "New self-hosted runner"**
3. **Follow the instructions** to download and configure the runner on your VM
4. **Run the runner as a Windows service** (recommended for production)

### Step 3: Configure Deployment Settings

Edit the environment variables in `.github/workflows/deploy-iis.yml` if needed:

```yaml
env:
  IIS_SITE_NAME: 'TodoMVCApp'           # IIS website name
  IIS_APP_POOL: 'TodoMVCAppPool'        # Application pool name
  IIS_SITE_PATH: 'C:\inetpub\wwwroot\TodoApp'  # Deployment path
  BACKUP_PATH: 'C:\Deployments\Backups' # Backup location
```

## 🚀 Deployment Process

### Automatic Deployment

The deployment triggers automatically when you:
- Push to `main` or `master` branch
- Create a pull request to `main` or `master`

### Manual Deployment

1. **Go to GitHub Actions** in your repository
2. **Select "Deploy to IIS" workflow**
3. **Click "Run workflow"**
4. **Choose options**:
   - Environment: `production` or `staging`
   - Force deploy: Skip health checks if needed

## 📁 Deployment Structure

```
C:\inetpub\wwwroot\TodoApp\          # Application files
├── Todo.dll                        # Main application
├── appsettings.Production.json     # Production config
├── web.config                      # IIS configuration
├── wwwroot/                        # Static files
├── logs/                           # Application logs
└── ...                            # Other application files

C:\Deployments\Backups\             # Backup directory
├── 20241229-143022-abc123/         # Timestamped backups
└── 20241229-120015-def456/         # (keeps last 5)
```

## 🔧 Configuration Files

### `appsettings.Production.json`
Production-specific settings with optimized logging levels.

### `web.config`
IIS configuration with:
- ASP.NET Core module settings
- Security headers
- Compression settings
- Static file caching

## 🏥 Health Checks

The deployment includes automatic health checks:
- **10 attempts** with 5-second intervals
- **HTTP 200 response** required from `http://localhost`
- **Fails deployment** if health checks don't pass
- **Can be skipped** with "Force deploy" option

## 🔍 Monitoring & Troubleshooting

### Check Deployment Status

1. **GitHub Actions**: Monitor workflow progress
2. **IIS Manager**: Check application pool and website status
3. **Event Viewer**: Windows logs for system issues
4. **Application Logs**: Check `C:\inetpub\wwwroot\TodoApp\logs\`

### Common Issues

**Application Pool Won't Start**
```powershell
# Check application pool status
Get-IISAppPool -Name "TodoMVCAppPool"

# Check event logs
Get-EventLog -LogName System -Source "Microsoft-Windows-IIS-*" -Newest 10
```

**Health Check Failures**
```powershell
# Test application manually
Invoke-WebRequest -Uri "http://localhost" -UseBasicParsing

# Check IIS logs
Get-ChildItem "C:\inetpub\logs\LogFiles\W3SVC1\" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
```

**Permission Issues**
```powershell
# Verify permissions
icacls "C:\inetpub\wwwroot\TodoApp"

# Reset permissions if needed
icacls "C:\inetpub\wwwroot\TodoApp" /grant "IIS_IUSRS:(OI)(CI)F" /T
```

### Rollback Process

If deployment fails, you can rollback:

1. **Stop the application pool**:
   ```powershell
   Stop-WebAppPool -Name "TodoMVCAppPool"
   ```

2. **Restore from backup**:
   ```powershell
   $latestBackup = Get-ChildItem "C:\Deployments\Backups" | Sort-Object CreationTime -Descending | Select-Object -First 1
   Copy-Item -Path "$($latestBackup.FullName)\*" -Destination "C:\inetpub\wwwroot\TodoApp" -Recurse -Force
   ```

3. **Start the application pool**:
   ```powershell
   Start-WebAppPool -Name "TodoMVCAppPool"
   ```

## 🔐 Security Considerations

- **HTTPS**: Configure SSL certificates in IIS for production
- **Firewall**: Ensure ports 80/443 are open
- **Updates**: Keep Windows and .NET runtime updated
- **Backups**: Automated backups are created before each deployment
- **Permissions**: Minimal required permissions are set automatically

## 📞 Support

If you encounter issues:

1. **Check GitHub Actions logs** for build/deployment errors
2. **Review IIS logs** for runtime issues
3. **Verify VM configuration** using the setup script
4. **Test manually** using PowerShell commands above

## 🎯 Next Steps

After successful deployment:

1. **Configure SSL certificates** for HTTPS
2. **Set up custom domain** if needed
3. **Configure monitoring** and alerting
4. **Set up database** if your application requires one
5. **Configure load balancing** for multiple instances 