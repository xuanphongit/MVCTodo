# Web Deploy with setParameters Guide

This guide explains how to use Microsoft Web Deploy with setParameters files to deploy the TodoApp to virtual machines.

## Overview

The project has been configured to support Web Deploy with parameterization, allowing you to deploy different configurations to different environments without changing code.

## File Structure

```
TodoApp/
├── Parameters.xml                          # Defines all Web Deploy parameters
├── parameters/
│   ├── setParameters.xml                   # Default parameter values
│   ├── setParameters.development.xml       # Development environment values
│   ├── setParameters.staging.xml          # Staging environment values
│   └── setParameters.production.xml       # Production environment values
├── Properties/PublishProfiles/
│   └── WebDeploy.pubxml                   # Web Deploy publish profile
└── scripts/
    ├── deploy-webdeploy.ps1               # Full deployment script
    └── deploy-simple.ps1                  # Simplified deployment script
```

## Parameters Defined

The `Parameters.xml` file defines these parameters:

| Parameter | Description | Usage |
|-----------|-------------|-------|
| `Authentication-DefaultCredentials-Username` | Login username | Authentication credentials |
| `Authentication-DefaultCredentials-Password` | Login password | Authentication credentials |
| `IIS Web Application Name` | IIS application path | Deployment target |
| `ASPNETCORE-ENVIRONMENT` | ASP.NET Core environment | Runtime behavior |
| `Logging-LogLevel-Default` | Default log level | Debugging and monitoring |
| `DefaultConnection` | Database connection string | Future database support |

## Environment Configurations

### Development Environment
- **Username**: `dev`
- **Password**: `dev123`
- **IIS Path**: `Default Web Site/TodoApp-Dev`
- **Environment**: `Development`
- **Log Level**: `Information`

### Staging Environment
- **Username**: `staging`
- **Password**: `Staging@2024`
- **IIS Path**: `Default Web Site/TodoApp-Staging`
- **Environment**: `Staging`
- **Log Level**: `Warning`

### Production Environment
- **Username**: `admin`
- **Password**: `SecurePassword@2024`
- **IIS Path**: `Default Web Site/TodoApp`
- **Environment**: `Production`
- **Log Level**: `Warning`

## Deployment Methods

### Method 1: Using PowerShell Script (Recommended)

```powershell
# Deploy to production
.\scripts\deploy-webdeploy.ps1 -Environment production -ServerUrl "https://your-vm:8172/msdeploy.axd" -Username "Administrator" -Password "your-vm-password"

# Deploy to staging
.\scripts\deploy-webdeploy.ps1 -Environment staging -ServerUrl "https://staging-vm:8172/msdeploy.axd" -Username "Administrator" -Password "staging-password"

# Deploy to development
.\scripts\deploy-webdeploy.ps1 -Environment development -ServerUrl "https://dev-vm:8172/msdeploy.axd" -Username "Administrator" -Password "dev-password"
```

### Method 2: Using Visual Studio

1. Right-click project → **Publish**
2. Select **Web Deploy** publish profile
3. Configure target server settings
4. Choose appropriate `setParameters.{environment}.xml` file
5. Click **Publish**

### Method 3: Using MSBuild

```cmd
# Create package with parameters
dotnet msbuild Todo.csproj /p:Configuration=Release /p:WebPublishMethod=Package /p:PackageAsSingleFile=true /p:PackageLocation=TodoApp.zip /p:SetParametersFile=parameters\setParameters.production.xml

# Deploy package
msdeploy -source:package=TodoApp.zip -dest:auto,computerName="https://your-vm:8172/msdeploy.axd",userName="Administrator",password="your-password" -verb:sync -setParamFile:parameters\setParameters.production.xml
```

### Method 4: Simple Direct Deploy

```powershell
.\scripts\deploy-simple.ps1 -Environment production -ServerUrl "https://your-vm:8172/msdeploy.axd" -Username "Administrator" -Password "your-password"
```

## Prerequisites on Target VM

### 1. Install Web Deploy 3.6
```powershell
# Download and install Web Deploy 3.6
Invoke-WebRequest -Uri "https://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi" -OutFile "WebDeploy.msi"
Start-Process -FilePath "WebDeploy.msi" -ArgumentList "/quiet" -Wait
```

