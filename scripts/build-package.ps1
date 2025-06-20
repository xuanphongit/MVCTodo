param(
    [Parameter(Mandatory=$false)]
    [string]$Configuration = "Release",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "artifacts",
    
    [Parameter(Mandatory=$false)]
    [string]$Version = "1.0.0"
)

Write-Host "Building and packaging TodoApp..." -ForegroundColor Green

# Set variables
$ProjectPath = "Todo.csproj"
$PackageName = "TodoApp.$Version"
$PackageFile = "$OutputPath\$PackageName.zip"

try {
    # Step 1: Clean previous builds
    Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
    if (Test-Path $OutputPath) {
        Remove-Item $OutputPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    
    dotnet clean $ProjectPath --configuration $Configuration

    # Step 2: Restore packages
    Write-Host "Restoring packages..." -ForegroundColor Yellow
    dotnet restore $ProjectPath

    # Step 3: Build project
    Write-Host "Building project..." -ForegroundColor Yellow
    dotnet build $ProjectPath --configuration $Configuration --no-restore
    
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed"
    }

    # Step 4: Create Web Deploy package
    Write-Host "Creating Web Deploy package..." -ForegroundColor Yellow
    
    dotnet msbuild $ProjectPath `
        /p:Configuration=$Configuration `
        /p:Platform="Any CPU" `
        /p:WebPublishMethod=Package `
        /p:PackageAsSingleFile=true `
        /p:PackageLocation=$PackageFile `
        /p:IncludeSetParameters=true `
        /p:ParametersXmlFile=Parameters.xml `
        /t:WebPublish
    
    if ($LASTEXITCODE -ne 0) {
        throw "Package creation failed"
    }

    # Step 5: Copy setParameters files to artifacts
    Write-Host "Copying setParameters files..." -ForegroundColor Yellow
    Copy-Item "parameters\*.xml" $OutputPath

    # Step 6: Generate build info
    $buildInfo = @{
        PackageName = $PackageName
        Version = $Version
        BuildDate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Configuration = $Configuration
        GitCommit = if (Get-Command git -ErrorAction SilentlyContinue) { git rev-parse HEAD } else { "N/A" }
    }
    
    $buildInfo | ConvertTo-Json | Out-File "$OutputPath\build-info.json"

    Write-Host "Build completed successfully!" -ForegroundColor Green
    Write-Host "Package created: $PackageFile" -ForegroundColor Cyan
    Write-Host "Artifacts directory: $OutputPath" -ForegroundColor Cyan
    
    # List artifacts
    Write-Host "`nArtifacts created:" -ForegroundColor Yellow
    Get-ChildItem $OutputPath | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Gray
    }

} catch {
    Write-Error "Build failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "`nBuild and packaging completed successfully!" -ForegroundColor Green 