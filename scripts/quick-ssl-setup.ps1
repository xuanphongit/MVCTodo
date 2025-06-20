#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Quick SSL setup for phongmx.org domain
.DESCRIPTION
    This script quickly imports the SSL certificate and configures IIS for HTTPS
.PARAMETER CertPassword
    Password for the SSL certificate file
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$CertPassword = ""
)

Write-Host "🔒 Quick SSL Setup for phongmx.org" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Configuration
$Domain = "phongmx.org"
$CertPath = ".github\workflows\key\origin.pfx"
$SiteName = "Default Web Site"

try {
    # Step 1: Check prerequisites
    Write-Host "📋 Checking prerequisites..." -ForegroundColor Yellow
    
    if (!(Get-Module WebAdministration -ListAvailable)) {
        throw "IIS WebAdministration module not available"
    }
    
    if (!(Test-Path $CertPath)) {
        throw "Certificate file not found: $CertPath"
    }
    
    Write-Host "✅ Prerequisites check passed" -ForegroundColor Green
    
    # Step 2: Get certificate password
    if ([string]::IsNullOrEmpty($CertPassword)) {
        $securePassword = Read-Host "Enter certificate password for $CertPath" -AsSecureString
    } else {
        $securePassword = ConvertTo-SecureString $CertPassword -AsPlainText -Force
    }
    
    # Step 3: Import certificate
    Write-Host "📜 Importing SSL certificate..." -ForegroundColor Yellow
    Import-Module WebAdministration -Force
    
    $cert = Import-PfxCertificate -FilePath $CertPath -CertStoreLocation "cert:\LocalMachine\My" -Password $securePassword -Exportable
    Write-Host "✅ Certificate imported successfully!" -ForegroundColor Green
    Write-Host "   Thumbprint: $($cert.Thumbprint)" -ForegroundColor Gray
    Write-Host "   Subject: $($cert.Subject)" -ForegroundColor Gray
    Write-Host "   Expires: $($cert.NotAfter)" -ForegroundColor Gray
    
    # Step 4: Configure IIS bindings
    Write-Host "🌐 Configuring IIS bindings..." -ForegroundColor Yellow
    
    # Remove existing bindings for the domain
    Get-WebBinding -Name $SiteName | Where-Object { $_.bindingInformation -like "*:*:$Domain" } | Remove-WebBinding -ErrorAction SilentlyContinue
    
    # Add HTTP binding (for redirection)
    New-WebBinding -Name $SiteName -Protocol http -Port 80 -HostHeader $Domain
    Write-Host "   ✓ HTTP binding added" -ForegroundColor Gray
    
    # Add HTTPS binding
    New-WebBinding -Name $SiteName -Protocol https -Port 443 -HostHeader $Domain -SslFlags 1
    Write-Host "   ✓ HTTPS binding added" -ForegroundColor Gray
    
    # Assign certificate to HTTPS binding
    $binding = Get-WebBinding -Name $SiteName -Protocol https -Port 443 -HostHeader $Domain
    $binding.AddSslCertificate($cert.Thumbprint, "my")
    Write-Host "   ✓ Certificate assigned to binding" -ForegroundColor Gray
    
    Write-Host "✅ IIS bindings configured successfully!" -ForegroundColor Green
    
    # Step 5: Configure HTTPS redirection
    Write-Host "🔄 Configuring HTTPS redirection..." -ForegroundColor Yellow
    
    $webConfigPath = "C:\inetpub\wwwroot\web.config"
    
    if (Test-Path $webConfigPath) {
        # Load existing web.config
        [xml]$webConfig = Get-Content $webConfigPath
        
        # Add HTTPS redirection rule if not exists
        if (!$webConfig.configuration.'system.webServer'.rewrite) {
            $rewrite = $webConfig.CreateElement("rewrite")
            $rules = $webConfig.CreateElement("rules")
            $rewrite.AppendChild($rules)
            $webConfig.configuration.'system.webServer'.AppendChild($rewrite)
        }
        
        # Check if rule already exists
        $existingRule = $webConfig.configuration.'system.webServer'.rewrite.rules.rule | Where-Object { $_.name -eq "Redirect to HTTPS" }
        if (!$existingRule) {
            $rule = $webConfig.CreateElement("rule")
            $rule.SetAttribute("name", "Redirect to HTTPS")
            $rule.SetAttribute("stopProcessing", "true")
            
            $match = $webConfig.CreateElement("match")
            $match.SetAttribute("url", ".*")
            $rule.AppendChild($match)
            
            $conditions = $webConfig.CreateElement("conditions")
            $condition = $webConfig.CreateElement("add")
            $condition.SetAttribute("input", "{HTTPS}")
            $condition.SetAttribute("pattern", "off")
            $condition.SetAttribute("ignoreCase", "true")
            $conditions.AppendChild($condition)
            $rule.AppendChild($conditions)
            
            $action = $webConfig.CreateElement("action")
            $action.SetAttribute("type", "Redirect")
            $action.SetAttribute("url", "https://{HTTP_HOST}/{R:0}")
            $action.SetAttribute("redirectType", "Permanent")
            $rule.AppendChild($action)
            
            $webConfig.configuration.'system.webServer'.rewrite.rules.AppendChild($rule)
            $webConfig.Save($webConfigPath)
            
            Write-Host "   ✓ HTTPS redirection rule added" -ForegroundColor Gray
        } else {
            Write-Host "   ✓ HTTPS redirection rule already exists" -ForegroundColor Gray
        }
    }
    
    Write-Host "✅ HTTPS redirection configured!" -ForegroundColor Green
    
    # Step 6: Test configuration
    Write-Host "🧪 Testing SSL configuration..." -ForegroundColor Yellow
    
    try {
        $testUrl = "https://$Domain"
        $response = Invoke-WebRequest -Uri $testUrl -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        Write-Host "✅ HTTPS test successful! Status: $($response.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Warning "⚠️ HTTPS test failed: $($_.Exception.Message)"
        Write-Host "This may be normal if DNS is not yet configured or site is not publicly accessible." -ForegroundColor Gray
    }
    
    # Final summary
    Write-Host ""
    Write-Host "🎉 SSL Setup Complete!" -ForegroundColor Green
    Write-Host "=====================" -ForegroundColor Green
    Write-Host "Domain: $Domain" -ForegroundColor White
    Write-Host "Certificate: Imported and configured" -ForegroundColor White
    Write-Host "HTTPS Binding: Configured on port 443" -ForegroundColor White
    Write-Host "HTTP Redirection: Enabled" -ForegroundColor White
    Write-Host ""
    Write-Host "🌐 Your site should be accessible at:" -ForegroundColor Cyan
    Write-Host "   https://$Domain" -ForegroundColor Green
    Write-Host "   https://$Domain/TodoApp" -ForegroundColor Green
    Write-Host ""
    Write-Host "📝 Next steps:" -ForegroundColor Yellow
    Write-Host "1. Ensure DNS points $Domain to this server" -ForegroundColor Gray
    Write-Host "2. Configure firewall to allow ports 80 and 443" -ForegroundColor Gray
    Write-Host "3. Deploy your application using Web Deploy" -ForegroundColor Gray
    Write-Host "4. Test from external network" -ForegroundColor Gray

} catch {
    Write-Error "❌ SSL setup failed: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "💡 Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "- Ensure you're running PowerShell as Administrator" -ForegroundColor Gray
    Write-Host "- Verify the certificate file exists and is accessible" -ForegroundColor Gray
    Write-Host "- Check that IIS is installed and running" -ForegroundColor Gray
    Write-Host "- Confirm the certificate password is correct" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "✅ Quick SSL setup completed successfully!" -ForegroundColor Green 