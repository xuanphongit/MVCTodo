# Test Web Deploy Workflow Locally
# This script simulates the GitHub Actions workflow for local testing

param(
    [string]$Method = "auto",
    [switch]$SkipBuild = $false
)

Write-Host "=== LOCAL WEB DEPLOY TEST ==="
Write-Host "Method: $Method"
Write-Host "Skip Build: $SkipBuild"
Write-Host ""

# Set paths (same as workflow)
$projectPath = "Todo.csproj"
$publishPath = "./publish"
$packagePath = "./package"
$siteName = "TodoMVCApp"
$appPoolName = "TodoMVCAppPool"
$sitePath = "C:\inetpub\wwwroot\TodoApp"

# Check admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
Write-Host "[INFO] Running as Administrator: $isAdmin"

if (!$isAdmin) {
    Write-Warning "This script requires Administrator privileges for IIS operations"
    Write-Host "Please run PowerShell as Administrator and try again"
    Write-Host ""
    Write-Host "Or run with limited functionality (file operations only):"
    Write-Host "  .\scripts\test-webdeploy-local.ps1 -Method folder"
    Write-Host ""
    $continue = Read-Host "Continue with limited functionality? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        exit 1
    }
}

# Clean previous builds
if (!$SkipBuild) {
    Write-Host "=== CLEANING PREVIOUS BUILD ==="
    if (Test-Path $publishPath) {
        Remove-Item -Path $publishPath -Recurse -Force
        Write-Host "Cleaned publish directory"
    }
    if (Test-Path $packagePath) {
        Remove-Item -Path $packagePath -Recurse -Force
        Write-Host "Cleaned package directory"
    }
}

# Build and publish
if (!$SkipBuild) {
    Write-Host ""
    Write-Host "=== BUILDING APPLICATION ==="
    Write-Host "Restoring packages..."
    dotnet restore $projectPath
    if ($LASTEXITCODE -ne 0) { throw "Package restore failed" }
    
    Write-Host "Building application..."
    dotnet build $projectPath --configuration Release --no-restore
    if ($LASTEXITCODE -ne 0) { throw "Build failed" }
    
    Write-Host "Publishing application..."
    dotnet publish $projectPath --configuration Release --no-build --output $publishPath --self-contained false
    if ($LASTEXITCODE -ne 0) { throw "Publish failed" }
    
    Write-Host "[SUCCESS] Build and publish completed"
}

# Create package if requested
Write-Host ""
Write-Host "=== CREATING WEB DEPLOY PACKAGE ==="

# Create package directory
if (!(Test-Path $packagePath)) {
    New-Item -ItemType Directory -Path $packagePath -Force | Out-Null
    Write-Host "Created package directory: $packagePath"
}

# Find MSDeploy
$msdeployPath = "${env:ProgramFiles}\IIS\Microsoft Web Deploy V3\msdeploy.exe"
if (!(Test-Path $msdeployPath)) {
    $msdeployPath = "${env:ProgramFiles(x86)}\IIS\Microsoft Web Deploy V3\msdeploy.exe"
}

$packageCreated = $false
if (Test-Path $msdeployPath) {
    try {
        Write-Host "Creating package with MSDeploy..."
        Write-Host "Source: $publishPath"
        Write-Host "Package: $packagePath\TodoApp.zip"
        
        & "$msdeployPath" `
            -verb:sync `
            -source:contentPath="$publishPath" `
            -dest:package="$packagePath\TodoApp.zip" `
            -verbose
            
        if ($LASTEXITCODE -eq 0 -and (Test-Path "$packagePath\TodoApp.zip")) {
            $packageInfo = Get-Item "$packagePath\TodoApp.zip"
            Write-Host "[SUCCESS] Package created successfully"
            Write-Host "Package size: $([math]::Round($packageInfo.Length / 1MB, 2)) MB"
            $packageCreated = $true
        } else {
            Write-Warning "Package creation failed with exit code: $LASTEXITCODE"
        }
    } catch {
        Write-Warning "Package creation failed: $($_.Exception.Message)"
    }
} else {
    Write-Host "[INFO] MSDeploy not found at expected locations"
    Write-Host "Expected locations:"
    Write-Host "  ${env:ProgramFiles}\IIS\Microsoft Web Deploy V3\msdeploy.exe"
    Write-Host "  ${env:ProgramFiles(x86)}\IIS\Microsoft Web Deploy V3\msdeploy.exe"
}

