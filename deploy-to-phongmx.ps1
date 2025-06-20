#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy TodoApp to phongmx.org VM
.DESCRIPTION
    This script builds and deploys the TodoApp to your phongmx.org VM with SSL support
.PARAMETER VMAddress
    IP address or hostname of your VM
.PARAMETER VMPassword
    Administrator password for your VM
.PARAMETER CertPassword
    Password for the SSL certificate
.PARAMETER WhatIf
    Run in validation mode only
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$VMAddress,
    
    [Parameter(Mandatory=$true)]
    [string]$VMPassword,
    
    [Parameter(Mandatory=$false)]
    [string]$CertPassword = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf = $false
)

Write-Host "🚀 Deploying TodoApp to phongmx.org" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Configuration
$Domain = "phongmx.org"
$VMUsername = "Administrator"
$ServerUrl = "https://$VMAddress:8172/msdeploy.axd"
$Environment = "production"

try {
    # Step 1: Build the application
    Write-Host "📦 Step 1: Building application..." -ForegroundColor Yellow
    
    $version = Get-Date -Format "yyyyMMdd.HHmm"
    Write-Host "Building version: $version" -ForegroundColor Gray
    
    & .\scripts\build-package.ps1 -Version $version -Configuration Release
    
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed"
    }
    
    $packageFile = "artifacts\TodoApp.$version.zip"
    if (!(Test-Path $packageFile)) {
        throw "Package file not found: $packageFile"
    }
    
    Write-Host "✅ Build completed successfully!" -ForegroundColor Green
    Write-Host "   Package: $packageFile" -ForegroundColor Gray
    
    # Step 2: Get certificate password if needed
    if ([string]::IsNullOrEmpty($CertPassword) -and (Test-Path ".github\workflows\key\origin.pfx")) {
        $CertPassword = Read-Host "Enter SSL certificate password" -AsSecureString
        $CertPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($CertPassword))
    }
    
    # Step 3: Deploy with SSL
    Write-Host "🚀 Step 2: Deploying to VM..." -ForegroundColor Yellow
    Write-Host "Target: $Domain ($VMAddress)" -ForegroundColor Gray
    Write-Host "Environment: $Environment" -ForegroundColor Gray
    Write-Host "Server URL: $ServerUrl" -ForegroundColor Gray
    
    if ($WhatIf) {
        Write-Host "🔍 Running in WhatIf mode - no actual changes will be made" -ForegroundColor Cyan
    }
    
    # Check if SSL certificate exists
    $deploySSL = Test-Path ".github\workflows\key\origin.pfx"
    
    if ($deploySSL -and ![string]::IsNullOrEmpty($CertPassword)) {
        # Deploy with SSL certificate
        Write-Host "Deploying with SSL certificate..." -ForegroundColor Gray
        & .\scripts\deploy-with-ssl.ps1 `
            -PackageFile $packageFile `
            -Environment $Environment `
            -ServerUrl $ServerUrl `
            -Username $VMUsername `
            -Password $VMPassword `
            -CertificatePath ".github\workflows\key\origin.pfx" `
            -CertificatePassword $CertPassword `
            -WhatIf:$WhatIf
    } else {
        # Deploy application only
        Write-Host "Deploying application only (SSL certificate not available or password not provided)..." -ForegroundColor Gray
        & .\scripts\deploy-package.ps1 `
            -PackageFile $packageFile `
            -Environment $Environment `
            -ServerUrl $ServerUrl `
            -Username $VMUsername `
            -Password $VMPassword `
            -WhatIf:$WhatIf
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "Deployment failed"
    }
    
    # Step 3: Test deployment (if not WhatIf)
    if (-not $WhatIf) {
        Write-Host "🧪 Step 3: Testing deployment..." -ForegroundColor Yellow
        
        Start-Sleep -Seconds 30  # Wait for application to start
        
        # Test HTTPS endpoint
        try {
            Write-Host "Testing HTTPS access..." -ForegroundColor Gray
            $response = Invoke-WebRequest -Uri "https://$Domain/TodoApp" -UseBasicParsing -TimeoutSec 30
            
            if ($response.StatusCode -eq 200) {
                Write-Host "✅ Application is responding successfully!" -ForegroundColor Green
                Write-Host "   Status: $($response.StatusCode)" -ForegroundColor Gray
                Write-Host "   Content Length: $($response.Content.Length) bytes" -ForegroundColor Gray
            }
        } catch {
            Write-Warning "⚠️ HTTPS test failed: $($_.Exception.Message)"
            
            # Try HTTP test
            try {
                Write-Host "Testing HTTP access (should redirect)..." -ForegroundColor Gray
                $response = Invoke-WebRequest -Uri "http://$Domain/TodoApp" -UseBasicParsing -TimeoutSec 30 -MaximumRedirection 0
            } catch {
                if ($_.Exception.Response.StatusCode -eq 301 -or $_.Exception.Response.StatusCode -eq 302) {
                    Write-Host "✅ HTTP correctly redirects to HTTPS" -ForegroundColor Green
                } else {
                    Write-Warning "⚠️ HTTP test also failed: $($_.Exception.Message)"
                }
            }
        }
    }
    
    # Step 4: Display summary
    Write-Host ""
    Write-Host "🎉 Deployment Summary" -ForegroundColor Green
    Write-Host "====================" -ForegroundColor Green
    Write-Host "Target VM: $VMAddress" -ForegroundColor White
    Write-Host "Domain: $Domain" -ForegroundColor White
    Write-Host "Version: $version" -ForegroundColor White
    Write-Host "Package: $packageFile" -ForegroundColor White
    Write-Host "SSL Certificate: $(if ($deploySSL) { 'Deployed' } else { 'Not available' })" -ForegroundColor White
    Write-Host "WhatIf Mode: $WhatIf" -ForegroundColor White
    
    if (-not $WhatIf) {
        Write-Host ""
        Write-Host "🌐 Application URLs:" -ForegroundColor Cyan
        Write-Host "   Main App: https://$Domain/TodoApp" -ForegroundColor Green
        Write-Host "   Login:    https://$Domain/TodoApp/Account/Login" -ForegroundColor Green
        Write-Host ""
        Write-Host "🔐 Login Credentials:" -ForegroundColor Cyan
        Write-Host "   Username: admin" -ForegroundColor White
        Write-Host "   Password: SecurePassword@2024" -ForegroundColor White
        Write-Host ""
        Write-Host "📝 Next Steps:" -ForegroundColor Yellow
        Write-Host "1. Open browser and navigate to https://$Domain/TodoApp" -ForegroundColor Gray
        Write-Host "2. Verify SSL certificate is working (green lock icon)" -ForegroundColor Gray
        Write-Host "3. Test login with the credentials above" -ForegroundColor Gray
        Write-Host "4. Verify HTTP redirects to HTTPS" -ForegroundColor Gray
    }

} catch {
    Write-Error "❌ Deployment failed: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "💡 Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Verify VM is accessible at $VMAddress" -ForegroundColor Gray
    Write-Host "2. Check Web Deploy service is running on VM" -ForegroundColor Gray
    Write-Host "3. Ensure firewall allows port 8172 on VM" -ForegroundColor Gray
    Write-Host "4. Verify Administrator credentials are correct" -ForegroundColor Gray
    Write-Host "5. Check DNS points $Domain to $VMAddress" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "✅ Deployment to phongmx.org completed successfully!" -ForegroundColor Green 