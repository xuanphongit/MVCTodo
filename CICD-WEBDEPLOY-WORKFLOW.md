# CI/CD Workflow with Web Deploy and setParameters

This document describes the complete CI/CD workflow for deploying the TodoApp using MS Web Deploy with parameterized configuration files.

## Workflow Overview

```mermaid
graph LR
    A[Code Commit] --> B[Build Pipeline]
    B --> C[Create ZIP Package]
    C --> D[Upload Artifacts]
    D --> E[Manual Deploy Trigger]
    E --> F[Download Artifacts]
    F --> G[Deploy with setParameters]
    G --> H[Update appsettings.json]
    H --> I[Application Running]
```

## 1. Build Phase (.github/workflows/build.yml)

### Triggers
- Push to `master` or `develop` branches
- Pull requests to `master`

### Process
1. **Checkout Code**: Get latest source code
2. **Setup .NET**: Install .NET 8.0 SDK
3. **Restore Dependencies**: Download NuGet packages
4. **Build Application**: Compile in Release configuration
5. **Run Tests**: Execute unit tests (if available)
6. **Create Web Deploy Package**: Generate ZIP package with MSBuild
7. **Copy setParameters Files**: Include all environment-specific parameter files
8. **Create Build Info**: Generate metadata about the build
9. **Upload Artifacts**: Store package and parameters for deployment

### Generated Artifacts
```
artifacts/
├── TodoApp.{run_number}.zip          # Web Deploy package
├── setParameters.xml                 # Default parameters
├── setParameters.development.xml     # Development parameters
├── setParameters.staging.xml         # Staging parameters
├── setParameters.production.xml      # Production parameters
└── build-info.json                   # Build metadata
```

## 2. Deployment Phase (.github/workflows/deploy.yml)

### Triggers
- Manual workflow dispatch with parameters:
  - **Environment**: development/staging/production
  - **Package Run Number**: Which build to deploy
  - **Server URL**: Target Web Deploy server
  - **WhatIf Mode**: Validation-only deployment

### Process
1. **Download Artifacts**: Get the specified build package
2. **Validate Artifacts**: Ensure package and setParameters files exist
3. **Deploy using Web Deploy**: Use msdeploy.exe with setParameters
4. **Post-deployment Validation**: Check if application responds
5. **Generate Summary**: Report deployment results

## 3. Parameter Injection Process

### Before Deployment (appsettings.json)
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "{{LOGLEVEL_PLACEHOLDER}}",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Authentication": {
    "DefaultCredentials": {
      "Username": "{{USERNAME_PLACEHOLDER}}",
      "Password": "{{PASSWORD_PLACEHOLDER}}"
    }
  }
}
```

### After Deployment (Production Example)
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Warning",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Authentication": {
    "DefaultCredentials": {
      "Username": "admin",
      "Password": "SecurePassword@2024"
    }
  }
}
```

## 4. Environment Configurations

| Environment | Username | Password | IIS Path | Log Level |
|-------------|----------|----------|----------|-----------|
| Development | `dev` | `dev123` | `Default Web Site/TodoApp-Dev` | `Information` |
| Staging | `staging` | `Staging@2024` | `Default Web Site/TodoApp-Staging` | `Warning` |
| Production | `admin` | `SecurePassword@2024` | `Default Web Site/TodoApp` | `Warning` |

## 5. Local Development Workflow

### Build Package Locally
```powershell
# Build and create package
.\scripts\build-package.ps1 -Version "1.0.0" -Configuration Release

# Output will be in artifacts/ directory
```

### Deploy Package Locally
```powershell
# Deploy to staging
.\scripts\deploy-package.ps1 `
  -PackageFile "artifacts\TodoApp.1.0.0.zip" `
  -Environment staging `
  -ServerUrl "https://staging-vm:8172/msdeploy.axd" `
  -Username "Administrator" `
  -Password "your-password"

# Deploy with WhatIf (validation only)
.\scripts\deploy-package.ps1 `
  -PackageFile "artifacts\TodoApp.1.0.0.zip" `
  -Environment production `
  -ServerUrl "https://prod-vm:8172/msdeploy.axd" `
  -Username "Administrator" `
  -Password "your-password" `
  -WhatIf
```

## 6. GitHub Secrets Configuration

Configure these secrets in your GitHub repository:

### Required Secrets
- `DEPLOY_USERNAME`: Username for Web Deploy (usually "Administrator")
- `DEPLOY_PASSWORD`: Password for Web Deploy server access

### Environment-Specific Configuration
Create GitHub environments (development, staging, production) with:
- Different approval requirements
- Environment-specific secrets if needed
- Protection rules for production

## 7. Azure DevOps Pipeline (Alternative)

```yaml
# azure-pipelines.yml
trigger:
- master
- develop

