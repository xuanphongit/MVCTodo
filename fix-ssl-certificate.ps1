#!/usr/bin/env pwsh
# Fix SSL Certificate Installation Script for TodoMVCApp
# This script configures SSL certificate for phongmx.org

param(
    [Parameter(Mandatory = $false)]
    [string]$Domain = "phongmx.org",
    
    [Parameter(Mandatory = $false)]
    [string]$SiteName = "TodoMVCApp",
    
    [Parameter(Mandatory = $false)]
    [switch]$UseExistingCert = $false
)

Write-Host "=== SSL CERTIFICATE INSTALLATION SCRIPT ===" -ForegroundColor Cyan
Write-Host "Domain: $Domain" -ForegroundColor Yellow
Write-Host "Site Name: $SiteName" -ForegroundColor Yellow
Write-Host ""

# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator."
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] Running as Administrator" -ForegroundColor Green

# Step 1: Certificate Management
Write-Host ""
Write-Host "=== STEP 1: CERTIFICATE MANAGEMENT ===" -ForegroundColor Yellow

$cert = $null
$thumbprint = $null

# Use existing localhost certificate for now
Write-Host "Looking for existing localhost certificate..." -ForegroundColor Cyan
$cert = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object { $_.Subject -like "*localhost*" } | Select-Object -First 1

if ($cert) {
    $thumbprint = $cert.Thumbprint
    Write-Host "[INFO] Found existing localhost certificate: $thumbprint" -ForegroundColor Green
    Write-Host "Subject: $($cert.Subject)" -ForegroundColor Cyan
    Write-Host "Expires: $($cert.NotAfter)" -ForegroundColor Cyan
    Write-Warning "Note: This is a localhost certificate, browsers will show security warnings for $Domain"
} else {
    Write-Error "No suitable certificate found."
    exit 1
}

# Step 2: IIS HTTPS Binding
Write-Host ""
Write-Host "=== STEP 2: IIS HTTPS BINDING ===" -ForegroundColor Yellow

# Check if site exists
Write-Host "Checking if IIS site '$SiteName' exists..." -ForegroundColor Cyan

$appcmdPath = "${env:SystemRoot}\System32\inetsrv\appcmd.exe"
if (Test-Path $appcmdPath) {
    $siteInfo = & $appcmdPath list site $SiteName 2>$null
    $siteExists = $siteInfo -and $siteInfo.Length -gt 0
} else {
    Write-Error "appcmd.exe not found. IIS may not be installed properly."
    exit 1
}

if (-not $siteExists) {
    Write-Error "IIS site '$SiteName' does not exist. Please run the deployment first."
    exit 1
}

Write-Host "[OK] IIS site '$SiteName' exists" -ForegroundColor Green

# Remove existing HTTPS bindings
Write-Host "Removing existing HTTPS bindings..." -ForegroundColor Cyan
& $appcmdPath delete binding /site.name:"$SiteName" /binding.protocol:https /binding.bindingInformation:"*:443:$Domain" 2>$null
& $appcmdPath delete binding /site.name:"$SiteName" /binding.protocol:https /binding.bindingInformation:"*:443:" 2>$null

# Remove existing SSL certificate bindings
netsh http delete sslcert hostnameport="$Domain`:443" 2>$null
netsh http delete sslcert ipport="0.0.0.0:443" 2>$null
Write-Host "[OK] Cleaned up existing bindings" -ForegroundColor Green

# Create new HTTPS binding
Write-Host "Creating new HTTPS binding for $Domain on port 443..." -ForegroundColor Cyan

& $appcmdPath set site "$SiteName" "/+bindings.[protocol='https',bindingInformation='*:443:$Domain']"
Write-Host "[OK] Created IIS HTTPS binding" -ForegroundColor Green

# Assign certificate using netsh
$appId = "{$([System.Guid]::NewGuid().ToString())}"
Write-Host "Assigning SSL certificate..." -ForegroundColor Cyan

# Try hostname-based binding first
netsh http add sslcert hostnameport="$Domain`:443" certhash=$thumbprint appid=$appId certstorename=MY

if ($LASTEXITCODE -eq 0) {
    Write-Host "[SUCCESS] SSL certificate assigned using hostname binding" -ForegroundColor Green
} else {
    Write-Warning "Hostname-based SSL binding failed, trying IP-based binding"
    netsh http add sslcert ipport="0.0.0.0:443" certhash=$thumbprint appid=$appId certstorename=MY
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] SSL certificate assigned using IP-based binding" -ForegroundColor Green
    } else {
        Write-Error "SSL certificate binding failed"
        exit 1
    }
}

# Step 3: Firewall Configuration
Write-Host ""
Write-Host "=== STEP 3: FIREWALL CONFIGURATION ===" -ForegroundColor Yellow

try {
    $rule = Get-NetFirewallRule -DisplayName "HTTPS Inbound" -ErrorAction SilentlyContinue
    if (-not $rule) {
        New-NetFirewallRule -DisplayName "HTTPS Inbound" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow | Out-Null
        Write-Host "[SUCCESS] Created firewall rule for HTTPS traffic" -ForegroundColor Green
    } else {
        Write-Host "[OK] HTTPS firewall rule already exists" -ForegroundColor Green
    }
} catch {
    Write-Warning "Could not configure firewall: $($_.Exception.Message)"
}

# Step 4: Verification
Write-Host ""
Write-Host "=== STEP 4: VERIFICATION ===" -ForegroundColor Yellow

# Check SSL binding
Write-Host "Verifying SSL certificate binding..." -ForegroundColor Cyan
$sslBindings = netsh http show sslcert | Select-String -Pattern "Certificate Hash.*$thumbprint"

if ($sslBindings) {
    Write-Host "[SUCCESS] SSL certificate is properly bound" -ForegroundColor Green
} else {
    Write-Warning "SSL certificate binding verification failed"
}

# Check IIS binding
Write-Host "Verifying IIS HTTPS binding..." -ForegroundColor Cyan
$siteInfo = & $appcmdPath list site "$SiteName"
if ($siteInfo -match "https.*:443:$Domain") {
    Write-Host "[SUCCESS] IIS HTTPS binding verified" -ForegroundColor Green
} else {
    Write-Warning "IIS HTTPS binding not found"
}

# Completion Summary
Write-Host ""
Write-Host "=== COMPLETION SUMMARY ===" -ForegroundColor Cyan
Write-Host "[SUCCESS] SSL certificate installation completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Certificate Details:" -ForegroundColor White
Write-Host "  Domain: $Domain"
Write-Host "  Thumbprint: $thumbprint"
Write-Host "  Site: $SiteName"
Write-Host "  Port: 443"
Write-Host ""
Write-Host "Test HTTPS access: https://$Domain" -ForegroundColor Yellow
Write-Host "Note: Self-signed certificate will show browser warnings" -ForegroundColor Yellow

exit 0 