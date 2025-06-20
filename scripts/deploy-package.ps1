param(
    [Parameter(Mandatory=$true)]
    [string]$PackageFile,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("development", "staging", "production")]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [string]$ServerUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$true)]
    [string]$Password,
    
    [Parameter(Mandatory=$false)]
    [string]$SetParametersPath = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf,
    
    [Parameter(Mandatory=$false)]
    [switch]$AllowUntrusted = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableBackup = $true
)

Write-Host "Deploying package to $Environment environment..." -ForegroundColor Green

# Validate package file exists
if (-not (Test-Path $PackageFile)) {
    Write-Error "Package file not found: $PackageFile"
    exit 1
}

# Determine setParameters file
if ([string]::IsNullOrEmpty($SetParametersPath)) {
    $packageDir = Split-Path $PackageFile -Parent
    $SetParametersPath = Join-Path $packageDir "setParameters.$Environment.xml"
}

# Validate setParameters file exists
if (-not (Test-Path $SetParametersPath)) {
    Write-Error "SetParameters file not found: $SetParametersPath"
    exit 1
}

try {
    # Find msdeploy.exe
    $msdeployPath = @(
        "${env:ProgramFiles}\IIS\Microsoft Web Deploy V3\msdeploy.exe",
        "${env:ProgramFiles(x86)}\IIS\Microsoft Web Deploy V3\msdeploy.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    
    if (-not $msdeployPath) {
        throw "MSDeploy.exe not found. Please install Web Deploy 3.6 or later."
    }

    Write-Host "Using MSDeploy: $msdeployPath" -ForegroundColor Gray
    Write-Host "Package: $PackageFile" -ForegroundColor Gray
    Write-Host "SetParameters: $SetParametersPath" -ForegroundColor Gray
    Write-Host "Target: $ServerUrl" -ForegroundColor Gray

    # Build msdeploy arguments
    $msdeployArgs = @(
        "-source:package='$PackageFile'"
        "-dest:auto,computerName='$ServerUrl',userName='$Username',password='$Password',authtype='basic'"
        "-verb:sync"
        "-setParamFile:'$SetParametersPath'"
        "-enableRule:AppOffline"
    )

    # Add optional parameters
    if ($AllowUntrusted) {
        $msdeployArgs += "-allowUntrusted"
    }
    
    if ($EnableBackup) {
        $msdeployArgs += "-enableRule:BackupRule"
    }
    
    if ($WhatIf) {
        $msdeployArgs += "-whatif"
        Write-Host "Running in WhatIf mode - no actual deployment will occur" -ForegroundColor Yellow
    }

    # Add verbose logging
    $msdeployArgs += "-verbose"

    Write-Host "`nExecuting Web Deploy..." -ForegroundColor Yellow
    Write-Host "Command: $msdeployPath $($msdeployArgs -join ' ')" -ForegroundColor Cyan
    
    # Execute deployment
    $process = Start-Process -FilePath $msdeployPath -ArgumentList $msdeployArgs -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -eq 0) {
        if ($WhatIf) {
            Write-Host "WhatIf deployment validation completed successfully!" -ForegroundColor Green
        } else {
            Write-Host "Deployment completed successfully!" -ForegroundColor Green
            
            # Try to determine the application URL
            $serverName = $ServerUrl -replace "https?://" -replace ":8172.*$"
            Write-Host "Application should be available at: https://$serverName/TodoApp" -ForegroundColor Cyan
        }
    } else {
        throw "Web Deploy failed with exit code $($process.ExitCode)"
    }

} catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "`nDeployment script completed." -ForegroundColor Green 