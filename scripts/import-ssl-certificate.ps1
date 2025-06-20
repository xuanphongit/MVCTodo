param(
    [Parameter(Mandatory=$false)]
    [string]$CertificatePath = ".github\workflows\key\origin.pfx",
    
    [Parameter(Mandatory=$false)]
    [string]$Domain = "phongmx.org",
    
    [Parameter(Mandatory=$false)]
    [string]$SiteName = "Default Web Site",
    
    [Parameter(Mandatory=$false)]
    [string]$ApplicationPath = "TodoApp",
    
    [Parameter(Mandatory=$false)]
    [int]$HttpsPort = 443,
    
    [Parameter(Mandatory=$false)]
    [int]$HttpPort = 80,
    
    [Parameter(Mandatory=$false)]
    [switch]$ForceHTTPS = $true,
    
    [Parameter(Mandatory=$false)]
    [string]$CertificatePassword = ""
)

Write-Host "🔒 Importing SSL certificate for $Domain" -ForegroundColor Green

# Import required modules
try {
    Import-Module WebAdministration -ErrorAction Stop
    Write-Host "✅ IIS WebAdministration module loaded" -ForegroundColor Gray
} catch {
    Write-Error "❌ IIS WebAdministration module not available. Please install IIS management tools."
    exit 1
}

function Import-SSLCertificate {
    param($CertPath, $Password, $Domain)
    
    Write-Host "Importing SSL certificate..." -ForegroundColor Yellow
    
    try {
        # Check if certificate file exists
        if (!(Test-Path $CertPath)) {
            throw "Certificate file not found: $CertPath"
        }
        
        Write-Host "Certificate file found: $CertPath" -ForegroundColor Gray
        
        # Get certificate password if not provided
        if ([string]::IsNullOrEmpty($Password)) {
            $securePassword = Read-Host "Enter certificate password" -AsSecureString
        } else {
            $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
        }
        
        # Import certificate to Local Machine Personal store
        Write-Host "Importing certificate to Local Machine Personal store..." -ForegroundColor Gray
        $cert = Import-PfxCertificate -FilePath $CertPath -CertStoreLocation "cert:\LocalMachine\My" -Password $securePassword -Exportable
        
        Write-Host "✅ Certificate imported successfully!" -ForegroundColor Green
        Write-Host "   Subject: $($cert.Subject)" -ForegroundColor Gray
        Write-Host "   Thumbprint: $($cert.Thumbprint)" -ForegroundColor Gray
        Write-Host "   Expires: $($cert.NotAfter)" -ForegroundColor Gray
        
        # Verify the certificate is for the correct domain
        $dnsNames = $cert.DnsNameList.Unicode
        if ($dnsNames -contains $Domain -or $cert.Subject -like "*$Domain*") {
            Write-Host "✅ Certificate is valid for domain: $Domain" -ForegroundColor Green
        } else {
            Write-Warning "⚠️ Certificate may not be valid for domain: $Domain"
            Write-Host "Certificate DNS names: $($dnsNames -join ', ')" -ForegroundColor Yellow
        }
        
        return $cert
    } catch {
        Write-Error "❌ Certificate import failed: $($_.Exception.Message)"
        return $null
    }
}

