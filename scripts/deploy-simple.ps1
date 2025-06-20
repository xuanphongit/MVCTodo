param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    [Parameter(Mandatory=$true)]
    [string]$ServerUrl,
    [Parameter(Mandatory=$true)]
    [string]$Username,
    [Parameter(Mandatory=$true)]
    [string]$Password
)

Write-Host "Quick Web Deploy for $Environment environment" -ForegroundColor Green

# Build and publish
dotnet publish --configuration Release

# Deploy using specific setParameters file
$setParamsFile = "parameters\setParameters.$Environment.xml"

# Use msdeploy directly
msdeploy.exe `
    -source:iisApp="bin\Release\net8.0\publish" `
    -dest:iisApp="Default Web Site/TodoApp",computerName="$ServerUrl",userName="$Username",password="$Password" `
    -verb:sync `
    -setParamFile:"$setParamsFile" `
    -allowUntrusted

Write-Host "Deployment completed!" -ForegroundColor Green 