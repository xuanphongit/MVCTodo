# SSL Certificate Setup Guide for phongmx.org

This guide explains how to configure SSL certificate for your TodoApp using the existing certificate file `origin.pfx` for the domain `phongmx.org`.

## Overview

You have an existing SSL certificate for `phongmx.org` located at `.github\workflows\key\origin.pfx`. This guide will help you:

1. Import the certificate into IIS
2. Configure HTTPS bindings
3. Update Web Deploy for SSL support
4. Test the SSL configuration

## Prerequisites

### On the Target VM:
- Windows Server with IIS installed
- Web Deploy 3.6 or later
- PowerShell 5.1 or later
- Administrator access

### Certificate Information:
- **Certificate File**: `.github\workflows\key\origin.pfx`
- **Domain**: `phongmx.org`
- **Subdomains**: Support for `staging.phongmx.org`, `dev.phongmx.org` (if included)

## Step-by-Step Setup

### 1. 🚀 Quick SSL Import and Configuration

Use the automated script to import and configure SSL:

```powershell
# Run on the target VM
.\scripts\import-ssl-certificate.ps1 -CertificatePath ".github\workflows\key\origin.pfx" -Domain "phongmx.org"
```

This script will:
- Import the certificate into the Local Machine Personal store
- Configure IIS HTTPS bindings for phongmx.org
- Set up HTTPS redirection in web.config
- Test the SSL configuration

### 2. 📋 Manual SSL Configuration (Alternative)

If you prefer manual configuration:

#### Step 2.1: Copy Certificate to VM
```powershell
# Copy certificate to VM (adjust path as needed)
Copy-Item ".github\workflows\key\origin.pfx" "C:\SSL\origin.pfx"
```

#### Step 2.2: Import Certificate
```powershell
# Import certificate to Local Machine store
$password = Read-Host "Enter certificate password" -AsSecureString
$cert = Import-PfxCertificate -FilePath "C:\SSL\origin.pfx" -CertStoreLocation "cert:\LocalMachine\My" -Password $password
Write-Host "Certificate imported with thumbprint: $($cert.Thumbprint)"
```

#### Step 2.3: Configure IIS Bindings
```powershell
# Import IIS module
Import-Module WebAdministration

# Remove existing HTTPS binding (if any)
Remove-WebBinding -Name "Default Web Site" -Protocol https -Port 443 -HostHeader "phongmx.org" -ErrorAction SilentlyContinue

# Add HTTP binding for redirection
New-WebBinding -Name "Default Web Site" -Protocol http -Port 80 -HostHeader "phongmx.org"

# Add HTTPS binding
New-WebBinding -Name "Default Web Site" -Protocol https -Port 443 -HostHeader "phongmx.org" -SslFlags 1

# Assign certificate to HTTPS binding
$binding = Get-WebBinding -Name "Default Web Site" -Protocol https -Port 443 -HostHeader "phongmx.org"
$binding.AddSslCertificate($cert.Thumbprint, "my")
```

### 3. 🔄 Update Web Deploy Configuration

The project has been updated to support SSL deployment with environment-specific domains:

| Environment | Domain | SSL Enabled |
|-------------|---------|-------------|
| Development | `dev.phongmx.org` | Optional |
| Staging | `staging.phongmx.org` | Yes |
| Production | `phongmx.org` | Yes |

### 4. 🚀 Deploy with SSL Support

#### Option A: Use SSL-Enabled Deployment Script
```powershell
.\scripts\deploy-with-ssl.ps1 `
  -PackageFile "artifacts\TodoApp.123.zip" `
  -Environment production `
  -ServerUrl "https://your-vm:8172/msdeploy.axd" `
  -Username "Administrator" `
  -Password "your-password" `
  -CertificatePath ".github\workflows\key\origin.pfx" `
  -CertificatePassword "cert-password"
```

#### Option B: Use Regular Deployment (SSL already configured)
```powershell
.\scripts\deploy-package.ps1 `
  -PackageFile "artifacts\TodoApp.123.zip" `
  -Environment production `
  -ServerUrl "https://your-vm:8172/msdeploy.axd" `
  -Username "Administrator" `
  -Password "your-password"
```

## Configuration Details

### Updated appsettings.json Template
The application configuration now includes SSL-aware settings:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "{{LOGLEVEL_PLACEHOLDER}}",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Authentication": {
    "DefaultCredentials": {
      "Username": "{{USERNAME_PLACEHOLDER}}",
      "Password": "{{PASSWORD_PLACEHOLDER}}"
    }
  },
  "Application": {
    "Domain": "{{DOMAIN_PLACEHOLDER}}",
    "UseSSL": "{{SSL_PLACEHOLDER}}",
    "BaseUrl": "https://{{DOMAIN_PLACEHOLDER}}"
  }
}
```

### Environment-Specific Parameters

**Production (`setParameters.production.xml`):**
```xml
<setParameter name="Application-Domain" value="phongmx.org" />
<setParameter name="Application-UseSSL" value="true" />
<setParameter name="HTTPS-Binding-Domain" value="phongmx.org" />
```

**Staging (`setParameters.staging.xml`):**
```xml
<setParameter name="Application-Domain" value="staging.phongmx.org" />
<setParameter name="Application-UseSSL" value="true" />
<setParameter name="HTTPS-Binding-Domain" value="staging.phongmx.org" />
```

**Development (`setParameters.development.xml`):**
```xml
<setParameter name="Application-Domain" value="dev.phongmx.org" />
<setParameter name="Application-UseSSL" value="false" />
<setParameter name="HTTPS-Binding-Domain" value="dev.phongmx.org" />
```

## DNS Configuration

Ensure your DNS is configured correctly:

```
# DNS Records for phongmx.org
phongmx.org.            A      YOUR_VM_IP
staging.phongmx.org.    A      YOUR_VM_IP
dev.phongmx.org.        A      YOUR_VM_IP (optional)
```

## Firewall Configuration

Open required ports on your VM:

```powershell
# Allow HTTP traffic
New-NetFirewallRule -DisplayName "HTTP Inbound" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow

