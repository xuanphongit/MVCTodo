# Todo MVC Application

A secure ASP.NET Core MVC application demonstrating modern web development practices with comprehensive security scanning and vulnerability management.

## 🔒 Security First

This project prioritizes security with automated vulnerability scanning, dependency management, and comprehensive security documentation.

### 🛡️ Security Features

- ✅ **Automated Security Scanning** - OWASP Dependency Check & GitLeaks
- ✅ **Zero High/Critical Vulnerabilities** - Regular security audits
- ✅ **Secure Dependencies** - Minimal attack surface
- ✅ **Vulnerability Tracking** - GitHub Security tab integration
- ✅ **SARIF Compliance** - Industry-standard security reporting

### 🚨 Recent Security Updates

**CVE-2025-48734 Resolved** ✅
- **Date**: January 29, 2025
- **Severity**: High (CVSS 8.8)
- **Fix**: Removed vulnerable `Microsoft.VisualStudio.Web.CodeGeneration.Design` package
- **Status**: Fully resolved, application builds and runs normally

See [SECURITY-ADVISORY.md](SECURITY-ADVISORY.md) for complete details.

## 🚀 Quick Start

### Prerequisites
- .NET 8.0 SDK or later
- Visual Studio 2022 / VS Code (optional)

### Running the Application

```bash
# Clone the repository
git clone <repository-url>
cd MVC

# Restore dependencies
dotnet restore

# Build the application
dotnet build

# Run the application
dotnet run
```

The application will start on `https://localhost:5001` or `http://localhost:5000`.

### Development

```bash
# Run with hot reload for development
dotnet watch run

# Run tests (when available)
dotnet test

# Generate code coverage (when tests available)
dotnet test --collect:"XPlat Code Coverage"
```

## 📁 Project Structure

```
📁 Todo MVC/
├── 📁 Controllers/          # MVC Controllers
│   ├── AccountController.cs
│   └── HomeController.cs
├── 📁 Model/               # Data Models
│   ├── TodoItem.cs
│   └── User.cs
├── 📁 Views/               # Razor Views
├── 📁 Pages/               # Razor Pages (if used)
├── 📁 wwwroot/             # Static files (CSS, JS, images)
├── 📁 Properties/          # Application properties
├── 📁 .github/workflows/   # GitHub Actions workflows
│   └── security-scan.yml  # Security scanning automation
├── 📄 Program.cs           # Application entry point
├── 📄 Todo.csproj          # Project file
├── 📄 .gitleaks.toml       # GitLeaks configuration
├── 📄 SECURITY-ADVISORY.md # Security documentation
└── 📄 README.md            # This file
```

## 🔧 Configuration

### Application Settings

Edit `appsettings.json` and `appsettings.Development.json` for environment-specific configuration:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

### Security Configuration

The application uses several security configurations:

1. **OWASP Dependency Check** - Configured in `.github/workflows/security-scan.yml`
2. **GitLeaks Secret Detection** - Configured in `.gitleaks.toml`
3. **Package Security** - Minimal dependencies in `Todo.csproj`

## 🛡️ Security Scanning

### Automated Scans

Security scans run automatically on:
- Every push to `main`/`master`
- Every pull request
- Weekly schedule (Sundays at 2 AM UTC)
- Manual trigger via GitHub Actions

### Manual Security Scan

```bash
# Run security scan manually (requires GitHub Actions)
# Go to: Actions → Security Scan → Run workflow
```

### Security Reports

Security reports are available in:
- **GitHub Security Tab** - Code scanning alerts
- **GitHub Actions Artifacts** - Downloadable reports
- **SARIF Files** - Industry-standard format

### Viewing Security Results

1. **GitHub Security Tab**: `Repository → Security → Code scanning alerts`
2. **Workflow Artifacts**: `Actions → Latest run → Artifacts`
3. **Security Issues**: Automatically created for vulnerabilities

## 🔧 Development Guidelines

### Adding Dependencies

When adding new packages:

