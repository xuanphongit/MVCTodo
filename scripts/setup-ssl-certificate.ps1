param(
    [Parameter(Mandatory=$true)]
    [string]$Domain = "ppphongmx.org",
    
    [Parameter(Mandatory=$true)]
    [string]$SiteName = "Default Web Site",
    
    [Parameter(Mandatory=$false)]
    [string]$CertificateMethod = "LetsEncrypt", # LetsEncrypt, SelfSigned, or Import
    
    [Parameter(Mandatory=$false)]
    [string]$CertificatePath = "",
    
    [Parameter(Mandatory=$false)]
    [string]$CertificatePassword = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Email = "admin@ppphongmx.org",
    
    [Parameter(Mandatory=$false)]
    [int]$HttpsPort = 443,
    
    [Parameter(Mandatory=$false)]
    [switch]$ForceHTTPS = $true
)

Write-Host "🔒 Setting up SSL certificate for $Domain" -ForegroundColor Green

# Import required modules
Import-Module WebAdministration -ErrorAction SilentlyContinue

function Install-LetsEncryptCertificate {
    param($Domain, $Email, $SiteName)
    
    Write-Host "Installing Let's Encrypt certificate..." -ForegroundColor Yellow
    
    try {
        # Check if Certbot is installed
        $certbot = Get-Command certbot -ErrorAction SilentlyContinue
        if (-not $certbot) {
            Write-Host "Installing Certbot..." -ForegroundColor Yellow
            
            # Install Chocolatey if not present
            if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
                Write-Host "Installing Chocolatey..." -ForegroundColor Gray
                Set-ExecutionPolicy Bypass -Scope Process -Force
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
                refreshenv
            }
            
            # Install Certbot
            choco install certbot -y
            refreshenv
        }
        
        Write-Host "Requesting certificate from Let's Encrypt..." -ForegroundColor Yellow
        
        # Stop website temporarily for domain validation
        Write-Host "Stopping IIS site temporarily for validation..." -ForegroundColor Gray
        Stop-Website -Name $SiteName -ErrorAction SilentlyContinue
        
        # Request certificate
        $certbotArgs = @(
            "certonly"
            "--standalone"
            "--non-interactive"
            "--agree-tos"
            "--email", $Email
            "-d", $Domain
        )
        
        & certbot @certbotArgs
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Let's Encrypt certificate obtained successfully!" -ForegroundColor Green
            
            # Certificate path for Let's Encrypt on Windows
            $certPath = "C:\Certbot\live\$Domain\fullchain.pem"
            $keyPath = "C:\Certbot\live\$Domain\privkey.pem"
            
            # Convert to PFX format for IIS
            $pfxPath = "C:\Certbot\live\$Domain\$Domain.pfx"
            $pfxPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 12 | % {[char]$_})
            
            # Use OpenSSL to convert (requires OpenSSL to be installed)
            if (Get-Command openssl -ErrorAction SilentlyContinue) {
                openssl pkcs12 -export -out $pfxPath -inkey $keyPath -in $certPath -password pass:$pfxPassword
                return @{
                    Path = $pfxPath
                    Password = $pfxPassword
                    Thumbprint = $null
                }
            } else {
                Write-Warning "OpenSSL not found. Please install OpenSSL or manually convert the certificate."
                return $null
            }
        } else {
            throw "Certbot failed with exit code $LASTEXITCODE"
        }
    } catch {
        Write-Error "Let's Encrypt certificate installation failed: $($_.Exception.Message)"
        return $null
    } finally {
        # Restart website
        Start-Website -Name $SiteName -ErrorAction SilentlyContinue
    }
}