pool:
  vmImage: 'windows-latest'

stages:
- stage: Build
  jobs:
  - job: BuildPackage
    steps:
    - task: DotNetCoreCLI@2
      displayName: 'Restore'
      inputs:
        command: 'restore'
        projects: '**/*.csproj'

    - task: DotNetCoreCLI@2
      displayName: 'Build'
      inputs:
        command: 'build'
        projects: '**/*.csproj'
        arguments: '--configuration Release --no-restore'

    - task: VSBuild@1
      displayName: 'Create Web Deploy Package'
      inputs:
        solution: 'Todo.csproj'
        msbuildArgs: '/p:Configuration=Release /p:WebPublishMethod=Package /p:PackageAsSingleFile=true /p:PackageLocation=$(Build.ArtifactStagingDirectory)/TodoApp.zip'

    - task: CopyFiles@2
      displayName: 'Copy setParameters files'
      inputs:
        SourceFolder: 'parameters'
        Contents: '*.xml'
        TargetFolder: '$(Build.ArtifactStagingDirectory)'

    - task: PublishBuildArtifacts@1
      displayName: 'Publish Artifacts'
      inputs:
        PathtoPublish: '$(Build.ArtifactStagingDirectory)'
        ArtifactName: 'TodoApp-Package'

- stage: Deploy
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/master'))
  jobs:
  - deployment: DeployToStaging
    environment: 'staging'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: IISWebAppDeploymentOnMachineGroup@0
            displayName: 'Deploy to IIS'
            inputs:
              WebSiteName: 'Default Web Site/TodoApp-Staging'
              Package: '$(Pipeline.Workspace)/TodoApp-Package/TodoApp.zip'
              SetParametersFile: '$(Pipeline.Workspace)/TodoApp-Package/setParameters.staging.xml'
```

## 8. Security Best Practices

### 1. Credential Management
- Never commit passwords to source control
- Use GitHub Secrets or Azure Key Vault
- Rotate credentials regularly
- Use service accounts with minimal permissions

### 2. Network Security
- Use HTTPS for all Web Deploy connections
- Restrict Web Deploy ports (8172) to specific IP ranges
- Consider VPN or private networks for deployment

### 3. Parameter Security
- Encrypt sensitive parameters in setParameters files
- Use different credentials for each environment
- Implement password complexity requirements

### 4. Deployment Security
- Enable backup before deployment
- Use WhatIf mode for validation
- Implement approval gates for production
- Monitor deployment logs

## 9. Troubleshooting

### Common Issues

#### Build Failures
```bash
# Check build logs
dotnet build --verbosity detailed

# Verify MSBuild parameters
dotnet msbuild Todo.csproj /p:Configuration=Release /t:WebPublish /v:detailed
```

#### Package Creation Issues
```powershell
# Verify Parameters.xml syntax
Get-Content Parameters.xml | Select-String "parameter"

# Check setParameters files
Get-ChildItem parameters/*.xml | ForEach-Object { 
  Write-Host $_.Name; Get-Content $_ 
}
```

#### Deployment Failures
```powershell
# Test Web Deploy connection
msdeploy -verb:dump -source:webServer,computerName="https://server:8172/msdeploy.axd",userName="user",password="pass"

# Validate package
msdeploy -verb:sync -source:package="TodoApp.zip" -dest:auto -whatif

# Check parameter replacement
msdeploy -verb:sync -source:package="TodoApp.zip" -dest:auto -setParamFile:"setParameters.staging.xml" -whatif
```

### Validation Commands
```powershell
# Verify deployed application
Invoke-WebRequest -Uri "https://server/TodoApp" -UseBasicParsing

# Check IIS application status
Get-IISApp | Where-Object Name -like "*TodoApp*"

# Verify configuration was updated
Get-Content "C:\inetpub\wwwroot\TodoApp\appsettings.json"
```

## 10. Benefits of This Approach

### 1. **Separation of Concerns**
- Build once, deploy many times
- Environment-specific configuration without code changes
- Clear separation between build and deployment

### 2. **Security**
- No sensitive data in source control
- Environment-specific credentials
- Secure parameter injection during deployment

### 3. **Reliability**
- Consistent packages across environments
- Validation before actual deployment (WhatIf)
- Automatic backup and rollback capabilities

### 4. **Scalability**
- Easy to add new environments
- Parameterized deployment scripts
- CI/CD pipeline automation

### 5. **Auditability**
- Complete deployment history
- Parameter tracking per environment
- Build artifact traceability

This workflow provides a robust, secure, and scalable approach to deploying .NET applications using MS Web Deploy with proper configuration management. 