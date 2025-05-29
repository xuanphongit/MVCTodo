# Security Scanning Workflow

This repository includes a comprehensive security scanning workflow using GitHub Actions with a Windows runner that performs OWASP dependency checking and GitLeaks secret scanning.

## 🔧 Workflow Features

### GitLeaks Secret Scanning
- **Purpose**: Detects secrets, passwords, API keys, and sensitive information in your repository
- **Scope**: Scans the entire repository history
- **Action**: Automatically runs on every push and pull request

### OWASP Dependency Check
- **Purpose**: Identifies known vulnerabilities in project dependencies
- **Technology**: Uses OWASP Dependency Check v10.0.4
- **Threshold**: Fails on vulnerabilities with CVSS score ≥ 7.0 (high severity)
- **Caching**: Implements intelligent caching for faster subsequent runs

### Advanced Features
- **Comprehensive Reporting**: Generates HTML, JSON, XML, and SARIF reports
- **GitHub Security Integration**: Uploads results to GitHub Security tab
- **Automated Notifications**: Creates GitHub issues for high-severity vulnerabilities
- **Smart Caching**: Caches NuGet packages and OWASP database for performance
- **Scheduled Scans**: Weekly automated security scans

## 🚀 Setup Instructions

### 1. Repository Secrets (Optional)
For enhanced GitLeaks functionality, you can add:
```
GITLEAKS_LICENSE: Your GitLeaks Pro license (if available)
```

### 2. Workflow Triggers
The workflow runs automatically on:
- **Push** to `master` or `main` branches
- **Pull Requests** targeting `master` or `main` branches  
- **Schedule**: Weekly on Sundays at 2 AM UTC
- **Manual**: Can be triggered manually from GitHub Actions tab

### 3. Permissions Required
The workflow requires these permissions (automatically configured):
- `contents: read` - To checkout code
- `security-events: write` - To upload SARIF results to Security tab

## 📊 Understanding Results

### GitLeaks Results
- **Location**: Workflow logs under "Run GitLeaks Secret Scan"
- **Format**: Detailed output showing any detected secrets
- **Action**: Review and remove any exposed secrets immediately

### OWASP Dependency Check Results
- **GitHub Security Tab**: Navigate to Security → Code scanning alerts
- **Artifacts**: Download `owasp-dependency-check-results` from workflow run
- **Reports Available**:
  - `dependency-check-report.html` - Human-readable report
  - `dependency-check-report.json` - Machine-readable data
  - `dependency-check-report.xml` - XML format
  - `dependency-check-report.sarif` - Security analysis format

### Job Summary
Each workflow run provides a comprehensive summary showing:
- Scan status and completion details
- Links to results and artifacts
- Next steps for remediation

## 🛠️ Customization Options

### Adjusting CVSS Threshold
To change the vulnerability severity threshold, modify this line in `.github/workflows/security-scan.yml`:
```powershell
--failOnCVSS 7 `  # Change to your desired threshold (0-10)
```

### Adding File Exclusions
To exclude additional directories/files from scanning:
```powershell
--exclude "**\your-directory\**" `
```

### Changing Scan Schedule
Modify the cron expression in the workflow:
```yaml
schedule:
  - cron: '0 2 * * 0'  # Currently: Weekly on Sundays at 2 AM UTC
```

### Notification Customization
The automatic issue creation can be customized by modifying the `notify-on-vulnerabilities` job.

## 🔍 Troubleshooting

### Common Issues

1. **Workflow Fails on First Run**
   - OWASP database download may timeout on first run
   - Re-run the workflow - subsequent runs will be cached and faster

2. **Large Repository Scanning**
   - First scan may take 10-15 minutes
   - Cached runs typically complete in 3-5 minutes

3. **False Positives**
   - Review OWASP reports carefully
   - Some vulnerabilities may not apply to your specific usage
   - Consider suppression files for confirmed false positives

### Performance Optimization
- **Caching**: The workflow caches NuGet packages and OWASP database
- **Exclusions**: Pre-configured to exclude common non-source directories
- **Windows Runner**: Optimized for .NET projects with Windows-specific tooling

## 📈 Security Best Practices

1. **Regular Monitoring**: Review Security tab weekly
2. **Prompt Updates**: Update dependencies when vulnerabilities are found
3. **Secret Management**: Use GitHub Secrets for sensitive data
4. **Branch Protection**: Require security checks to pass before merging
5. **Team Awareness**: Ensure team members understand security alerts

## 🎯 Integration with Existing Workflows

This security workflow is designed to complement your existing `build.yml` workflow:
- **Independent**: Runs separately from build process
- **Non-blocking**: Doesn't interfere with development workflow
- **Comprehensive**: Covers areas not addressed by other security tools

The workflow works alongside your existing:
- SonarQube/SonarCloud analysis
- Trivy vulnerability scanning  
- CodeQL analysis

## 📚 Additional Resources

- [OWASP Dependency Check Documentation](https://owasp.org/www-project-dependency-check/)
- [GitLeaks Documentation](https://github.com/gitleaks/gitleaks)
- [GitHub Security Features](https://docs.github.com/en/code-security)
- [CVSS Scoring System](https://www.first.org/cvss/)

---

**Note**: This workflow is specifically optimized for .NET 8 MVC projects running on Windows runners. Modify paths and commands as needed for different project types. 