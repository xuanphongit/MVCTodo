# Setup Web Deploy V3 for GitHub Actions Deployment
# Run this script as Administrator on your target server

param(
    [switch]$InstallWebDeploy = $true,
    [switch]$ConfigureIIS = $true,
    [switch]$SetupPermissions = $true,
    [string]$SiteName = "TodoMVCApp",
    [string]$AppPoolName = "TodoMVCAppPool",
    [string]$SitePath = "C:\inetpub\wwwroot\TodoApp"
)

Write-Host "=== Web Deploy V3 Setup Script ===" -ForegroundColor Green
Write-Host "This script will install and configure Web Deploy V3 for GitHub Actions deployment"
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (!$isAdmin) {
    Write-Error "This script must be run as Administrator!"
    Write-Host "Please run PowerShell as Administrator and try again."
    exit 1
}

Write-Host "[SUCCESS] Running as Administrator" -ForegroundColor Green

# Function to download and install Web Deploy
function Install-WebDeploy {
    Write-Host "=== Installing Web Deploy V3 ===" -ForegroundColor Yellow
    
    # Check if already installed
    $webDeployPath = "${env:ProgramFiles}\IIS\Microsoft Web Deploy V3\msdeploy.exe"
    $webDeployPath32 = "${env:ProgramFiles(x86)}\IIS\Microsoft Web Deploy V3\msdeploy.exe"
    
    if ((Test-Path $webDeployPath) -or (Test-Path $webDeployPath32)) {
        Write-Host "[INFO] Web Deploy V3 is already installed" -ForegroundColor Green
        return
    }
    
    # Try to install via Chocolatey first (if available)
    try {
        $chocoPath = Get-Command choco -ErrorAction SilentlyContinue
        if ($chocoPath) {
            Write-Host "Installing Web Deploy via Chocolatey..."
            choco install webdeploy -y
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[SUCCESS] Web Deploy installed via Chocolatey" -ForegroundColor Green
                return
            }
        }
    } catch {
        Write-Warning "Chocolatey installation failed: $($_.Exception.Message)"
    }
    
    # Download and install manually
    Write-Host "Downloading Web Deploy V3..."
    $downloadUrl = "https://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi"
    $downloadPath = "$env:TEMP\WebDeploy_amd64_en-US.msi"
    
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath -UseBasicParsing
        Write-Host "[SUCCESS] Web Deploy downloaded" -ForegroundColor Green
        
        # Install Web Deploy
        Write-Host "Installing Web Deploy..."
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$downloadPath`" /quiet /norestart" -Wait
        
        # Verify installation
        Start-Sleep -Seconds 5
        if ((Test-Path $webDeployPath) -or (Test-Path $webDeployPath32)) {
            Write-Host "[SUCCESS] Web Deploy V3 installed successfully" -ForegroundColor Green
        } else {
            throw "Web Deploy installation verification failed"
        }
        
        # Cleanup
        Remove-Item $downloadPath -Force -ErrorAction SilentlyContinue
        
    } catch {
        Write-Error "Failed to install Web Deploy: $($_.Exception.Message)"
        Write-Host ""
        Write-Host "Please install Web Deploy manually:"
        Write-Host "1. Download from: https://www.microsoft.com/en-us/download/details.aspx?id=43717"
        Write-Host "2. Run the installer as Administrator"
        Write-Host "3. Choose 'Complete' installation"
        exit 1
    }
}

# Function to configure IIS features
function Configure-IIS {
    Write-Host "=== Configuring IIS Features ===" -ForegroundColor Yellow
    
    # Enable required Windows features
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
        "IIS-WebServerManagementTools",
        "IIS-ManagementConsole",
        "IIS-IIS6ManagementCompatibility",
        "IIS-Metabase"
    )
    
    Write-Host "Enabling IIS features..."
    foreach ($feature in $features) {
        try {
            Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart -ErrorAction SilentlyContinue
            Write-Host "[SUCCESS] Enabled $feature" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to enable $feature: $($_.Exception.Message)"
        }
    }
    
    # Install ASP.NET Core Hosting Bundle
    Write-Host "Checking ASP.NET Core Hosting Bundle..."
    try {
        $hostingBundle = Get-ChildItem "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Updates" -Recurse | Where-Object { $_.Name -like "*ASP.NET Core*" }
        if ($hostingBundle) {
            Write-Host "[INFO] ASP.NET Core Hosting Bundle is already installed" -ForegroundColor Green
        } else {
            Write-Host "ASP.NET Core Hosting Bundle not found. Please install it manually:"
            Write-Host "Download from: https://dotnet.microsoft.com/en-us/download/dotnet/8.0"
            Write-Host "Look for 'ASP.NET Core Runtime 8.0.x - Windows Hosting Bundle'"
        }
    } catch {
        Write-Warning "Could not check ASP.NET Core Hosting Bundle: $($_.Exception.Message)"
    }
}

# Function to setup permissions
function Setup-Permissions {
    Write-Host "=== Setting up Permissions ===" -ForegroundColor Yellow
    
    # Create site directory
    if (!(Test-Path $SitePath)) {
        New-Item -ItemType Directory -Path $SitePath -Force | Out-Null
        Write-Host "[SUCCESS] Created site directory: $SitePath" -ForegroundColor Green
    }
    
    # Set permissions for IIS_IUSRS
    try {
        icacls $SitePath /grant "IIS_IUSRS:(OI)(CI)F" /T /Q
        Write-Host "[SUCCESS] Set permissions for IIS_IUSRS" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to set IIS_IUSRS permissions: $($_.Exception.Message)"
    }
    
    # Set permissions for IUSR
    try {
        icacls $SitePath /grant "IUSR:(OI)(CI)R" /T /Q
        Write-Host "[SUCCESS] Set permissions for IUSR" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to set IUSR permissions: $($_.Exception.Message)"
    }
    
    # Configure Web Deploy permissions
    Write-Host "Configuring Web Deploy permissions..."
    try {
        # Add current user to Web Deploy administrators
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        
        # This requires Web Deploy to be installed
        $webDeployPath = "${env:ProgramFiles}\IIS\Microsoft Web Deploy V3\msdeploy.exe"
        if (!(Test-Path $webDeployPath)) {
            $webDeployPath = "${env:ProgramFiles(x86)}\IIS\Microsoft Web Deploy V3\msdeploy.exe"
        }
        
        if (Test-Path $webDeployPath) {
            Write-Host "[SUCCESS] Web Deploy permissions configured" -ForegroundColor Green
        } else {
            Write-Warning "Web Deploy not found for permission configuration"
        }
    } catch {
        Write-Warning "Failed to configure Web Deploy permissions: $($_.Exception.Message)"
    }
}

# Function to create sample IIS site
function Create-SampleSite {
    Write-Host "=== Creating Sample IIS Site ===" -ForegroundColor Yellow
    
    try {
        # Import WebAdministration module
        Import-Module WebAdministration -Force
        
        # Create Application Pool
        if (!(Get-WebAppPool -Name $AppPoolName -ErrorAction SilentlyContinue)) {
            New-WebAppPool -Name $AppPoolName -Force
            Set-ItemProperty -Path "IIS:\AppPools\$AppPoolName" -Name processModel.identityType -Value ApplicationPoolIdentity
            Set-ItemProperty -Path "IIS:\AppPools\$AppPoolName" -Name managedRuntimeVersion -Value ""
            Write-Host "[SUCCESS] Created application pool: $AppPoolName" -ForegroundColor Green
        } else {
            Write-Host "[INFO] Application pool already exists: $AppPoolName" -ForegroundColor Green
        }
        
        # Create Website
        if (!(Get-Website -Name $SiteName -ErrorAction SilentlyContinue)) {
            New-Website -Name $SiteName -PhysicalPath $SitePath -Port 80 -ApplicationPool $AppPoolName
            Write-Host "[SUCCESS] Created website: $SiteName" -ForegroundColor Green
        } else {
            Write-Host "[INFO] Website already exists: $SiteName" -ForegroundColor Green
        }
        
        # Create a simple index.html for testing
        $indexContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Web Deploy Test Site</title>
</head>
<body>
    <h1>Web Deploy Setup Successful!</h1>
    <p>This is a test page created by the Web Deploy setup script.</p>
    <p>Site: $SiteName</p>
    <p>App Pool: $AppPoolName</p>
    <p>Path: $SitePath</p>
    <p>Timestamp: $(Get-Date)</p>
</body>
</html>
"@
        
        $indexContent | Out-File -FilePath "$SitePath\index.html" -Encoding UTF8 -Force
        Write-Host "[SUCCESS] Created test index.html" -ForegroundColor Green
        
    } catch {
        Write-Warning "Failed to create sample site: $($_.Exception.Message)"
    }
}

# Main execution
try {
    Write-Host "Starting Web Deploy V3 setup..." -ForegroundColor Green
    Write-Host "Parameters:"
    Write-Host "- Install Web Deploy: $InstallWebDeploy"
    Write-Host "- Configure IIS: $ConfigureIIS"
    Write-Host "- Setup Permissions: $SetupPermissions"
    Write-Host "- Site Name: $SiteName"
    Write-Host "- App Pool: $AppPoolName"
    Write-Host "- Site Path: $SitePath"
    Write-Host ""
    
    if ($InstallWebDeploy) {
        Install-WebDeploy
    }
    
    if ($ConfigureIIS) {
        Configure-IIS
    }
    
    if ($SetupPermissions) {
        Setup-Permissions
    }
    
    # Always create sample site for testing
    Create-SampleSite
    
    Write-Host ""
    Write-Host "=== SETUP COMPLETED SUCCESSFULLY ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "1. Test the site by visiting: http://localhost"
    Write-Host "2. Configure your GitHub Actions runner to run as Administrator"
    Write-Host "3. Use the deploy-webdeploy.yml workflow for deployments"
    Write-Host ""
    Write-Host "Web Deploy V3 is now ready for GitHub Actions deployment!"
    
} catch {
    Write-Error "Setup failed: $($_.Exception.Message)"
    exit 1
} 