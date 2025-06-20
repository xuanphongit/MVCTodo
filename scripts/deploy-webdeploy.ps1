param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("development", "staging", "production")]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [string]$ServerUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$true)]
    [string]$Password,
    
    [Parameter(Mandatory=$false)]
    [string]$SiteName = "Default Web Site/TodoApp",
    
    [Parameter(Mandatory=$false)]
    [string]$BuildConfiguration = "Release"
)

Write-Host "Starting Web Deploy deployment for $Environment environment..." -ForegroundColor Green

# Set variables
$ProjectPath = "Todo.csproj"
$SetParametersFile = "parameters\setParameters.$Environment.xml"
$PackagePath = "bin\$BuildConfiguration\net8.0\publish"

# Validate setParameters file exists
if (-not (Test-Path $SetParametersFile)) {
    Write-Error "SetParameters file not found: $SetParametersFile"
    exit 1
}

try {
    # Step 1: Clean and build the project
    Write-Host "Building project..." -ForegroundColor Yellow
    dotnet clean $ProjectPath --configuration $BuildConfiguration
    dotnet build $ProjectPath --configuration $BuildConfiguration --no-restore
    
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed"
    }

    # Step 2: Publish the project
    Write-Host "Publishing project..." -ForegroundColor Yellow
    dotnet publish $ProjectPath --configuration $BuildConfiguration --output $PackagePath --no-build
    
    if ($LASTEXITCODE -ne 0) {
        throw "Publish failed"
    }

    # Step 3: Create Web Deploy package
    Write-Host "Creating Web Deploy package..." -ForegroundColor Yellow
    $PackageFile = "TodoApp.$Environment.zip"
    
    # Use MSBuild to create the package with parameters
    dotnet msbuild $ProjectPath `
        /p:Configuration=$BuildConfiguration `
        /p:Platform="Any CPU" `
        /p:WebPublishMethod=Package `
        /p:PackageAsSingleFile=true `
        /p:PackageLocation=$PackageFile `
        /p:IncludeSetParameters=true `
        /p:SetParametersFile=$SetParametersFile
    
    if ($LASTEXITCODE -ne 0) {
        throw "Package creation failed"
    }

    # Step 4: Deploy using Web Deploy
    Write-Host "Deploying to $ServerUrl..." -ForegroundColor Yellow
    
    # Build msdeploy command
    $msdeployPath = "${env:ProgramFiles}\IIS\Microsoft Web Deploy V3\msdeploy.exe"
    
    if (-not (Test-Path $msdeployPath)) {
        $msdeployPath = "${env:ProgramFiles(x86)}\IIS\Microsoft Web Deploy V3\msdeploy.exe"
    }
    
    if (-not (Test-Path $msdeployPath)) {
        throw "MSDeploy.exe not found. Please install Web Deploy 3.6 or later."
    }
    
    $msdeployArgs = @(
        "-source:package='$PackageFile'"
        "-dest:auto,computerName='$ServerUrl',userName='$Username',password='$Password',authtype='basic'"
        "-verb:sync"
        "-enableRule:AppOffline"
        "-setParamFile:'$SetParametersFile'"
        "-allowUntrusted"
        "-verbose"
    )
    
    Write-Host "Executing: $msdeployPath $($msdeployArgs -join ' ')" -ForegroundColor Cyan
    
    & $msdeployPath $msdeployArgs
    
    if ($LASTEXITCODE -ne 0) {
        throw "Web Deploy failed with exit code $LASTEXITCODE"
    }

    Write-Host "Deployment completed successfully!" -ForegroundColor Green
    Write-Host "Application URL: https://$($ServerUrl.Replace(':8172/msdeploy.axd', ''))/$($SiteName.Split('/')[-1])" -ForegroundColor Cyan

} catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    exit 1
} finally {
    # Cleanup
    if (Test-Path $PackageFile) {
        Remove-Item $PackageFile -Force
        Write-Host "Cleaned up package file: $PackageFile" -ForegroundColor Gray
    }
}

Write-Host "Script completed." -ForegroundColor Green 