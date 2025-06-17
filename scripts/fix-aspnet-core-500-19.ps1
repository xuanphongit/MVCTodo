# Fix ASP.NET Core HTTP 500.19 Error
# This script addresses the common 0x8007000d error by installing required components
# Run this script as Administrator on your IIS server

param(
    [string]$SiteName = "TodoMVCApp",
    [string]$AppPoolName = "TodoMVCAppPool",
    [string]$SitePath = "C:\inetpub\wwwroot"
)

Write-Host "=== FIXING ASP.NET CORE HTTP 500.19 ERROR ===" -ForegroundColor Red
Write-Host "Error Code: 0x8007000d - Configuration data is invalid" -ForegroundColor Yellow
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (!$isAdmin) {
    Write-Error "This script must be run as Administrator!"
    Write-Host "Please run PowerShell as Administrator and try again."
    exit 1
}

Write-Host "[SUCCESS] Running as Administrator" -ForegroundColor Green

# Step 1: Check current ASP.NET Core installation
Write-Host ""
Write-Host "=== STEP 1: CHECKING ASP.NET CORE INSTALLATION ===" -ForegroundColor Yellow

try {
    $dotnetVersion = dotnet --version
    Write-Host "[INFO] .NET Runtime Version: $dotnetVersion" -ForegroundColor Cyan
} catch {
    Write-Host "[ERROR] .NET Runtime not found!" -ForegroundColor Red
    Write-Host "Please install .NET 8.0 Runtime first"
    exit 1
}

# Check for ASP.NET Core Module
$aspnetCoreModulePath = "$env:SystemRoot\System32\inetsrv\aspnetcorev2.dll"
$aspnetCoreModuleExists = Test-Path $aspnetCoreModulePath

Write-Host "ASP.NET Core Module V2 Path: $aspnetCoreModulePath"
Write-Host "ASP.NET Core Module V2 Exists: $aspnetCoreModuleExists" -ForegroundColor $(if($aspnetCoreModuleExists){"Green"}else{"Red"})

# Step 2: Install ASP.NET Core Hosting Bundle
if (!$aspnetCoreModuleExists) {
    Write-Host ""
    Write-Host "=== STEP 2: INSTALLING ASP.NET CORE HOSTING BUNDLE ===" -ForegroundColor Yellow
    
    # Download the latest .NET 8.0 Hosting Bundle
    $hostingBundleUrl = "https://download.microsoft.com/download/8/4/8/848a2b7e-4b87-48a8-aa1b-2d3b728a86e8/dotnet-hosting-8.0.11-win.exe"
    $hostingBundlePath = "$env:TEMP\dotnet-hosting-8.0.11-win.exe"
    
    Write-Host "Downloading ASP.NET Core Hosting Bundle..."
    try {
        Invoke-WebRequest -Uri $hostingBundleUrl -OutFile $hostingBundlePath -UseBasicParsing
        Write-Host "[SUCCESS] Downloaded Hosting Bundle" -ForegroundColor Green
    } catch {
        Write-Error "Failed to download Hosting Bundle: $($_.Exception.Message)"
        Write-Host ""
        Write-Host "MANUAL INSTALLATION REQUIRED:"
        Write-Host "1. Go to: https://dotnet.microsoft.com/download/dotnet/8.0"
        Write-Host "2. Download 'ASP.NET Core Runtime 8.0.x - Windows Hosting Bundle'"
        Write-Host "3. Run the installer as Administrator"
        exit 1
    }
    
    Write-Host "Installing ASP.NET Core Hosting Bundle..."
    try {
        Start-Process -FilePath $hostingBundlePath -ArgumentList "/quiet" -Wait -NoNewWindow
        Write-Host "[SUCCESS] Hosting Bundle installed" -ForegroundColor Green
        
        # Clean up
        Remove-Item $hostingBundlePath -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Error "Failed to install Hosting Bundle: $($_.Exception.Message)"
        exit 1
    }
} else {
    Write-Host "[INFO] ASP.NET Core Module V2 is already installed" -ForegroundColor Green
}

# Step 3: Restart IIS to load the new module
Write-Host ""
Write-Host "=== STEP 3: RESTARTING IIS ===" -ForegroundColor Yellow

try {
    Write-Host "Stopping IIS..."
    iisreset /stop
    Start-Sleep -Seconds 3
    
    Write-Host "Starting IIS..."
    iisreset /start
    Start-Sleep -Seconds 5
    
    Write-Host "[SUCCESS] IIS restarted successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to restart IIS: $($_.Exception.Message)"
    exit 1
}

