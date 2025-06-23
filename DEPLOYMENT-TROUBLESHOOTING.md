# Deployment Troubleshooting Guide

## Parameter Replacement Issues

### Problem: Placeholders not being replaced in deployed appsettings.json

The deployed application shows placeholders like `{{USERNAME_PLACEHOLDER}}` instead of actual values.

### Root Causes:
1. **Missing setParameters files** - Environment-specific parameter files not found
2. **Web Deploy package deployment failure** - Package deployment falls back to folder copy without parameter replacement
3. **Incorrect parameter file references** - setParameters file path not found during deployment

### Solution Applied:

#### 1. Enhanced setParameters Files
All parameter files now include all required parameters:
- `parameters/setParameters.xml` (default)
- `parameters/setParameters.production.xml` 
- `parameters/setParameters.staging.xml`
- `parameters/setParameters.development.xml`

#### 2. Manual Parameter Replacement
When Web Deploy package deployment fails, the workflow now:
1. Copies files using standard file copy
2. Manually replaces placeholders in `appsettings.json`
3. Uses the appropriate `setParameters.{environment}.xml` file
4. Verifies replacement was successful

#### 3. Parameter File Discovery
The deployment script now searches for parameter files in multiple locations:
- `parameters/setParameters.{environment}.xml`
- `parameters/setParameters.xml` (fallback)
- `{publish_path}/parameters/setParameters.{environment}.xml`
- `{publish_path}/parameters/setParameters.xml` (fallback)

### Verification Steps:

#### 1. Check Parameter Files Exist
```powershell
# Verify all parameter files exist
Get-ChildItem -Path "parameters" -Filter "setParameters*.xml"
```

#### 2. Validate Parameter File Content
```powershell
# Check production parameters
[xml]$params = Get-Content "parameters/setParameters.production.xml"
$params.parameters.setParameter | Format-Table name, value
```

#### 3. Test Parameter Replacement Locally
```powershell
# Test manual replacement
$content = Get-Content "appsettings.json" -Raw
$content = $content -replace "{{USERNAME_PLACEHOLDER}}", "admin"
$content = $content -replace "{{PASSWORD_PLACEHOLDER}}", "admin123"
Write-Host $content
```

### Post-Deployment Verification:

#### 1. Check Deployed appsettings.json
```powershell
# On the target server, check the deployed file
Get-Content "C:\inetpub\wwwroot\TodoApp\appsettings.json" | ConvertFrom-Json | ConvertTo-Json -Depth 10
```

#### 2. Verify Application Startup
- Check Windows Event Logs for ASP.NET Core errors
- Monitor Application Pool status
- Test application endpoints

### Common Issues and Fixes:

#### Issue: "setParameters file not found"
**Fix:** Ensure parameter files are included in the build and copied to publish directory
```xml
<!-- In Todo.csproj -->
<ItemGroup>
  <Content Include="parameters\*.xml">
    <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
  </Content>
</ItemGroup>
```

#### Issue: "Web Deploy package creation failed"
**Fix:** Manual deployment with parameter replacement is now used as fallback

#### Issue: "Some placeholders still not replaced"
**Fix:** Check parameter names match exactly between `Parameters.xml` and `setParameters.xml`

### Monitoring and Logging:

The deployment workflow now includes:
1. **Parameter File Discovery Logging** - Shows which parameter file is being used
2. **Replacement Verification** - Lists which placeholders were replaced
3. **Content Validation** - Shows final appsettings.json content if issues found

### Environment-Specific Configuration:

| Environment | Username | Password | Domain | SSL |
|-------------|----------|----------|---------|-----|
| Development | `dev` | `dev123` | `dev.phongmx.org` | `false` |
| Staging | `staging` | `Staging@2024` | `staging.phongmx.org` | `true` |
| Production | `admin` | `SecurePassword@2024` | `phongmx.org` | `true` |

### Manual Deployment Steps (If Automated Deployment Fails):

1. **Build and Publish**
```powershell
dotnet publish Todo.csproj --configuration Release --output ./publish
```

2. **Copy Parameter Files**
```powershell
Copy-Item parameters ./publish -Recurse -Force
```

3. **Manual Parameter Replacement**
```powershell
$environment = "production"
$content = Get-Content "./publish/appsettings.json" -Raw
[xml]$params = Get-Content "./publish/parameters/setParameters.$environment.xml"

foreach ($param in $params.parameters.setParameter) {
    $placeholder = switch ($param.name) {
        "Authentication-DefaultCredentials-Username" { "{{USERNAME_PLACEHOLDER}}" }
        "Authentication-DefaultCredentials-Password" { "{{PASSWORD_PLACEHOLDER}}" }
        "Logging-LogLevel-Default" { "{{LOGLEVEL_PLACEHOLDER}}" }
        "Application-Domain" { "{{DOMAIN_PLACEHOLDER}}" }
        "Application-UseSSL" { "{{SSL_PLACEHOLDER}}" }
        "DefaultConnection" { "{{CONNECTION_PLACEHOLDER}}" }
    }
    if ($placeholder) {
        $content = $content -replace [regex]::Escape($placeholder), $param.value
    }
}

$content | Out-File "./publish/appsettings.json" -Encoding UTF8 -Force
```

4. **Deploy to IIS**
```powershell
# Stop application pool
Stop-WebAppPool -Name "TodoMVCAppPool"

# Copy files
Copy-Item "./publish/*" "C:\inetpub\wwwroot\TodoApp" -Recurse -Force

# Start application pool  
Start-WebAppPool -Name "TodoMVCAppPool"
```

This solution ensures that parameter replacement works reliably even when Web Deploy package deployment fails. 