function New-SelfSignedSSLCertificate {
    param($Domain)
    
    Write-Host "Creating self-signed certificate..." -ForegroundColor Yellow
    
    try {
        $cert = New-SelfSignedCertificate `
            -DnsName $Domain `
            -CertStoreLocation "cert:\LocalMachine\My" `
            -FriendlyName "SSL Certificate for $Domain" `
            -NotAfter (Get-Date).AddYears(2) `
            -KeyAlgorithm RSA `
            -KeyLength 2048 `
            -HashAlgorithm SHA256 `
            -KeyUsage DigitalSignature, KeyEncipherment `
            -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider"
        
        Write-Host "✅ Self-signed certificate created successfully!" -ForegroundColor Green
        Write-Host "Thumbprint: $($cert.Thumbprint)" -ForegroundColor Gray
        
        return @{
            Path = $null
            Password = $null
            Thumbprint = $cert.Thumbprint
        }
    } catch {
        Write-Error "Self-signed certificate creation failed: $($_.Exception.Message)"
        return $null
    }
}

function Import-ExistingCertificate {
    param($CertificatePath, $CertificatePassword)
    
    Write-Host "Importing existing certificate..." -ForegroundColor Yellow
    
    try {
        if (!(Test-Path $CertificatePath)) {
            throw "Certificate file not found: $CertificatePath"
        }
        
        $securePassword = ConvertTo-SecureString $CertificatePassword -AsPlainText -Force
        $cert = Import-PfxCertificate -FilePath $CertificatePath -CertStoreLocation "cert:\LocalMachine\My" -Password $securePassword
        
        Write-Host "✅ Certificate imported successfully!" -ForegroundColor Green
        Write-Host "Thumbprint: $($cert.Thumbprint)" -ForegroundColor Gray
        
        return @{
            Path = $CertificatePath
            Password = $CertificatePassword
            Thumbprint = $cert.Thumbprint
        }
    } catch {
        Write-Error "Certificate import failed: $($_.Exception.Message)"
        return $null
    }
}

function Configure-IISSSLBinding {
    param($SiteName, $Domain, $Thumbprint, $Port)
    
    Write-Host "Configuring IIS SSL binding..." -ForegroundColor Yellow
    
    try {
        # Remove existing HTTPS binding if it exists
        $existingBinding = Get-WebBinding -Name $SiteName -Protocol https -ErrorAction SilentlyContinue
        if ($existingBinding) {
            Write-Host "Removing existing HTTPS binding..." -ForegroundColor Gray
            Remove-WebBinding -Name $SiteName -Protocol https -Port $Port -ErrorAction SilentlyContinue
        }
        
        # Add new HTTPS binding
        Write-Host "Adding HTTPS binding for $Domain on port $Port..." -ForegroundColor Gray
        New-WebBinding -Name $SiteName -Protocol https -Port $Port -HostHeader $Domain -SslFlags 1
        
        # Get the binding and assign certificate
        $binding = Get-WebBinding -Name $SiteName -Protocol https
        $binding.AddSslCertificate($Thumbprint, "my")
        
        Write-Host "✅ SSL binding configured successfully!" -ForegroundColor Green
        
        # Test the binding
        $testBinding = Get-WebBinding -Name $SiteName -Protocol https
        if ($testBinding) {
            Write-Host "HTTPS binding verified:" -ForegroundColor Green
            Write-Host "  Protocol: $($testBinding.protocol)" -ForegroundColor Gray
            Write-Host "  Port: $($testBinding.bindingInformation.split(':')[1])" -ForegroundColor Gray
            Write-Host "  Host: $($testBinding.bindingInformation.split(':')[2])" -ForegroundColor Gray
        }
        
        return $true
    } catch {
        Write-Error "IIS SSL binding configuration failed: $($_.Exception.Message)"
        return $false
    }
}

function Enable-HTTPSRedirection {
    param($SiteName)
    
    Write-Host "Configuring HTTPS redirection..." -ForegroundColor Yellow
    
    try {
        # Install URL Rewrite module if not present
        $urlRewrite = Get-WindowsFeature -Name IIS-HttpRedirect -ErrorAction SilentlyContinue
        if ($urlRewrite -and $urlRewrite.InstallState -ne "Installed") {
            Write-Host "Installing IIS URL Rewrite..." -ForegroundColor Gray
            Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpRedirect -All
        }
        
        # Configure URL rewrite rule for HTTPS redirection
        $webConfigPath = "C:\inetpub\wwwroot\web.config"
        
        if (Test-Path $webConfigPath) {
            Write-Host "Adding HTTPS redirection rule to web.config..." -ForegroundColor Gray
            
            [xml]$webConfig = Get-Content $webConfigPath
            
            # Add URL rewrite section if it doesn't exist
            if (-not $webConfig.configuration.'system.webServer'.rewrite) {
                $rewrite = $webConfig.CreateElement("rewrite")
                $rules = $webConfig.CreateElement("rules")
                $rewrite.AppendChild($rules)
                $webConfig.configuration.'system.webServer'.AppendChild($rewrite)
            }
            
            # Add HTTPS redirection rule
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
            
            Write-Host "✅ HTTPS redirection configured!" -ForegroundColor Green
        }
    } catch {
        Write-Warning "HTTPS redirection configuration failed: $($_.Exception.Message)"
    }
}

# Main execution
try {
    Write-Host "Starting SSL certificate setup for $Domain..." -ForegroundColor Cyan
    
    # Validate prerequisites
    if (!(Get-Module WebAdministration -ListAvailable)) {
        throw "IIS WebAdministration module not available. Please install IIS management tools."
    }
    
    if (!(Get-Website -Name $SiteName -ErrorAction SilentlyContinue)) {
        throw "Website '$SiteName' not found in IIS."
    }
    
    # Get or create certificate based on method
    $certInfo = switch ($CertificateMethod.ToLower()) {
        "letsencrypt" { 
            Install-LetsEncryptCertificate -Domain $Domain -Email $Email -SiteName $SiteName
        }
        "selfsigned" { 
            New-SelfSignedSSLCertificate -Domain $Domain
        }
        "import" { 
            if ([string]::IsNullOrEmpty($CertificatePath)) {
                throw "Certificate path is required for import method"
            }
            Import-ExistingCertificate -CertificatePath $CertificatePath -CertificatePassword $CertificatePassword
        }
        default { 
            throw "Invalid certificate method: $CertificateMethod"
        }
    }
    
    if (-not $certInfo) {
        throw "Certificate setup failed"
    }
    
    # Configure IIS SSL binding
    $bindingSuccess = Configure-IISSSLBinding -SiteName $SiteName -Domain $Domain -Thumbprint $certInfo.Thumbprint -Port $HttpsPort
    
    if (-not $bindingSuccess) {
        throw "SSL binding configuration failed"
    }
    
    # Enable HTTPS redirection if requested
    if ($ForceHTTPS) {
        Enable-HTTPSRedirection -SiteName $SiteName
    }
    
    Write-Host ""
    Write-Host "🎉 SSL Certificate Setup Complete!" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Green
    Write-Host "Domain: $Domain" -ForegroundColor White
    Write-Host "Method: $CertificateMethod" -ForegroundColor White
    Write-Host "Port: $HttpsPort" -ForegroundColor White
    Write-Host "Certificate Thumbprint: $($certInfo.Thumbprint)" -ForegroundColor White
    Write-Host "HTTPS Redirection: $ForceHTTPS" -ForegroundColor White
    Write-Host ""
    Write-Host "🌐 Your site should now be accessible at: https://$Domain" -ForegroundColor Cyan
    Write-Host ""
    
    if ($CertificateMethod -eq "LetsEncrypt") {
        Write-Host "📝 Let's Encrypt certificates expire every 90 days." -ForegroundColor Yellow
        Write-Host "   Set up automatic renewal using Windows Task Scheduler." -ForegroundColor Yellow
    }
    
} catch {
    Write-Error "SSL setup failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "SSL certificate setup completed successfully!" -ForegroundColor Green 