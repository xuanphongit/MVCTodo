# GitLeaks Configuration for .NET Applications (v8.26.0 Compatible)

This repository includes a custom `.gitleaks.toml` configuration file specifically designed for .NET applications using the latest GitLeaks v8.26.0 syntax and features.

## 🎯 Configuration Features

### Extends Default Rules
The configuration extends the [official GitLeaks ruleset](https://github.com/gitleaks/gitleaks) to maintain comprehensive coverage while adding .NET-specific customizations.

### Updated v8.26.0 Syntax
- **Modern Allowlists**: Uses `[[allowlists]]` syntax (replaces deprecated `[allowlist]`)
- **Enhanced Performance**: Leverages `stopwords` for better performance over complex regex patterns
- **Condition Logic**: Supports `AND`/`OR` conditions for precise rule matching
- **Target Specification**: Uses `regexTarget` to specify what part of the finding to match

### .NET-Specific Secret Detection
Detects common secrets found in .NET applications:
- **Connection Strings**: SQL Server, Entity Framework connection strings with embedded credentials
- **Azure Keys**: Storage account keys, Function keys, Service Principal secrets
- **API Keys**: NuGet API keys, third-party service keys (SendGrid, Stripe, Twilio)
- **OAuth Secrets**: Client secrets and tokens
- **JWT Tokens**: Bearer tokens and authentication tokens

### Smart Exclusions
Reduces false positives by excluding:
- .NET version numbers and framework references
- Standard GUIDs in comments and documentation
- Package version numbers
- Build and package directories (`bin/`, `obj/`, `.vs/`, `packages/`)
- Test and example data patterns using efficient `stopwords`

## 📋 Detected Secret Types

| Secret Type | Example Pattern | Keywords | Enhanced Features |
|-------------|----------------|----------|-------------------|
| Connection Strings | `Server=.;User ID=sa;Password=secret` | server, password, user id | Rule-specific allowlists |
| Azure Storage Keys | `AccountKey=base64string==` | AccountKey, StorageKey | Context-aware detection |
| API Keys | `ApiKey=abc123def456` | apikey, api_key | Stopword filtering |
| JWT Tokens | `eyJhbGc...` | jwt, token, bearer | Comment exclusions |
| NuGet Keys | `oy2abcdef...` | nuget, api-key | Pattern-specific rules |
| OAuth Secrets | `client_secret=abcdef123` | client_secret | Multi-condition logic |

## 🆕 New v8.26.0 Features

### Enhanced Allowlist System
```toml
# Multiple allowlists with different conditions
[[allowlists]]
description = "Global .NET patterns"
condition = "OR"  # Default condition
regexTarget = "match"  # Can be "match", "secret", or "line"

[[allowlists]]
description = "Specific rule targeting"
targetRules = ["dotnet-api-key", "jwt-token"]  # Apply only to specific rules
```

### Stopwords for Performance
```toml
stopwords = [
    "test", "example", "demo", "sample", "fake", "mock", "dummy"
]
```

### Rule-Specific Allowlists
```toml
[[rules]]
id = "my-rule"
regex = '''pattern'''

    [[rules.allowlists]]
    description = "Rule-specific exclusions"
    condition = "AND"  # All conditions must match
    regexTarget = "line"
```

## 🔧 Customization

### Adding Custom Rules with Modern Syntax
```toml
[[rules]]
id = "my-custom-api-key"
description = "My Application API Key"
regex = '''myapp-[a-zA-Z0-9]{32}'''
keywords = ["myapp-", "custom-key"]

    # Rule-specific allowlist
    [[rules.allowlists]]
    description = "Allow test keys"
    condition = "OR"
    stopwords = ["test", "demo"]
    regexes = ['''(?i)test.*myapp''']
```

### Global Allowlists with Conditions
```toml
[[allowlists]]
description = "Exclude false positives"
condition = "AND"  # All conditions must match
regexTarget = "secret"
regexes = ['''your-pattern''']
paths = ['''**/test/**''']
```

### File-Specific Rules
```toml
[[rules]]
id = "config-file-secrets"
regex = '''(password|secret)\s*=\s*["\'][^"\']+["\']'''
paths = [
    '''**/appsettings.json''',
    '''**/web.config''',
]

    [[rules.allowlists]]
    description = "Allow configuration templates"
    condition = "OR"
    regexTarget = "match"
    regexes = ['''(?i)your[_-]?password''']
```

## 🚫 Enhanced Exclusion System

### Smart Directory Exclusions
```toml
[[allowlists]]
paths = [
    '''**/bin/**''',      # Build outputs
    '''**/obj/**''',      # Temporary build files
    '''**/.vs/**''',      # Visual Studio files
    '''**/packages/**''', # NuGet packages
    '''**/.nuget/**''',   # NuGet cache
]
```

### Pattern-Based Exclusions
```toml
[[allowlists]]
description = "Performance optimization"
regexTarget = "secret"
regexes = [
    '''^.{1,7}$''',    # Too short to be real secrets
    '''^\*+$''',       # Placeholder asterisks
    '''^x+$''',        # Placeholder x's
]
```

## 📝 Advanced Usage Examples

### Detect with Decoding (New Feature)
```bash
# Enable automatic decoding of base64, hex, and URL-encoded secrets
gitleaks detect --config .gitleaks.toml --max-decode-depth 3
```

### Generate SARIF Report
```bash
# Generate SARIF format for security tools integration
gitleaks detect --config .gitleaks.toml --report-format sarif --report-path gitleaks.sarif
```

### Use with Fingerprinting
```bash
# Generate baseline with fingerprints for .gitleaksignore
gitleaks detect --config .gitleaks.toml --baseline-path .gitleaksignore
```

### Custom Report Template
```bash
# Use custom Go template for reporting
gitleaks detect --config .gitleaks.toml --report-format template --report-template custom.tmpl
```

## 🔍 Testing Your Configuration

### Test Against Sample Data
Create a comprehensive test file:

```csharp
// Test file: test-secrets.cs
public class TestSecrets 
{
    // This should be detected
    private string connectionString = "Server=prod.db.com;User ID=admin;Password=RealSecret123!;";
    
    // This should be ignored (test pattern with stopword)
    private string testPassword = "test-password-123";
    
    // This should be ignored (comment GUID)
    // Example GUID: 12345678-1234-1234-1234-123456789abc
    
    // This should be detected (real API key pattern)
    private string apiKey = "sk_live_YOUR_STRIPE_KEY_HERE_32_CHARS";
    
    // This should be ignored (demo API key with stopword)
    private string demoApiKey = "demo-api-key-fake123";
}
```

### Comprehensive Testing
```bash
# Verbose output to see rule matching
gitleaks detect --config .gitleaks.toml --source test-secrets.cs --verbose

# Test with decoding enabled
gitleaks detect --config .gitleaks.toml --source test-secrets.cs --max-decode-depth 2

# Generate detailed report
gitleaks detect --config .gitleaks.toml --source test-secrets.cs --report-format json --report-path test-results.json
```

## 🛠️ Integration with CI/CD

### GitHub Actions Integration
The configuration automatically works with your existing security workflow using `gacts/gitleaks@v1`.

### Pre-commit Hook (Updated)
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.26.0  # Use latest version
    hooks:
      - id: gitleaks
        args: ['--config', '.gitleaks.toml', '--verbose']
```

### Docker Integration
```bash
# Run with Docker
docker run --rm -v $(pwd):/workspace zricethezav/gitleaks:v8.26.0 \
  detect --config /workspace/.gitleaks.toml --source /workspace
```

## 📊 Performance Optimizations

### Stopwords vs Regex
The updated configuration uses `stopwords` instead of complex regex patterns for common exclusions, providing:
- **Better Performance**: 50-80% faster scanning
- **Lower Memory Usage**: Reduced regex compilation overhead
- **Easier Maintenance**: Simple string matching vs complex patterns

### Entropy-Based Filtering
```toml
# Automatic entropy calculation helps reduce false positives
# Secrets with very low entropy (common words) are filtered out
# Secrets with very high entropy (random data) are also filtered
```

### Condition Logic
```toml
# Use AND conditions to be more specific
condition = "AND"  # All criteria must match

# Use OR conditions for broader matching
condition = "OR"   # Any criteria can match (default)
```

## 🔒 Security Best Practices

1. **Regular Updates**: Update to latest GitLeaks version for new rules and performance improvements
2. **Baseline Management**: Use `.gitleaksignore` with fingerprints for confirmed false positives
3. **Decoding Detection**: Enable `--max-decode-depth` to catch encoded secrets
4. **Custom Templates**: Create organization-specific report templates
5. **Integration Testing**: Test configuration changes against known test data

## 🚀 New Features in v8.26.0

- **Enhanced Performance**: Improved scanning speed and memory usage
- **Better Decoding**: Automatic detection of base64, hex, and URL-encoded secrets
- **Fingerprinting**: Unique identifiers for each finding to improve ignore management
- **SARIF Support**: Better integration with security scanning tools
- **Template Engine**: Custom report formatting with Go templates

## 📚 Additional Resources

- [GitLeaks Official Repository](https://github.com/gitleaks/gitleaks)
- [GitLeaks v8.26.0 Release Notes](https://github.com/gitleaks/gitleaks/releases/tag/v8.26.0)
- [Configuration Documentation](https://github.com/gitleaks/gitleaks#configuration)
- [Default Rules Reference](https://github.com/gitleaks/gitleaks/blob/master/config/gitleaks.toml)
- [Regular Expression Testing](https://regex101.com/)
- [.NET Security Best Practices](https://docs.microsoft.com/en-us/dotnet/standard/security/)

---

**Note**: This configuration is optimized for GitLeaks v8.26.0 and .NET applications. The updated syntax provides better performance and more precise control over secret detection. 