### 2. Configure IIS and Web Deploy
```powershell
# Enable Web Deploy in IIS
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole, IIS-WebServer, IIS-CommonHttpFeatures, IIS-HttpErrors, IIS-HttpRedirect, IIS-ApplicationDevelopment, IIS-NetFxExtensibility45, IIS-HealthAndDiagnostics, IIS-HttpLogging, IIS-Security, IIS-RequestFiltering, IIS-Performance, IIS-WebServerManagementTools, IIS-ManagementConsole, IIS-IIS6ManagementCompatibility, IIS-Metabase, IIS-ASPNET45

# Install ASP.NET Core Runtime
Invoke-WebRequest -Uri "https://download.microsoft.com/download/6/0/2/602A459C-D42C-4A05-9E72-9EA43CB47D90/dotnet-hosting-8.0.0-win.exe" -OutFile "dotnet-hosting.exe"
Start-Process -FilePath "dotnet-hosting.exe" -ArgumentList "/quiet" -Wait
```

### 3. Configure Web Deploy Service
- Open **IIS Manager**
- Install **Web Deploy** module
- Configure **Management Service** to allow remote connections
- Create deployment user or use Administrator account

## Security Considerations

1. **Credential Management**: Store credentials securely, use Azure Key Vault or environment variables
2. **HTTPS**: Always use HTTPS for Web Deploy connections
3. **Firewall**: Ensure port 8172 is open for Web Deploy service
4. **Authentication**: Use strong passwords and consider certificate-based authentication
5. **Network**: Use VPN or private networks for deployment connections

## Troubleshooting

### Common Issues

1. **Web Deploy Service Not Running**
   ```powershell
   Start-Service WMSVC
   Set-Service WMSVC -StartupType Automatic
   ```

2. **Connection Refused**
   - Check firewall settings
   - Verify Web Deploy service is running
   - Confirm correct port (8172)

3. **Authentication Failed**
   - Verify username/password
   - Check user permissions in IIS
   - Ensure user has deployment rights

4. **Parameter Not Found**
   - Verify `Parameters.xml` syntax
   - Check `setParameters.xml` file exists
   - Confirm parameter names match exactly

### Validation Commands

```powershell
# Test Web Deploy connection
msdeploy -verb:dump -source:webServer,computerName="https://your-vm:8172/msdeploy.axd",userName="Administrator",password="your-password"

# Validate package
msdeploy -verb:sync -source:package=TodoApp.zip -dest:auto -whatif

# Check IIS application
msdeploy -verb:dump -source:iisApp="Default Web Site/TodoApp",computerName="https://your-vm:8172/msdeploy.axd",userName="Administrator",password="your-password"
```

## Best Practices

1. **Environment Separation**: Use different setParameters files for each environment
2. **Version Control**: Do not commit passwords to source control
3. **Backup**: Always enable backup during deployment (`EnableMSDeployBackup=True`)
4. **Testing**: Test deployment in staging before production
5. **Monitoring**: Monitor application after deployment
6. **Rollback**: Keep previous versions for quick rollback capability

## CI/CD Integration

### Azure DevOps Pipeline Example

```yaml
- task: DotNetCoreCLI@2
  displayName: 'Build'
  inputs:
    command: 'build'
    projects: '**/*.csproj'
    arguments: '--configuration Release'

- task: DotNetCoreCLI@2
  displayName: 'Publish'
  inputs:
    command: 'publish'
    projects: '**/*.csproj'
    arguments: '--configuration Release --output $(Build.ArtifactStagingDirectory)'

- task: IISWebAppDeploymentOnMachineGroup@0
  displayName: 'Deploy to IIS'
  inputs:
    WebSiteName: 'Default Web Site/TodoApp'
    Package: '$(Build.ArtifactStagingDirectory)/**/*.zip'
    SetParametersFile: 'parameters/setParameters.$(Environment).xml'
    RemoveAdditionalFilesFlag: true
    TakeAppOfflineFlag: true
```

This setup provides a robust, parameterized deployment solution that adapts to different environments while maintaining security and flexibility. 