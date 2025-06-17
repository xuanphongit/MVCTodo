# Manual Copy Deployment Script
# This script copies files from the temporary deployment directory to the IIS directory
# Run this as Administrator after a successful deployment to temp directory

param(
    [string]$TempPath = "C:\Windows\SERVIC~1\NETWOR~1\AppData\Local\Temp\TodoApp_Deploy_Test",
    [string]$IISPath = "C:\inetpub\wwwroot\TodoApp",
    [string]$SiteName = "TodoMVCApp",
    [string]$AppPoolName = "TodoMVCAppPool"
)

Write-Host "=== MANUAL DEPLOYMENT COPY ==="
Write-Host "Source (temp): $TempPath"
Write-Host "Target (IIS): $IISPath"
Write-Host ""

# Check admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (!$isAdmin) {
    Write-Error "This script requires Administrator privileges"
    Write-Host "Please run PowerShell as Administrator and try again"
    exit 1
}

Write-Host "[INFO] Running as Administrator: $isAdmin"

# Check if temp directory exists and has files
if (!(Test-Path $TempPath)) {
    Write-Error "Temporary deployment directory not found: $TempPath"
    Write-Host "Please run the GitHub Actions deployment first"
    exit 1
}

$tempFiles = Get-ChildItem -Path $TempPath -Recurse -File
Write-Host "[INFO] Found $($tempFiles.Count) files in temporary directory"

# Create IIS directory if it doesn't exist
if (!(Test-Path $IISPath)) {
    Write-Host "Creating IIS directory: $IISPath"
    New-Item -ItemType Directory -Path $IISPath -Force | Out-Null
    Write-Host "[SUCCESS] Created IIS directory"
}

# Set proper permissions
Write-Host "Setting IIS permissions..."
try {
    icacls $IISPath /grant "IIS_IUSRS:(OI)(CI)F" /T | Out-Null
    icacls $IISPath /grant "IUSR:(OI)(CI)R" /T | Out-Null
    icacls $IISPath /grant "IIS AppPool\${AppPoolName}:(OI)(CI)F" /T | Out-Null
    Write-Host "[SUCCESS] Set IIS permissions"
} catch {
    Write-Warning "[WARNING] Could not set all permissions: $($_.Exception.Message)"
}

# Stop IIS services
Write-Host "Stopping IIS services..."
try {
    Import-Module WebAdministration -ErrorAction SilentlyContinue
    Stop-WebAppPool -Name $AppPoolName -ErrorAction SilentlyContinue
    Stop-Website -Name $SiteName -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    Write-Host "[INFO] Stopped IIS services"
} catch {
    Write-Warning "[WARNING] Could not stop IIS services: $($_.Exception.Message)"
}

# Copy files
Write-Host "Copying files from temp to IIS directory..."
try {
    Copy-Item -Path "$TempPath\*" -Destination $IISPath -Recurse -Force
    Write-Host "[SUCCESS] Files copied successfully"
    
    # Verify copy
    $iisFiles = Get-ChildItem -Path $IISPath -Recurse -File
    Write-Host "[INFO] Copied $($iisFiles.Count) files to IIS directory"
    
} catch {
    Write-Error "File copy failed: $($_.Exception.Message)"
    exit 1
}

# Start IIS services
Write-Host "Starting IIS services..."
try {
    Start-WebAppPool -Name $AppPoolName
    Start-Website -Name $SiteName
    Write-Host "[SUCCESS] Started IIS services"
} catch {
    Write-Warning "[WARNING] Could not start IIS services: $($_.Exception.Message)"
}

# Show final status
Write-Host ""
Write-Host "=== DEPLOYMENT SUMMARY ==="
Write-Host "✓ Files copied: $($iisFiles.Count)"
Write-Host "✓ Target directory: $IISPath"
Write-Host "✓ Application Pool: $AppPoolName"
Write-Host "✓ Website: $SiteName"

# Show deployed files
Write-Host ""
Write-Host "Deployed files in IIS directory:"
Get-ChildItem -Path $IISPath | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize

# Clean up temp directory (optional)
$cleanup = Read-Host "Do you want to clean up the temporary directory? (y/N)"
if ($cleanup -eq "y" -or $cleanup -eq "Y") {
    try {
        Remove-Item -Path $TempPath -Recurse -Force
        Write-Host "[SUCCESS] Cleaned up temporary directory"
    } catch {
        Write-Warning "[WARNING] Could not clean up temp directory: $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "=== DEPLOYMENT COMPLETED ==="
Write-Host "Your application should now be accessible via IIS"
Write-Host "Check the website at: http://localhost (or your configured domain)" 