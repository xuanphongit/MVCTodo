# Azure VM Deployment Best Practices

## 📋 Overview

This document outlines the best practices implemented in our GitHub Actions workflow for deploying ASP.NET Core applications to Azure VMs using IIS and Web Deploy.

## 🛡️ Security Best Practices

### 1. Secrets Management
- **Web Deploy credentials** stored in GitHub Secrets
- **No hardcoded passwords** or sensitive data in workflow
- **Environment-specific secrets** using GitHub Environments

```yaml
env:
  WEB_DEPLOY_SERVER: ${{ secrets.WEB_DEPLOY_SERVER || 'localhost' }}
  WEB_DEPLOY_USERNAME: ${{ secrets.WEB_DEPLOY_USERNAME }}
  WEB_DEPLOY_PASSWORD: ${{ secrets.WEB_DEPLOY_PASSWORD }}
```

### 2. Least Privilege Access
- **Dedicated service accounts** for deployment
- **Minimal required permissions** for IIS operations
- **Proper file system permissions** (IIS_IUSRS, IUSR)

### 3. Secure Communication
- **HTTPS endpoints** for health checks in production
- **Encrypted secrets** in GitHub repository
- **Secure file transfer** using Web Deploy

## ⚡ Performance Optimizations

### 1. Build Optimization
- **NuGet package caching** to reduce restore time
- **Incremental builds** with proper dependency management
- **Parallel operations** where possible

```yaml
- name: Cache NuGet packages
  uses: actions/cache@v4
  with:
    path: ~/.nuget/packages
    key: ${{ runner.os }}-nuget-${{ hashFiles('**/*.csproj') }}
```

### 2. Deployment Efficiency
- **Differential deployment** using Web Deploy
- **Robocopy for backups** with multi-threading
- **Selective file exclusions** (logs, temp files)

### 3. Resource Management
- **Timeout controls** on long-running operations
- **Memory-efficient file operations**
- **Cleanup of temporary files**

## 🔄 Reliability & Error Handling

### 1. Comprehensive Error Handling
- **Try-catch blocks** around critical operations
- **Graceful degradation** when admin privileges unavailable
- **Detailed error messages** with troubleshooting steps

### 2. Retry Logic
- **Health check retries** with exponential backoff
- **Multiple URL testing** for health checks
- **Fallback deployment methods**

### 3. Rollback Capabilities
- **Automatic backups** before deployment
- **Backup retention policy** (keep last 10)
- **Rollback instructions** in failure scenarios

## 🌍 Environment Management

### 1. Multi-Environment Support
```yaml
env:
  IIS_SITE_NAME: ${{ inputs.environment == 'staging' && 'TodoMVCApp-Staging' || 'TodoMVCApp' }}
  IIS_APP_POOL: ${{ inputs.environment == 'staging' && 'TodoMVCAppPool-Staging' || 'TodoMVCAppPool' }}
```

### 2. Environment-Specific Configuration
- **Separate IIS sites** for each environment
- **Different health check URLs**
- **Environment-specific backup paths**

### 3. GitHub Environments
- **Environment protection rules**
- **Required reviewers** for production
- **Environment-specific secrets**

## 📊 Monitoring & Observability

### 1. Comprehensive Logging
- **Structured logging** with consistent formatting
- **Color-coded output** for better readability
- **Progress indicators** and status messages

### 2. Health Checks
- **Multi-URL health checking**
- **Detailed response validation**
- **Performance metrics collection**

### 3. Deployment Metrics
- **Duration tracking**
- **File count and size metrics**
- **Success/failure rates**

## 🚀 CI/CD Best Practices

### 1. Workflow Optimization
- **Path-based triggers** to avoid unnecessary builds
- **Conditional step execution**
- **Parallel job execution** where possible

```yaml
on:
  push:
    branches: [ "master", "main" ]
    paths-ignore:
      - '**.md'
      - 'docs/**'
```

### 2. Testing Integration
- **Automated test execution**
- **Test result reporting**
- **Quality gates** before deployment

### 3. Deployment Strategies
- **Blue-green deployment** capability
- **Canary releases** for staged rollouts
- **Feature flags** integration ready

## 🔧 Infrastructure as Code

### 1. Automated Setup
- **PowerShell scripts** for IIS configuration
- **Idempotent operations** for repeatability
- **Prerequisites validation**

### 2. Configuration Management
- **Environment-specific settings**
- **Centralized configuration**
- **Version-controlled infrastructure**

## 📈 Scalability Considerations

### 1. Multi-Server Deployment
- **Load balancer ready**
- **Session state management**
- **Distributed caching support**

### 2. Resource Scaling
- **Auto-scaling preparation**
- **Resource monitoring**
- **Performance baselines**

## 🛠️ Troubleshooting & Maintenance

### 1. Diagnostic Information
- **System health checks**
- **Dependency validation**
- **Resource availability checks**

### 2. Maintenance Windows
- **Scheduled deployment slots**
- **Maintenance mode handling**
- **Service interruption minimization**

### 3. Support Documentation
- **Troubleshooting guides**
- **Common issue resolutions**
- **Escalation procedures**

## 📋 Compliance & Governance

### 1. Audit Trail
- **Deployment history tracking**
- **Change documentation**
- **Approval workflows**

### 2. Security Compliance
- **Regular security updates**
- **Vulnerability scanning**
- **Access control reviews**

### 3. Backup & Recovery
- **Automated backup creation**
- **Backup verification**
- **Disaster recovery procedures**

## 🎯 Implementation Checklist

### Pre-Deployment
- [ ] GitHub Secrets configured
- [ ] Self-hosted runner setup with admin privileges
- [ ] IIS and Web Deploy installed
- [ ] .NET 8.0 Hosting Bundle installed
- [ ] Firewall rules configured

### During Deployment
- [ ] Prerequisites validation passes
- [ ] Build and tests successful
- [ ] Backup created successfully
- [ ] Application deployed without errors
- [ ] Health checks pass

### Post-Deployment
- [ ] Application functionality verified
- [ ] Performance metrics within acceptable range
- [ ] Monitoring alerts configured
- [ ] Documentation updated
- [ ] Team notified of deployment status

## 📞 Support & Resources

### Documentation
- [DEPLOYMENT.md](./DEPLOYMENT.md) - General deployment guide
- [WEB-DEPLOY-GUIDE.md](./WEB-DEPLOY-GUIDE.md) - Web Deploy specific guide
- [WEB-DEPLOY-TROUBLESHOOTING.md](./WEB-DEPLOY-TROUBLESHOOTING.md) - Troubleshooting guide

### Scripts
- `scripts/setup-iis.ps1` - IIS setup automation
- `scripts/setup-webdeploy.ps1` - Web Deploy setup
- `scripts/manual-copy-deployment.ps1` - Manual deployment fallback

### Monitoring
- GitHub Actions workflow logs
- Windows Event Logs (Application, System)
- IIS logs
- Application performance counters

---

**Note**: This workflow follows Microsoft's recommended practices for IIS deployment and incorporates industry best practices for CI/CD pipelines in enterprise environments. 