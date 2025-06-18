# Script to create Azure credentials for GitHub Actions
Write-Host "=== CREATING AZURE CREDENTIALS FOR GITHUB ACTIONS ===" -ForegroundColor Yellow

# Login to Azure
Connect-AzAccount

# Get subscription ID
$subscriptionId = (Get-AzContext).Subscription.Id
Write-Host "Using Subscription ID: $subscriptionId" -ForegroundColor Cyan

# Create Service Principal
$spName = "github-actions-deployer"
Write-Host "Creating Service Principal: $spName" -ForegroundColor Cyan

$sp = New-AzADServicePrincipal -DisplayName $spName -Role "Key Vault Secrets User" -Scope "/subscriptions/$subscriptionId"

# Create credentials object
$credentials = @{
    clientId = $sp.AppId
    clientSecret = $sp.PasswordCredentials.SecretText
    subscriptionId = $subscriptionId
    tenantId = (Get-AzContext).Tenant.Id
}

# Convert to JSON
$jsonCredentials = $credentials | ConvertTo-Json

Write-Host "`n=== AZURE CREDENTIALS ===" -ForegroundColor Green
Write-Host "Add these credentials to your GitHub repository secrets as 'AZURE_CREDENTIALS':" -ForegroundColor Yellow
Write-Host $jsonCredentials -ForegroundColor White

Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Cyan
Write-Host "1. Go to your GitHub repository" -ForegroundColor White
Write-Host "2. Go to Settings > Secrets and variables > Actions" -ForegroundColor White
Write-Host "3. Click 'New repository secret'" -ForegroundColor White
Write-Host "4. Name: AZURE_CREDENTIALS" -ForegroundColor White
Write-Host "5. Value: (paste the JSON above)" -ForegroundColor White
Write-Host "6. Click 'Add secret'" -ForegroundColor White

Write-Host "`n=== IMPORTANT ===" -ForegroundColor Red
Write-Host "Make sure to save these credentials securely. They provide access to your Azure subscription." -ForegroundColor Red 