# Enhanced IIS Deployment Guide

This document describes the enhanced IIS deployment workflow that **does not require MS Deploy tool** and provides advanced deployment strategies and features.

## 📋 Overview

The Enhanced IIS Deployment workflow (`deploy-iis.yml`) is a comprehensive, production-ready CI/CD pipeline that:

- ✅ **No MS Deploy dependency** - Uses PowerShell and native IIS tools only
- ✅ **Multiple deployment strategies** - Rolling, Blue-Green, Direct deployment
- ✅ **Multi-environment support** - Production, Staging, Development
- ✅ **Enhanced error handling** - Comprehensive troubleshooting and recovery
- ✅ **Advanced health checks** - Multi-URL testing with detailed diagnostics
- ✅ **Intelligent backup/rollback** - Automated backup with easy rollback
- ✅ **Performance optimized** - NuGet caching, parallel operations

## 🚀 Features

### Core Capabilities
- **Zero-downtime deployments** with graceful app_offline handling
- **Automatic backup creation** before each deployment
- **Comprehensive health checks** with detailed troubleshooting
- **Multi-environment configuration** with environment-specific settings
- **Advanced logging** with color-coded output and structured information
- **Permission management** with proper IIS user permissions
- **Configuration preservation** for critical config files

### Deployment Strategies

#### 1. Rolling Deployment (Default)
- **Best for**: Most production scenarios
- **Downtime**: Minimal (app_offline.htm shown during update)
- **Safety**: High (preserves logs, data, and configurations)
- **Rollback**: Easy (automatic backup created)

```yaml
deployment_strategy: 'rolling'
```

#### 2. Blue-Green Deployment
- **Best for**: Critical production systems requiring zero downtime
- **Downtime**: None (instant switch between environments)
- **Safety**: Highest (full environment isolation)
- **Rollback**: Instant (switch back to previous environment)

```yaml
deployment_strategy: 'blue-green'
```

#### 3. Direct Deployment
- **Best for**: Development/testing environments
- **Downtime**: Medium (services stopped during deployment)
- **Safety**: Basic (direct file replacement)
- **Rollback**: Manual (requires backup restoration)

```yaml
deployment_strategy: 'direct'
```

## 🔧 Setup Requirements

### Prerequisites
- Windows Server with IIS installed
- .NET 8.0 SDK
- PowerShell 5.1 or later
- GitHub Actions self-hosted runner

### Optional (Recommended)
- ASP.NET Core Hosting Bundle (prevents 500.19 errors)
- GitHub Actions runner running as Administrator (for full functionality)

## 📝 Workflow Configuration

### Basic Usage

```yaml
# Trigger automatic deployment on push to main branch
name: Deploy to Production
on:
  push:
    branches: [ "main" ]

# Or trigger manual deployment with options
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deployment Environment'
        required: true
        default: 'production'
        type: choice
        options:
        - production
        - staging
        - development
```

### Advanced Configuration

```yaml
# Manual deployment with all options
inputs:
  environment: 'production'          # Target environment
  deployment_strategy: 'rolling'     # Deployment strategy
  force_deploy: false               # Skip health checks
  skip_iis_setup: false            # Skip IIS configuration
  skip_tests: false                # Skip running tests
```

### Environment-Specific Settings

The workflow automatically configures environment-specific settings:

| Environment | IIS Site Name | App Pool Name | Site Path |
|------------|---------------|---------------|-----------|
| Production | TodoMVCApp | TodoMVCAppPool | C:\inetpub\wwwroot\TodoApp |
| Staging | TodoMVCApp-Staging | TodoMVCAppPool-Staging | C:\inetpub\wwwroot\TodoApp-Staging |
| Development | TodoMVCApp-Dev | TodoMVCAppPool-Dev | C:\inetpub\wwwroot\TodoApp-Dev |

## 🔍 Workflow Steps Breakdown

### 1. Environment Setup
- ✅ Checkout code with full history
- ✅ Setup .NET SDK with version management
- ✅ Display comprehensive deployment information
- ✅ Initialize IIS configuration with error handling

### 2. Prerequisites Validation
- ✅ Check Administrator privileges
- ✅ Verify .NET SDK installation
- ✅ Validate IIS service status
- ✅ Check ASP.NET Core Module availability
- ✅ Verify disk space availability
- ✅ Test PowerShell execution policy

### 3. Build Process
- ✅ Cache NuGet packages for performance
- ✅ Restore dependencies with error handling
- ✅ Build application in Release mode
- ✅ Run tests with coverage collection (optional)
- ✅ Publish application with verification

### 4. IIS Management
- ✅ Create/configure Application Pool with proper settings
- ✅ Create/configure IIS Website with bindings
- ✅ Set proper file permissions for IIS users
- ✅ Handle both Administrator and limited privilege scenarios