# Allow HTTPS traffic
New-NetFirewallRule -DisplayName "HTTPS Inbound" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow

# Allow Web Deploy (if not already configured)
New-NetFirewallRule -DisplayName "Web Deploy" -Direction Inbound -Protocol TCP -LocalPort 8172 -Action Allow
```

## Testing SSL Configuration

### 1. Test Certificate Installation
```powershell
# Check if certificate is installed
Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -like "*phongmx.org*" }

# Check IIS bindings
Get-WebBinding -Name "Default Web Site"
```

### 2. Test HTTPS Connectivity
```powershell
# Test from PowerShell
Invoke-WebRequest -Uri "https://phongmx.org/TodoApp" -UseBasicParsing

# Test HTTP to HTTPS redirection
Invoke-WebRequest -Uri "http://phongmx.org/TodoApp" -UseBasicParsing -MaximumRedirection 0
```

### 3. Online SSL Tests
- **SSL Labs**: https://www.ssllabs.com/ssltest/
- **SSL Checker**: https://www.sslshopper.com/ssl-checker.html

## Troubleshooting

### Common Issues

#### 1. Certificate Import Fails
**Error**: "Cannot find the requested object"
**Solution**: 
```powershell
# Ensure certificate file exists
Test-Path ".github\workflows\key\origin.pfx"

# Verify certificate file is not corrupted
certutil -dump ".github\workflows\key\origin.pfx"
```

#### 2. SSL Binding Fails
**Error**: "A specified logon session does not exist"
**Solution**:
```powershell
# Run PowerShell as Administrator
# Re-import certificate with -Exportable flag
$cert = Import-PfxCertificate -FilePath "C:\SSL\origin.pfx" -CertStoreLocation "cert:\LocalMachine\My" -Password $password -Exportable
```

#### 3. HTTPS Not Working
**Checklist**:
- [ ] Certificate is imported to correct store (LocalMachine\My)
- [ ] IIS binding exists for domain on port 443
- [ ] Certificate is assigned to binding
- [ ] Firewall allows port 443
- [ ] DNS points to correct IP

#### 4. Mixed Content Warnings
**Solution**: Update application URLs to use HTTPS:
```csharp
// In Startup.cs or Program.cs
app.UseHttpsRedirection();
app.UseHsts(); // For production
```

### Validation Commands

```powershell
# Check certificate details
$cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -like "*phongmx.org*" }
$cert | Select-Object Subject, Thumbprint, NotAfter

# Check IIS binding
Get-WebBinding -Name "Default Web Site" | Where-Object { $_.protocol -eq "https" }

# Test SSL from command line
openssl s_client -connect phongmx.org:443 -servername phongmx.org

# Check if certificate is valid for domain
certutil -verify -urlfetch "C:\SSL\origin.pfx"
```

## GitHub Actions Integration

The workflows have been updated to support SSL deployment. Configure these additional secrets:

```
CERT_PASSWORD=your-certificate-password
```

The deployment workflows will automatically:
1. Use HTTPS URLs for the application
2. Configure environment-specific domains
3. Enable HTTPS redirection
4. Validate SSL connectivity

## Security Best Practices

### 1. Certificate Security
- Store certificate password in GitHub Secrets
- Use least-privilege access for deployment accounts
- Regularly monitor certificate expiration

### 2. HTTPS Configuration
- Enable HSTS headers
- Use secure cipher suites
- Disable weak SSL/TLS versions

### 3. Application Security
```csharp
// In Program.cs for production
if (app.Environment.IsProduction())
{
    app.UseHsts();
    app.UseHttpsRedirection();
}
```

## Certificate Renewal

When your certificate expires:

1. **Get new certificate** with same format (.pfx)
2. **Update the file** at `.github\workflows\key\origin.pfx`
3. **Re-run SSL import script** on all environments
4. **Test all environments** after renewal

## Support

For issues with SSL configuration:
1. Check Windows Event Logs (System, Application, Security)
2. Review IIS logs in `C:\inetpub\logs\LogFiles`
3. Use SSL testing tools for validation
4. Verify DNS and firewall configuration

This SSL setup provides production-ready HTTPS configuration for your TodoApp with proper certificate management and deployment automation. 