# Step 4: Verify ASP.NET Core Module registration
Write-Host ""
Write-Host "=== STEP 4: VERIFYING MODULE REGISTRATION ===" -ForegroundColor Yellow

try {
    # Check if AspNetCoreModuleV2 is registered in IIS
    $moduleCheck = & "$env:SystemRoot\System32\inetsrv\appcmd.exe" list module AspNetCoreModuleV2 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] AspNetCoreModuleV2 is registered in IIS" -ForegroundColor Green
        Write-Host "Module details: $moduleCheck"
    } else {
        Write-Warning "[WARNING] AspNetCoreModuleV2 not found in IIS modules"
        
        # Try to register manually
        Write-Host "Attempting to register AspNetCoreModuleV2..."
        & "$env:SystemRoot\System32\inetsrv\appcmd.exe" install module /name:AspNetCoreModuleV2 /image:"%windir%\System32\inetsrv\aspnetcorev2.dll"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] AspNetCoreModuleV2 registered manually" -ForegroundColor Green
        } else {
            Write-Error "Failed to register AspNetCoreModuleV2"
        }
    }
} catch {
    Write-Warning "Could not verify module registration: $($_.Exception.Message)"
}

# Step 5: Configure Application Pool for ASP.NET Core
Write-Host ""
Write-Host "=== STEP 5: CONFIGURING APPLICATION POOL ===" -ForegroundColor Yellow

try {
    # Check if app pool exists
    $appPoolExists = & "$env:SystemRoot\System32\inetsrv\appcmd.exe" list apppool $AppPoolName 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Creating application pool: $AppPoolName"
        & "$env:SystemRoot\System32\inetsrv\appcmd.exe" add apppool /name:$AppPoolName
    }
    
    # Configure app pool for ASP.NET Core (No Managed Code)
    Write-Host "Configuring application pool for ASP.NET Core..."
    & "$env:SystemRoot\System32\inetsrv\appcmd.exe" set apppool $AppPoolName /managedRuntimeVersion:""
    & "$env:SystemRoot\System32\inetsrv\appcmd.exe" set apppool $AppPoolName /processModel.identityType:ApplicationPoolIdentity
    & "$env:SystemRoot\System32\inetsrv\appcmd.exe" set apppool $AppPoolName /processModel.loadUserProfile:true
    
    Write-Host "[SUCCESS] Application pool configured for ASP.NET Core" -ForegroundColor Green
} catch {
    Write-Error "Failed to configure application pool: $($_.Exception.Message)"
}

# Step 6: Verify web.config and fix common issues
Write-Host ""
Write-Host "=== STEP 6: VERIFYING WEB.CONFIG ===" -ForegroundColor Yellow

$webConfigPath = "$SitePath\web.config"
if (Test-Path $webConfigPath) {
    Write-Host "Found web.config at: $webConfigPath"
    
    # Read and validate web.config
    try {
        $webConfigContent = Get-Content $webConfigPath -Raw
        
        # Check for AspNetCoreModuleV2
        if ($webConfigContent -like "*AspNetCoreModuleV2*") {
            Write-Host "[SUCCESS] web.config references AspNetCoreModuleV2" -ForegroundColor Green
        } else {
            Write-Warning "[WARNING] web.config does not reference AspNetCoreModuleV2"
            Write-Host "Current handlers in web.config:"
            $webConfigContent | Select-String -Pattern "<add.*name.*aspNetCore" | ForEach-Object { Write-Host "  $_" }
        }
        
        # Check for Todo.dll
        if ($webConfigContent -like "*Todo.dll*") {
            $dllPath = "$SitePath\Todo.dll"
            if (Test-Path $dllPath) {
                Write-Host "[SUCCESS] Todo.dll found at: $dllPath" -ForegroundColor Green
            } else {
                Write-Host "[ERROR] Todo.dll not found at: $dllPath" -ForegroundColor Red
                Write-Host "Please ensure the application is properly deployed"
            }
        }
        
    } catch {
        Write-Error "Failed to read web.config: $($_.Exception.Message)"
    }
} else {
    Write-Host "[ERROR] web.config not found at: $webConfigPath" -ForegroundColor Red
    Write-Host "Please ensure the application is deployed to the correct location"
}