# Show deployment assets
Write-Host ""
Write-Host "=== DEPLOYMENT ASSETS SUMMARY ==="
if (Test-Path $publishPath) {
    $publishedFiles = Get-ChildItem -Path $publishPath -Recurse -File
    Write-Host "Published files: $($publishedFiles.Count) files"
    Write-Host "Published size: $([math]::Round((Get-ChildItem -Path $publishPath -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB, 2)) MB"
    
    Write-Host ""
    Write-Host "Key files in publish directory:"
    Get-ChildItem -Path $publishPath -File | Where-Object { $_.Name -match '\.(exe|dll|json|config)$' } | Select-Object Name, Length | Format-Table -AutoSize
} else {
    Write-Warning "Published files directory not found: $publishPath"
}

if ($packageCreated) {
    Write-Host "Web Deploy package: CREATED ✓"
} else {
    Write-Host "Web Deploy package: NOT CREATED (will use folder deployment)"
}

# Test deployment (simulate workflow)
Write-Host ""
Write-Host "=== TESTING DEPLOYMENT METHODS ==="

# Method 1: Package deployment
if ($packageCreated -and $isAdmin -and ($Method -eq "auto" -or $Method -eq "package")) {
    Write-Host "Testing package deployment..."
    try {
        # This would normally deploy to IIS, but we'll just test the command
        Write-Host "Command would be:"
        Write-Host "  & '$msdeployPath' -verb:sync -source:package='$packagePath\TodoApp.zip' -dest:iisApp='$siteName',computerName=localhost"
        Write-Host "[INFO] Package deployment test completed (simulation only)"
    } catch {
        Write-Warning "Package deployment test failed: $($_.Exception.Message)"
    }
}

# Method 2: Folder sync
if (Test-Path $publishPath) {
    Write-Host "Testing folder synchronization..."
    try {
        if (Test-Path $msdeployPath) {
            Write-Host "Command would be:"
            Write-Host "  & '$msdeployPath' -verb:sync -source:contentPath='$publishPath' -dest:contentPath='$sitePath',computerName=localhost"
            Write-Host "[INFO] Folder sync test completed (simulation only)"
        } else {
            Write-Host "[INFO] MSDeploy not available for folder sync test"
        }
    } catch {
        Write-Warning "Folder sync test failed: $($_.Exception.Message)"
    }
}

# Method 3: File copy
Write-Host "Testing file copy method..."
if (Test-Path $publishPath) {
    Write-Host "Source files ready for copy: $publishPath"
    Write-Host "Target would be: $sitePath"
    Write-Host "[INFO] File copy test completed (simulation only)"
} else {
    Write-Warning "No source files available for copy test"
}

Write-Host ""
Write-Host "=== TEST SUMMARY ==="
Write-Host "✓ Build process: $(if (!$SkipBuild) { 'TESTED' } else { 'SKIPPED' })"
Write-Host "✓ Package creation: $(if ($packageCreated) { 'SUCCESS' } else { 'FAILED/SKIPPED' })"
Write-Host "✓ Deployment methods: SIMULATED"
Write-Host ""
Write-Host "To run actual deployment:"
Write-Host "1. Ensure IIS is installed and configured"
Write-Host "2. Run as Administrator"
Write-Host "3. Create target directory: $sitePath"
Write-Host "4. Run the GitHub Actions workflow or manual deployment script"
Write-Host ""
Write-Host "=== END LOCAL TEST ===" 