### 5. Deployment Execution
- ✅ Create automated backup before deployment
- ✅ Execute chosen deployment strategy
- ✅ Preserve critical configuration files
- ✅ Set proper permissions after deployment
- ✅ Verify deployment success

### 6. Health Verification
- ✅ Multi-URL health check testing
- ✅ Content verification for expected application
- ✅ Detailed troubleshooting information on failure
- ✅ IIS service status verification
- ✅ Event log analysis

### 7. Cleanup & Summary
- ✅ Start IIS services if stopped
- ✅ Generate comprehensive deployment report
- ✅ Provide next steps and troubleshooting guidance
- ✅ Display rollback information if needed

## 🛠️ Troubleshooting

### Common Issues

#### 1. HTTP 500.19 Error
**Cause**: ASP.NET Core Hosting Bundle not installed
**Solution**: 
```powershell
# Run the diagnostic script
.\scripts\diagnose-500-19-simple.ps1

# Install ASP.NET Core Hosting Bundle
.\scripts\fix-aspnet-core-500-19.ps1
```

#### 2. Permission Denied Errors
**Cause**: GitHub Actions runner not running as Administrator
**Solution**:
- Run runner as Administrator, or
- Use manual deployment scripts

#### 3. Health Check Failures
**Cause**: Application not starting properly
**Troubleshooting**:
- Check Windows Event Logs
- Verify IIS site and app pool status
- Check file permissions
- Validate web.config syntax

### Limited Privileges Mode

When running without Administrator privileges, the workflow provides:

- ✅ File deployment capabilities
- ✅ Basic IIS operations via PowerShell
- ✅ Comprehensive error reporting
- ✅ Manual setup guidance
- ⚠️ Limited IIS management features
- ⚠️ Some permission operations may fail

## 📊 Monitoring & Logging

### Built-in Monitoring
- **Deployment metrics**: Duration, file count, size
- **Health check results**: Response time, status codes
- **Error tracking**: Detailed error messages and stack traces
- **Performance data**: Build time, test results, deployment speed

### Log Locations
- **GitHub Actions logs**: Full workflow execution details
- **Application logs**: `{IIS_SITE_PATH}\logs\`
- **Windows Event Logs**: System and Application logs
- **IIS logs**: `C:\inetpub\logs\LogFiles\`

## 🔄 Rollback Procedures

### Automatic Rollback
The workflow creates automatic backups before each deployment:

```
C:\Deployments\Backups\
├── 20231201-143022-abc123def\     # Timestamped backup
│   ├── backup-info.json           # Backup metadata
│   └── [application files]        # Previous version
└── [other backups...]
```

### Manual Rollback
```powershell
# 1. Stop IIS services
Stop-WebAppPool -Name "TodoMVCAppPool"
Stop-Website -Name "TodoMVCApp"

# 2. Restore from backup
$backupPath = "C:\Deployments\Backups\[latest-backup]"
$sitePath = "C:\inetpub\wwwroot\TodoApp"
Copy-Item -Path "$backupPath\*" -Destination $sitePath -Recurse -Force

# 3. Start IIS services
Start-WebAppPool -Name "TodoMVCAppPool"
Start-Website -Name "TodoMVCApp"
```

## 🔒 Security Considerations

### File Permissions
- **IIS_IUSRS**: Read access to application files
- **IUSR**: Read access for anonymous authentication
- **Application Pool Identity**: Full control over logs and App_Data

### Configuration Security
- Environment-specific configurations
- Sensitive data in GitHub Secrets
- Secure file handling during deployment

## 🚀 Performance Optimization

### Build Performance
- NuGet package caching
- Parallel operations where possible
- Incremental builds when supported

### Deployment Performance
- Efficient file copying with Robocopy
- Selective file exclusions
- Optimized permission setting

### Runtime Performance
- Proper application pool configuration
- Optimized IIS settings
- Performance monitoring hooks

## 📚 Additional Resources

- **Scripts Directory**: `scripts/` - Helper scripts for manual operations
- **Troubleshooting Guide**: `WEB-DEPLOY-TROUBLESHOOTING.md`
- **Security Guide**: `SECURITY-ADVISORY.md`
- **Best Practices**: `AZURE-VM-DEPLOYMENT-BEST-PRACTICES.md`

## 🤝 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review GitHub Actions logs
3. Consult Windows Event Logs
4. Use diagnostic scripts in `scripts/` directory
5. Refer to additional documentation files

---

**Note**: This enhanced workflow is designed to work without MS Deploy tool dependencies, making it more lightweight and easier to set up while providing enterprise-grade deployment capabilities. 