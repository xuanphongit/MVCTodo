# Quick Diagnostic Script for HTTP 500.19 Error
# This script quickly checks the common causes of the error

param(
    [string]$SitePath = "C:\inetpub\wwwroot\TodoApp"
)

Write-Host "=== HTTP 500.19 DIAGNOSTIC TOOL ===" -ForegroundColor Cyan
Write-Host "Checking common causes of error code 0x8007000d"
Write-Host ""

$issues = @()

# 1. Check ASP.NET Core Module
Write-Host "[1] Checking ASP.NET Core Module..." -ForegroundColor Yellow
$aspnetCoreModulePath = "$env:SystemRoot\System32\inetsrv\aspnetcorev2.dll"
if (Test-Path $aspnetCoreModulePath) {
    Write-Host "    ✓ AspNetCoreModuleV2 exists" -ForegroundColor Green
} else {
    Write-Host "    ✗ AspNetCoreModuleV2 NOT FOUND" -ForegroundColor Red
    $issues += "ASP.NET Core Hosting Bundle not installed"
}

# 2. Check IIS Module Registration
Write-Host "[2] Checking IIS Module Registration..." -ForegroundColor Yellow
try {
    $moduleCheck = & "$env:SystemRoot\System32\inetsrv\appcmd.exe" list module AspNetCoreModuleV2 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    ✓ AspNetCoreModuleV2 registered in IIS" -ForegroundColor Green
    } else {
        Write-Host "    ✗ AspNetCoreModuleV2 NOT registered in IIS" -ForegroundColor Red
        $issues += "AspNetCoreModuleV2 not registered in IIS"
    }
} catch {
    Write-Host "    ✗ Cannot check module registration" -ForegroundColor Red
    $issues += "Cannot verify IIS module registration"
}

# 3. Check .NET Runtime
Write-Host "[3] Checking .NET Runtime..." -ForegroundColor Yellow
try {
    $dotnetVersion = dotnet --version
    Write-Host "    ✓ .NET Runtime: $dotnetVersion" -ForegroundColor Green
} catch {
    Write-Host "    ✗ .NET Runtime NOT FOUND" -ForegroundColor Red
    $issues += ".NET Runtime not installed"
}

# 4. Check Application Files
Write-Host "[4] Checking Application Files..." -ForegroundColor Yellow
if (Test-Path $SitePath) {
    Write-Host "    ✓ Site directory exists: $SitePath" -ForegroundColor Green
    
    # Check for key files
    $webConfigPath = "$SitePath\web.config"
    $dllPath = "$SitePath\Todo.dll"
    
    if (Test-Path $webConfigPath) {
        Write-Host "    ✓ web.config exists" -ForegroundColor Green
    } else {
        Write-Host "    ✗ web.config NOT FOUND" -ForegroundColor Red
        $issues += "web.config missing"
    }
    
    if (Test-Path $dllPath) {
        Write-Host "    ✓ Todo.dll exists" -ForegroundColor Green
    } else {
        Write-Host "    ✗ Todo.dll NOT FOUND" -ForegroundColor Red
        $issues += "Application DLL missing"
    }
} else {
    Write-Host "    ✗ Site directory NOT FOUND: $SitePath" -ForegroundColor Red
    $issues += "Application not deployed"
}

# 5. Check Application Pool Configuration
Write-Host "[5] Checking Application Pool..." -ForegroundColor Yellow
try {
    $appPoolName = "TodoMVCAppPool"
    $appPoolConfig = & "$env:SystemRoot\System32\inetsrv\appcmd.exe" list apppool $appPoolName 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    ✓ Application pool exists: $appPoolName" -ForegroundColor Green
        
        # Check runtime version
        if ($appPoolConfig -like "*managedRuntimeVersion:*") {
            $runtimeMatch = $appPoolConfig | Select-String "managedRuntimeVersion:([^,]*)"
            if ($runtimeMatch) {
                $runtimeVersion = $runtimeMatch.Matches.Groups[1].Value
                if ($runtimeVersion -eq '""' -or $runtimeVersion -eq "") {
                    Write-Host "    ✓ Runtime version: No Managed Code (correct for ASP.NET Core)" -ForegroundColor Green
                } else {
                    Write-Host "    ⚠ Runtime version: $runtimeVersion (should be 'No Managed Code')" -ForegroundColor Yellow
                    $issues += "Application pool not configured for ASP.NET Core"
                }
            }
        }
    } else {
        Write-Host "    ✗ Application pool NOT FOUND: $appPoolName" -ForegroundColor Red
        $issues += "Application pool not created"
    }
} catch {
    Write-Host "    ✗ Cannot check application pool" -ForegroundColor Red
    $issues += "Cannot verify application pool"
}