function Configure-IISBindings {
    param($SiteName, $Domain, $Certificate, $HttpsPort, $HttpPort, $ApplicationPath)
    
    Write-Host "Configuring IIS bindings..." -ForegroundColor Yellow
    
    try {
        # Check if site exists
        $site = Get-Website -Name $SiteName -ErrorAction SilentlyContinue
        if (!$site) {
            throw "Website '$SiteName' not found in IIS"
        }
        
        Write-Host "Site found: $SiteName" -ForegroundColor Gray
        
        # Remove existing bindings for the domain
        Write-Host "Removing existing bindings for $Domain..." -ForegroundColor Gray
        Get-WebBinding -Name $SiteName | Where-Object { $_.bindingInformation -like "*:*:$Domain" } | Remove-WebBinding
        
        # Add HTTP binding (for redirection)
        Write-Host "Adding HTTP binding for $Domain on port $HttpPort..." -ForegroundColor Gray
        New-WebBinding -Name $SiteName -Protocol http -Port $HttpPort -HostHeader $Domain
        
        # Add HTTPS binding
        Write-Host "Adding HTTPS binding for $Domain on port $HttpsPort..." -ForegroundColor Gray
        New-WebBinding -Name $SiteName -Protocol https -Port $HttpsPort -HostHeader $Domain -SslFlags 1
        
        # Assign certificate to HTTPS binding
        Write-Host "Assigning certificate to HTTPS binding..." -ForegroundColor Gray
        $binding = Get-WebBinding -Name $SiteName -Protocol https -Port $HttpsPort -HostHeader $Domain
        $binding.AddSslCertificate($Certificate.Thumbprint, "my")
        
        Write-Host "✅ IIS bindings configured successfully!" -ForegroundColor Green
        
        # Display binding information
        Write-Host "Current bindings for $SiteName:" -ForegroundColor Cyan
        Get-WebBinding -Name $SiteName | ForEach-Object {
            $portInfo = $_.bindingInformation.Split(':')
            Write-Host "  $($_.protocol)://$($portInfo[2]):$($portInfo[1])" -ForegroundColor Gray
        }
        
        return $true
    } catch {
        Write-Error "❌ IIS binding configuration failed: $($_.Exception.Message)"
        return $false
    }
}

function Configure-HTTPSRedirection {
    param($SiteName, $ApplicationPath)
    
    Write-Host "Configuring HTTPS redirection..." -ForegroundColor Yellow
    
    try {
        # Determine web.config path
        $site = Get-Website -Name $SiteName
        $physicalPath = $site.physicalPath
        if ($physicalPath.StartsWith("%SystemDrive%")) {
            $physicalPath = $physicalPath.Replace("%SystemDrive%", $env:SystemDrive)
        }
        
        if (![string]::IsNullOrEmpty($ApplicationPath)) {
            $webConfigPath = Join-Path $physicalPath "$ApplicationPath\web.config"
        } else {
            $webConfigPath = Join-Path $physicalPath "web.config"
        }
        
        Write-Host "Web.config path: $webConfigPath" -ForegroundColor Gray
        
        if (!(Test-Path $webConfigPath)) {
            Write-Warning "⚠️ web.config not found at: $webConfigPath"
            Write-Host "Creating basic web.config with HTTPS redirection..." -ForegroundColor Gray
            
            $webConfigContent = @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <rewrite>
      <rules>
        <rule name="Redirect to HTTPS" stopProcessing="true">
          <match url=".*" />
          <conditions>
            <add input="{HTTPS}" pattern="off" ignoreCase="true" />
          </conditions>
          <action type="Redirect" url="https://{HTTP_HOST}/{R:0}" redirectType="Permanent" />
        </rule>
      </rules>
    </rewrite>
  </system.webServer>
</configuration>
"@
            $webConfigContent | Out-File -FilePath $webConfigPath -Encoding UTF8
            Write-Host "✅ Basic web.config created with HTTPS redirection" -ForegroundColor Green
            return
        }
        
        # Load existing web.config
        [xml]$webConfig = Get-Content $webConfigPath
        
        # Ensure system.webServer exists
        if (!$webConfig.configuration.'system.webServer') {
            $systemWebServer = $webConfig.CreateElement("system.webServer")
            $webConfig.configuration.AppendChild($systemWebServer)
        }
        
        # Ensure rewrite section exists
        if (!$webConfig.configuration.'system.webServer'.rewrite) {
            $rewrite = $webConfig.CreateElement("rewrite")
            $webConfig.configuration.'system.webServer'.AppendChild($rewrite)
        }
        
        # Ensure rules section exists
        if (!$webConfig.configuration.'system.webServer'.rewrite.rules) {
            $rules = $webConfig.CreateElement("rules")
            $webConfig.configuration.'system.webServer'.rewrite.AppendChild($rules)
        }
        
        # Remove existing HTTPS redirect rule if present
        $existingRule = $webConfig.configuration.'system.webServer'.rewrite.rules.rule | Where-Object { $_.name -eq "Redirect to HTTPS" }
        if ($existingRule) {
            Write-Host "Removing existing HTTPS redirect rule..." -ForegroundColor Gray
            $webConfig.configuration.'system.webServer'.rewrite.rules.RemoveChild($existingRule)
        }
        
        # Add HTTPS redirection rule
        Write-Host "Adding HTTPS redirection rule..." -ForegroundColor Gray
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
        
        # Save web.config
        $webConfig.Save($webConfigPath)
        Write-Host "✅ HTTPS redirection configured in web.config" -ForegroundColor Green
        
    } catch {
        Write-Warning "⚠️ HTTPS redirection configuration failed: $($_.Exception.Message)"
    }
}