1. **Check Security**: Review package for known vulnerabilities
2. **Minimal Scope**: Add only production-required packages
3. **Pin Versions**: Specify exact versions to avoid surprises
4. **Scan After**: Run security scan after adding packages

```bash
# Example: Adding a secure package
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer --version 8.0.0

# Run security scan after
# (Trigger via GitHub Actions or wait for automated scan)
```

### Security Best Practices

1. **Development Packages**: Install scaffolding packages temporarily only
2. **Version Updates**: Regularly update packages to latest secure versions
3. **Transitive Dependencies**: Review indirect dependencies
4. **Security Testing**: Test security changes in development first

### Scaffolding (If Needed)

If you need scaffolding functionality:

```bash
# Option 1: Temporary installation (RECOMMENDED)
dotnet add package Microsoft.VisualStudio.Web.CodeGeneration.Design --version 9.0.0
# Use scaffolding...
dotnet remove package Microsoft.VisualStudio.Web.CodeGeneration.Design

# Option 2: Use .NET CLI templates
dotnet new controller -n MyController
dotnet new page -n MyPage

# Option 3: Manual development (MOST SECURE)
# Create controllers and views manually
```

## 📊 Security Monitoring

### Security Workflow Features

- **OWASP Dependency Check v12.1.1** - Latest vulnerability database
- **GitLeaks v8.26.0** - Advanced secret detection
- **NVD Integration** - National Vulnerability Database
- **SARIF Reporting** - Industry-standard security format
- **Automated Issues** - Auto-creation of security alerts
- **Detailed Analysis** - Vulnerability severity analysis

### Security Metrics

Current security status:
- ✅ **0 Critical vulnerabilities**
- ✅ **0 High vulnerabilities**
- ✅ **0 Exposed secrets**
- ✅ **Minimal dependencies**
- ✅ **Regular scanning**

## 🤝 Contributing

### Security-First Development

1. **Fork** the repository
2. **Create** a feature branch
3. **Add** your changes with security in mind
4. **Test** locally including security implications
5. **Submit** a pull request
6. **Wait** for automated security scan results
7. **Address** any security issues found

### Pull Request Guidelines

- Include security impact assessment
- Update documentation if needed
- Ensure all security scans pass
- No new vulnerabilities introduced

## 📚 Documentation

### Security Documentation
- [SECURITY-ADVISORY.md](SECURITY-ADVISORY.md) - Recent security updates
- [SECURITY-WORKFLOW.md](SECURITY-WORKFLOW.md) - Security scanning details
- [GITLEAKS-CONFIG.md](GITLEAKS-CONFIG.md) - Secret detection configuration

### Microsoft Documentation
- [ASP.NET Core Security](https://docs.microsoft.com/en-us/aspnet/core/security/)
- [.NET Security Guidelines](https://docs.microsoft.com/en-us/dotnet/standard/security/)
- [Package Security](https://docs.microsoft.com/en-us/nuget/consume-packages/security)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔧 Support

### Security Issues
- **Critical/High**: Create issue with `security` label immediately
- **General Questions**: Use GitHub Discussions
- **Urgent**: Follow responsible disclosure practices

### Development Issues
- Create issue with appropriate labels
- Include reproduction steps
- Specify environment details

## 🎯 Roadmap

### Planned Security Enhancements
- [ ] Additional security headers implementation
- [ ] Content Security Policy (CSP)
- [ ] API rate limiting
- [ ] Input validation enhancements
- [ ] Security unit tests

### Development Features
- [ ] User authentication improvements
- [ ] Todo item persistence
- [ ] API endpoints
- [ ] Frontend enhancements

---

**Last Updated**: January 29, 2025  
**Security Status**: ✅ **SECURE** - No known vulnerabilities  
**Build Status**: ✅ **PASSING** - All builds successful  
**Scan Status**: ✅ **CLEAN** - Latest security scan passed  

For the latest security status, check the [Security tab](../../security) or [GitHub Actions](../../actions). 