# 6. Check Website Configuration
Write-Host "[6] Checking Website Configuration..." -ForegroundColor Yellow
try {
    $siteName = "TodoMVCApp"
    $siteConfig = & "$env:SystemRoot\System32\inetsrv\appcmd.exe" list site $siteName 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    ✓ Website exists: $siteName" -ForegroundColor Green
    } else {
        Write-Host "    ✗ Website NOT FOUND: $siteName" -ForegroundColor Red
        $issues += "Website not created in IIS"
    }
} catch {
    Write-Host "    ✗ Cannot check website" -ForegroundColor Red
    $issues += "Cannot verify website configuration"
}

# 7. Check File Permissions
Write-Host "[7] Checking File Permissions..." -ForegroundColor Yellow
if (Test-Path $SitePath) {
    try {
        # Try to create a test file to check write permissions
        $testFile = "$SitePath\permission_test.txt"
        "test" | Out-File -FilePath $testFile -Force
        Remove-Item $testFile -Force
        Write-Host "    ✓ IIS has write permissions" -ForegroundColor Green
    } catch {
        Write-Host "    ⚠ Permission issues detected" -ForegroundColor Yellow
        $issues += "File permission issues"
    }
} else {
    Write-Host "    - Cannot check permissions (site directory missing)" -ForegroundColor Gray
}

# Summary
Write-Host ""
Write-Host "=== DIAGNOSTIC SUMMARY ===" -ForegroundColor Cyan

if ($issues.Count -eq 0) {
    Write-Host "✓ No obvious issues found!" -ForegroundColor Green
    Write-Host "The 500.19 error might be caused by:"
    Write-Host "  - Temporary IIS issues (try restarting IIS)"
    Write-Host "  - Recent Windows updates affecting ASP.NET Core"
    Write-Host "  - Antivirus software blocking files"
} else {
    Write-Host "✗ Found $($issues.Count) potential issue(s):" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host "  • $issue" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== RECOMMENDED ACTIONS ===" -ForegroundColor Cyan

if ($issues -contains "ASP.NET Core Hosting Bundle not installed") {
    Write-Host "1. Install ASP.NET Core Hosting Bundle:" -ForegroundColor Yellow
    Write-Host "   Run: .\scripts\fix-aspnet-core-500-19.ps1"
}

if ($issues -contains "Application not deployed") {
    Write-Host "2. Deploy your application:" -ForegroundColor Yellow
    Write-Host "   Run the GitHub Actions workflow or manual deployment"
}

if ($issues -contains "Application pool not created") {
    Write-Host "3. Create IIS Application Pool and Website:" -ForegroundColor Yellow
    Write-Host "   Run: .\scripts\setup-webdeploy.ps1"
}

if ($issues.Count -eq 0 -or $issues -notcontains "ASP.NET Core Hosting Bundle not installed") {
    Write-Host "Quick fix attempts:" -ForegroundColor Yellow
    Write-Host "1. Restart IIS: iisreset"
    Write-Host "2. Restart Application Pool: appcmd start apppool TodoMVCAppPool"
    Write-Host "3. Check Windows Event Logs for detailed errors"
}

Write-Host ""
Write-Host "For comprehensive fix, run: .\scripts\fix-aspnet-core-500-19.ps1" -ForegroundColor Green 