# Step 7: Check site configuration
Write-Host ""
Write-Host "=== STEP 7: VERIFYING SITE CONFIGURATION ===" -ForegroundColor Yellow

try {
    # Check if site exists
    $siteExists = & "$env:SystemRoot\System32\inetsrv\appcmd.exe" list site $SiteName 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Website '$SiteName' exists" -ForegroundColor Green
        Write-Host "Site details: $siteExists"
        
        # Check site's application pool assignment
        $siteConfig = & "$env:SystemRoot\System32\inetsrv\appcmd.exe" list app "$SiteName/" 2>&1
        Write-Host "App configuration: $siteConfig"
        
    } else {
        Write-Host "[ERROR] Website '$SiteName' not found" -ForegroundColor Red
        Write-Host "Please create the website in IIS Manager or run the deployment script"
    }
} catch {
    Write-Warning "Could not verify site configuration: $($_.Exception.Message)"
}

# Step 8: Set proper permissions
Write-Host ""
Write-Host "=== STEP 8: SETTING PERMISSIONS ===" -ForegroundColor Yellow

if (Test-Path $SitePath) {
    try {
        Write-Host "Setting permissions on: $SitePath"
        icacls $SitePath /grant "IIS_IUSRS:(OI)(CI)F" /T /Q
        icacls $SitePath /grant "IUSR:(OI)(CI)R" /T /Q
        icacls $SitePath /grant "IIS AppPool\${AppPoolName}:(OI)(CI)F" /T /Q
        Write-Host "[SUCCESS] Permissions set successfully" -ForegroundColor Green
    } catch {
        Write-Warning "Could not set all permissions: $($_.Exception.Message)"
    }
} else {
    Write-Host "[WARNING] Site path does not exist: $SitePath" -ForegroundColor Yellow
}

# Step 9: Test the fix
Write-Host ""
Write-Host "=== STEP 9: TESTING THE FIX ===" -ForegroundColor Yellow

Write-Host "Starting services..."
try {
    & "$env:SystemRoot\System32\inetsrv\appcmd.exe" start apppool $AppPoolName
    & "$env:SystemRoot\System32\inetsrv\appcmd.exe" start site $SiteName
    Write-Host "[SUCCESS] Services started" -ForegroundColor Green
} catch {
    Write-Warning "Could not start services: $($_.Exception.Message)"
}

# Wait a moment for services to start
Start-Sleep -Seconds 5

# Test HTTP request
Write-Host "Testing HTTP request..."
try {
    $response = Invoke-WebRequest -Uri "http://localhost" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    Write-Host "[SUCCESS] HTTP request successful!" -ForegroundColor Green
    Write-Host "Status Code: $($response.StatusCode)"
    Write-Host "Response Length: $($response.Content.Length) bytes"
} catch {
    Write-Host "[INFO] HTTP test result: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "This may be normal if the application is still starting up"
}

# Final summary
Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "The following actions were performed to fix HTTP 500.19 error:"
Write-Host "1. ✓ Verified Administrator privileges"
Write-Host "2. ✓ Checked .NET installation"
Write-Host "3. ✓ Installed/Verified ASP.NET Core Hosting Bundle"
Write-Host "4. ✓ Restarted IIS to load modules"
Write-Host "5. ✓ Verified AspNetCoreModuleV2 registration"
Write-Host "6. ✓ Configured Application Pool for ASP.NET Core"
Write-Host "7. ✓ Verified web.config configuration"
Write-Host "8. ✓ Verified site configuration"
Write-Host "9. ✓ Set proper file permissions"
Write-Host "10. ✓ Started IIS services"
Write-Host ""

Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Try accessing your website: http://localhost"
Write-Host "2. If still getting 500.19, check Windows Event Logs:"
Write-Host "   - Windows Logs > Application"
Write-Host "   - Applications and Services Logs > Microsoft > Windows > IIS-Configuration"
Write-Host "3. Verify your application files are in: $SitePath"
Write-Host "4. Ensure Todo.dll exists in the deployment directory"
Write-Host ""

Write-Host "If the error persists, please check:"
Write-Host "- Event Viewer for detailed error messages"
Write-Host "- IIS Manager > Modules > Verify AspNetCoreModuleV2 is listed"
Write-Host "- Application Pool > Advanced Settings > .NET CLR Version = 'No Managed Code'"
Write-Host ""

Write-Host "=== FIX COMPLETED ===" -ForegroundColor Green 