function Test-SSLConfiguration {
    param($Domain, $HttpsPort)
    
    Write-Host "Testing SSL configuration..." -ForegroundColor Yellow
    
    try {
        $url = "https://$Domain"
        if ($HttpsPort -ne 443) {
            $url += ":$HttpsPort"
        }
        
        Write-Host "Testing HTTPS connection to: $url" -ForegroundColor Gray
        
        # Test SSL connection
        $request = [System.Net.WebRequest]::Create($url)
        $request.Timeout = 10000
        $response = $request.GetResponse()
        
        if ($response.StatusCode -eq "OK") {
            Write-Host "✅ HTTPS connection successful!" -ForegroundColor Green
            Write-Host "   Status: $($response.StatusCode)" -ForegroundColor Gray
            Write-Host "   Server: $($response.Server)" -ForegroundColor Gray
        }
        
        $response.Close()
        return $true
    } catch {
        Write-Warning "⚠️ HTTPS test failed: $($_.Exception.Message)"
        Write-Host "This may be normal if the site is not yet accessible externally." -ForegroundColor Gray
        return $false
    }
}

# Main execution
try {
    Write-Host "🚀 Starting SSL certificate import and configuration..." -ForegroundColor Cyan
    Write-Host "Domain: $Domain" -ForegroundColor White
    Write-Host "Certificate: $CertificatePath" -ForegroundColor White
    Write-Host "Site: $SiteName" -ForegroundColor White
    Write-Host "Application: $ApplicationPath" -ForegroundColor White
    Write-Host ""
    
    # Step 1: Import certificate
    $certificate = Import-SSLCertificate -CertPath $CertificatePath -Password $CertificatePassword -Domain $Domain
    if (!$certificate) {
        throw "Certificate import failed"
    }
    
    # Step 2: Configure IIS bindings
    $bindingSuccess = Configure-IISBindings -SiteName $SiteName -Domain $Domain -Certificate $certificate -HttpsPort $HttpsPort -HttpPort $HttpPort -ApplicationPath $ApplicationPath
    if (!$bindingSuccess) {
        throw "IIS binding configuration failed"
    }
    
    # Step 3: Configure HTTPS redirection
    if ($ForceHTTPS) {
        Configure-HTTPSRedirection -SiteName $SiteName -ApplicationPath $ApplicationPath
    }
    
    # Step 4: Test SSL configuration
    Write-Host ""
    Test-SSLConfiguration -Domain $Domain -HttpsPort $HttpsPort
    
    Write-Host ""
    Write-Host "🎉 SSL Certificate Configuration Complete!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "Domain: $Domain" -ForegroundColor White
    Write-Host "Certificate Thumbprint: $($certificate.Thumbprint)" -ForegroundColor White
    Write-Host "HTTPS Port: $HttpsPort" -ForegroundColor White
    Write-Host "HTTP Port: $HttpPort" -ForegroundColor White
    Write-Host "HTTPS Redirection: $ForceHTTPS" -ForegroundColor White
    Write-Host ""
    Write-Host "🌐 Your site should now be accessible at:" -ForegroundColor Cyan
    Write-Host "   https://$Domain/$ApplicationPath" -ForegroundColor Green
    Write-Host ""
    
    # Additional information
    Write-Host "📝 Next steps:" -ForegroundColor Yellow
    Write-Host "1. Update DNS to point $Domain to this server" -ForegroundColor Gray
    Write-Host "2. Update firewall to allow ports $HttpPort and $HttpsPort" -ForegroundColor Gray
    Write-Host "3. Test the application from external network" -ForegroundColor Gray
    Write-Host "4. Update Web Deploy scripts to use HTTPS URLs" -ForegroundColor Gray
    
} catch {
    Write-Error "❌ SSL certificate configuration failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "✅ SSL certificate import and configuration completed successfully!" -ForegroundColor Green 