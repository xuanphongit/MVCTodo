# IIS Setup Script for ASP.NET Core
# Run this script as Administrator on your Azure VM

Write-Host "=== IIS Setup for ASP.NET Core ===" -ForegroundColor Green

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator. Please run PowerShell as Administrator and try again."
    exit 1
}

# Enable IIS and required features
Write-Host "Enabling IIS and required features..." -ForegroundColor Yellow

$features = @(
    "IIS-WebServerRole",
    "IIS-WebServer",
    "IIS-CommonHttpFeatures",
    "IIS-HttpErrors",
    "IIS-HttpLogging",
    "IIS-RequestFiltering",
    "IIS-StaticContent",
    "IIS-DefaultDocument",
    "IIS-DirectoryBrowsing",
    "IIS-ASPNET45",
    "IIS-NetFxExtensibility45",
    "IIS-ISAPIExtensions",
    "IIS-ISAPIFilter",
    "IIS-HttpCompressionStatic",
    "IIS-HttpCompressionDynamic",
    "IIS-Security",
    "IIS-RequestFiltering",
    "IIS-IPSecurity",
    "IIS-Performance",
    "IIS-WebServerManagementTools",
    "IIS-ManagementConsole",
    "IIS-IIS6ManagementCompatibility",
    "IIS-Metabase"
)

foreach ($feature in $features) {
    Write-Host "Enabling feature: $feature" -ForegroundColor Cyan
    Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart
}

# Download and install .NET 8.0 Hosting Bundle
Write-Host "Downloading .NET 8.0 Hosting Bundle..." -ForegroundColor Yellow

$hostingBundleUrl = "https://download.microsoft.com/download/8/4/8/848a2b7e-4b87-48a8-aa1b-2d3b728a86e8/dotnet-hosting-8.0.11-win.exe"
$hostingBundlePath = "$env:TEMP\dotnet-hosting-bundle.exe"

try {
    Invoke-WebRequest -Uri $hostingBundleUrl -OutFile $hostingBundlePath
    Write-Host "✅ Downloaded .NET Hosting Bundle successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to download .NET Hosting Bundle: $($_.Exception.Message)"
    exit 1
}

# Install .NET Hosting Bundle
Write-Host "Installing .NET 8.0 Hosting Bundle..." -ForegroundColor Yellow
Start-Process -FilePath $hostingBundlePath -ArgumentList "/quiet" -Wait -NoNewWindow

# Verify installation
Write-Host "Verifying .NET installation..." -ForegroundColor Yellow
try {
    $dotnetVersion = dotnet --version
    Write-Host "✅ .NET Version: $dotnetVersion" -ForegroundColor Green
} catch {
    Write-Warning "⚠️ .NET command not found in PATH. You may need to restart the system."
}

# Restart IIS to load the new module
Write-Host "Restarting IIS..." -ForegroundColor Yellow
iisreset

# Create application directories
Write-Host "Creating application directories..." -ForegroundColor Yellow

$appPath = "C:\inetpub\wwwroot\TodoApp"
$backupPath = "C:\Deployments\Backups"
$logsPath = "C:\inetpub\wwwroot\TodoApp\logs"

$directories = @($appPath, $backupPath, $logsPath)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "✅ Created directory: $dir" -ForegroundColor Green
    } else {
        Write-Host "ℹ️ Directory already exists: $dir" -ForegroundColor Cyan
    }
}

# Set permissions
Write-Host "Setting directory permissions..." -ForegroundColor Yellow

$acl = Get-Acl $appPath
$accessRule1 = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$accessRule2 = New-Object System.Security.AccessControl.FileSystemAccessRule("IUSR", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule1)
$acl.SetAccessRule($accessRule2)
Set-Acl -Path $appPath -AclObject $acl

Write-Host "✅ Permissions set successfully" -ForegroundColor Green

# Configure IIS settings
Write-Host "Configuring IIS settings..." -ForegroundColor Yellow

Import-Module WebAdministration

# Enable compression
Set-WebConfigurationProperty -Filter "system.webServer/httpCompression" -Name "doStaticCompression" -Value $true
Set-WebConfigurationProperty -Filter "system.webServer/httpCompression" -Name "doDynamicCompression" -Value $true

# Configure default document
Set-WebConfigurationProperty -Filter "system.webServer/defaultDocument" -Name "enabled" -Value $true

Write-Host "✅ IIS configured successfully" -ForegroundColor Green

# Display summary
Write-Host ""
Write-Host "=== SETUP COMPLETE ===" -ForegroundColor Green
Write-Host "IIS is now configured for ASP.NET Core hosting" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Ensure your VM is set up as a GitHub self-hosted runner" -ForegroundColor White
Write-Host "2. Push your code to trigger the deployment workflow" -ForegroundColor White
Write-Host "3. Monitor the GitHub Actions workflow for deployment status" -ForegroundColor White
Write-Host ""
Write-Host "Application will be deployed to: $appPath" -ForegroundColor Cyan
Write-Host "Backups will be stored in: $backupPath" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Green

# Clean up
Remove-Item $hostingBundlePath -Force -ErrorAction SilentlyContinue 