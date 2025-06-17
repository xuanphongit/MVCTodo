# Simple HTTP 500.19 Diagnostic Script
param(
    [string]$SitePath = "C:\inetpub\wwwroot\TodoApp"
)

Write-Host "=== HTTP 500.19 DIAGNOSTIC TOOL ===" -ForegroundColor Cyan
Write-Host "Error Code: 0x8007000d - Configuration data is invalid"
Write-Host ""

$issues = @()

# 1. Check ASP.NET Core Module
Write-Host "[1] Checking ASP.NET Core Module..." -ForegroundColor Yellow
$aspnetCoreModulePath = "$env:SystemRoot\System32\inetsrv\aspnetcorev2.dll"
if (Test-Path $aspnetCoreModulePath) {
    Write-Host "    OK - AspNetCoreModuleV2 exists" -ForegroundColor Green
} else {
    Write-Host "    ERROR - AspNetCoreModuleV2 NOT FOUND" -ForegroundColor Red
    $issues += "ASP.NET Core Hosting Bundle not installed"
}

# 2. Check .NET Runtime
Write-Host "[2] Checking .NET Runtime..." -ForegroundColor Yellow
try {
    $dotnetVersion = dotnet --version
    Write-Host "    OK - .NET Runtime: $dotnetVersion" -ForegroundColor Green
} catch {
    Write-Host "    ERROR - .NET Runtime NOT FOUND" -ForegroundColor Red
    $issues += ".NET Runtime not installed"
}

# 3. Check Application Files
Write-Host "[3] Checking Application Files..." -ForegroundColor Yellow
if (Test-Path $SitePath) {
    Write-Host "    OK - Site directory exists: $SitePath" -ForegroundColor Green
    
    $webConfigPath = "$SitePath\web.config"
    $dllPath = "$SitePath\Todo.dll"
    
    if (Test-Path $webConfigPath) {
        Write-Host "    OK - web.config exists" -ForegroundColor Green
    } else {
        Write-Host "    ERROR - web.config NOT FOUND" -ForegroundColor Red
        $issues += "web.config missing"
    }
    
    if (Test-Path $dllPath) {
        Write-Host "    OK - Todo.dll exists" -ForegroundColor Green
    } else {
        Write-Host "    ERROR - Todo.dll NOT FOUND" -ForegroundColor Red
        $issues += "Application DLL missing"
    }
} else {
    Write-Host "    ERROR - Site directory NOT FOUND: $SitePath" -ForegroundColor Red
    $issues += "Application not deployed"
}

# 4. Check Application Pool
Write-Host "[4] Checking Application Pool..." -ForegroundColor Yellow
try {
    $appPoolName = "TodoMVCAppPool"
    $appPoolCheck = & "$env:SystemRoot\System32\inetsrv\appcmd.exe" list apppool $appPoolName 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    OK - Application pool exists: $appPoolName" -ForegroundColor Green
    } else {
        Write-Host "    ERROR - Application pool NOT FOUND: $appPoolName" -ForegroundColor Red
        $issues += "Application pool not created"
    }
} catch {
    Write-Host "    ERROR - Cannot check application pool" -ForegroundColor Red
    $issues += "Cannot verify application pool"
}

# 5. Check Website
Write-Host "[5] Checking Website..." -ForegroundColor Yellow
try {
    $siteName = "TodoMVCApp"
    $siteCheck = & "$env:SystemRoot\System32\inetsrv\appcmd.exe" list site $siteName 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    OK - Website exists: $siteName" -ForegroundColor Green
    } else {
        Write-Host "    ERROR - Website NOT FOUND: $siteName" -ForegroundColor Red
        $issues += "Website not created in IIS"
    }
} catch {
    Write-Host "    ERROR - Cannot check website" -ForegroundColor Red
    $issues += "Cannot verify website configuration"
}

# Summary
Write-Host ""
Write-Host "=== DIAGNOSTIC SUMMARY ===" -ForegroundColor Cyan

if ($issues.Count -eq 0) {
    Write-Host "No obvious issues found!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Try these quick fixes:" -ForegroundColor Yellow
    Write-Host "1. Restart IIS: iisreset"
    Write-Host "2. Restart Application Pool"
    Write-Host "3. Check Windows Event Logs"
} else {
    Write-Host "Found $($issues.Count) potential issue(s):" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host "  - $issue" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "=== RECOMMENDED SOLUTIONS ===" -ForegroundColor Cyan
    
    if ($issues -contains "ASP.NET Core Hosting Bundle not installed") {
        Write-Host "1. Install ASP.NET Core Hosting Bundle:" -ForegroundColor Yellow
        Write-Host "   Run: .\scripts\fix-aspnet-core-500-19.ps1"
        Write-Host ""
    }
    
    if ($issues -contains "Application not deployed") {
        Write-Host "2. Deploy your application:" -ForegroundColor Yellow
        Write-Host "   Run the GitHub Actions workflow"
        Write-Host ""
    }
    
    if ($issues -contains "Application pool not created") {
        Write-Host "3. Setup IIS:" -ForegroundColor Yellow
        Write-Host "   Run: .\scripts\setup-webdeploy.ps1"
        Write-Host ""
    }
}

Write-Host "For comprehensive fix, run: .\scripts\fix-aspnet-core-500-19.ps1" -ForegroundColor Green 