#!/usr/bin/env pwsh
# Test Parameter Replacement Script
# This script tests parameter replacement functionality locally before deployment

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("production", "staging", "development")]
    [string]$Environment = "production",
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf = $false
)

Write-Host "=== TESTING PARAMETER REPLACEMENT ===" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host "WhatIf Mode: $WhatIf" -ForegroundColor Yellow
Write-Host ""

# Check if required files exist
$requiredFiles = @(
    "appsettings.json",
    "Parameters.xml",
    "parameters/setParameters.xml",
    "parameters/setParameters.$Environment.xml"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Error "Missing required files: $($missingFiles -join ', ')"
    exit 1
}

Write-Host "[OK] All required files found" -ForegroundColor Green

# Load original appsettings.json
$originalContent = Get-Content "appsettings.json" -Raw
Write-Host ""
Write-Host "Original appsettings.json:" -ForegroundColor Yellow
Write-Host $originalContent

# Find placeholders in original content
$placeholders = @()
$placeholderPattern = '\{\{[A-Z_]+\}\}'
$matches = [regex]::Matches($originalContent, $placeholderPattern)
foreach ($match in $matches) {
    if ($placeholders -notcontains $match.Value) {
        $placeholders += $match.Value
    }
}

Write-Host ""
Write-Host "Found placeholders: $($placeholders -join ', ')" -ForegroundColor Cyan

# Load parameter file
$paramFile = "parameters/setParameters.$Environment.xml"
if (-not (Test-Path $paramFile)) {
    $paramFile = "parameters/setParameters.xml"
    Write-Warning "Environment-specific parameter file not found, using default: $paramFile"
}

Write-Host "Using parameter file: $paramFile" -ForegroundColor Green

[xml]$setParams = Get-Content $paramFile
Write-Host ""
Write-Host "Parameters from ${paramFile}:" -ForegroundColor Yellow
foreach ($param in $setParams.parameters.setParameter) {
    Write-Host "  $($param.name) = '$($param.value)'"
}

# Perform replacement
$modifiedContent = $originalContent
$replacements = @()

foreach ($param in $setParams.parameters.setParameter) {
    $paramName = $param.name
    $paramValue = $param.value
    
    # Map parameter names to placeholders
    $placeholder = switch ($paramName) {
        "Authentication-DefaultCredentials-Username" { "{{USERNAME_PLACEHOLDER}}" }
        "Authentication-DefaultCredentials-Password" { "{{PASSWORD_PLACEHOLDER}}" }
        "Logging-LogLevel-Default" { "{{LOGLEVEL_PLACEHOLDER}}" }
        "Application-Domain" { "{{DOMAIN_PLACEHOLDER}}" }
        "Application-UseSSL" { "{{SSL_PLACEHOLDER}}" }
        "DefaultConnection" { "{{CONNECTION_PLACEHOLDER}}" }
        default { $null }
    }
    
    if ($placeholder) {
        if ($modifiedContent -match [regex]::Escape($placeholder)) {
            $modifiedContent = $modifiedContent -replace [regex]::Escape($placeholder), $paramValue
            $replacements += @{
                Placeholder = $placeholder
                Parameter = $paramName
                Value = $paramValue
                Found = $true
            }
        } else {
            $replacements += @{
                Placeholder = $placeholder
                Parameter = $paramName
                Value = $paramValue
                Found = $false
            }
        }
    }
}

Write-Host ""
Write-Host "Replacement Results:" -ForegroundColor Cyan
foreach ($replacement in $replacements) {
    if ($replacement.Found) {
        Write-Host "  [REPLACED] $($replacement.Placeholder) -> '$($replacement.Value)'" -ForegroundColor Green
    } else {
        Write-Host "  [NOT FOUND] $($replacement.Placeholder) (parameter: $($replacement.Parameter))" -ForegroundColor Red
    }
}

# Check for remaining placeholders
$remainingPlaceholders = @()
$remainingMatches = [regex]::Matches($modifiedContent, $placeholderPattern)
foreach ($match in $remainingMatches) {
    if ($remainingPlaceholders -notcontains $match.Value) {
        $remainingPlaceholders += $match.Value
    }
}

Write-Host ""
if ($remainingPlaceholders.Count -gt 0) {
    Write-Warning "Remaining unreplaced placeholders: $($remainingPlaceholders -join ', ')"
    Write-Host ""
    Write-Host "These placeholders need to be added to Parameters.xml and setParameters files:" -ForegroundColor Yellow
    foreach ($placeholder in $remainingPlaceholders) {
        Write-Host "  $placeholder"
    }
} else {
    Write-Host "[SUCCESS] All placeholders have been replaced!" -ForegroundColor Green
}

Write-Host ""
Write-Host "Modified appsettings.json:" -ForegroundColor Yellow
Write-Host $modifiedContent

# Validate JSON syntax
try {
    $jsonObject = $modifiedContent | ConvertFrom-Json
    Write-Host ""
    Write-Host "[SUCCESS] Modified content is valid JSON" -ForegroundColor Green
} catch {
    Write-Error "Modified content is not valid JSON: $($_.Exception.Message)"
    exit 1
}

# Save test output if not in WhatIf mode
if (-not $WhatIf) {
    $testOutputFile = "appsettings.$Environment.test.json"
    $modifiedContent | Out-File -FilePath $testOutputFile -Encoding UTF8 -Force
    Write-Host ""
    Write-Host "Test output saved to: $testOutputFile" -ForegroundColor Green
    Write-Host "You can review this file to verify the replacement results." -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "WhatIf mode: No files were modified" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "=== TEST COMPLETED ===" -ForegroundColor Cyan

# Summary
$totalPlaceholders = $placeholders.Count
$replacedCount = ($replacements | Where-Object { $_.Found }).Count
$unreplacedCount = $remainingPlaceholders.Count

Write-Host ""
Write-Host "Summary:" -ForegroundColor White
Write-Host "  Total placeholders found: $totalPlaceholders"
Write-Host "  Successfully replaced: $replacedCount"
Write-Host "  Still unreplaced: $unreplacedCount"

if ($unreplacedCount -eq 0 -and $replacedCount -gt 0) {
    Write-Host ""
    Write-Host "✅ Parameter replacement test PASSED" -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "❌ Parameter replacement test FAILED" -ForegroundColor Red
    Write-Host "Please fix the issues above before deploying." -ForegroundColor Yellow
    exit 1
} 