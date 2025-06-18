# Install Azure PowerShell Modules Script
Write-Host "=== INSTALLING AZURE POWERSHELL MODULES ===" -ForegroundColor Yellow

# Set TLS to 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Update PowerShellGet and PackageManagement
Write-Host "Updating PowerShellGet and PackageManagement..." -ForegroundColor Cyan
Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
Install-Module -Name PowerShellGet -Force -AllowClobber -Scope CurrentUser

# Install Azure PowerShell modules
Write-Host "Installing Azure PowerShell modules..." -ForegroundColor Cyan
try {
    # First try using Install-Module
    Install-Module -Name Az -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
    Write-Host "[SUCCESS] Azure PowerShell modules installed via Install-Module" -ForegroundColor Green
} catch {
    Write-Host "[WARNING] Install-Module failed, trying alternative method..." -ForegroundColor Yellow
    try {
        # Alternative method using PowerShell Gallery
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
        Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
        Remove-Item .\AzureCLI.msi
        Write-Host "[SUCCESS] Azure CLI installed via MSI" -ForegroundColor Green
    } catch {
        Write-Error "Failed to install Azure PowerShell modules: $($_.Exception.Message)"
        throw
    }
}

# Verify installation
Write-Host "Verifying installation..." -ForegroundColor Cyan
if (Get-Module -ListAvailable -Name Az) {
    Import-Module Az
    Write-Host "[SUCCESS] Azure PowerShell modules verified and imported" -ForegroundColor Green
    
    # Display installed modules
    Write-Host "`nInstalled Azure Modules:" -ForegroundColor Cyan
    Get-Module -ListAvailable -Name Az* | Select-Object Name, Version | Format-Table -AutoSize
} else {
    Write-Error "Azure PowerShell modules not found after installation"
    throw
}

Write-Host "`n=== INSTALLATION COMPLETE ===" -ForegroundColor Green
Write-Host "You can now use Azure PowerShell commands. Example:" -ForegroundColor Cyan
Write-Host "  Connect-AzAccount" -ForegroundColor White
Write-Host "  Get-AzSubscription" -ForegroundColor White 