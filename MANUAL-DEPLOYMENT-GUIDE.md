# Manual Deployment Guide

When the GitHub Actions deployment completes successfully but deploys to a temporary directory (due to lack of Administrator privileges), you can manually copy the files to the IIS directory.

## 🎯 When to Use This Guide

You'll need this when you see output like:
```
[INFO] Created temporary directory for testing: C:\Windows\SERVIC~1\NETWOR~1\AppData\Local\Temp\TodoApp_Deploy_Test
[INFO] Using temporary target path: C:\Windows\SERVIC~1\NETWOR~1\AppData\Local\Temp\TodoApp_Deploy_Test
[SUCCESS] Files copied successfully
[INFO] Copied 73 files to target directory
```

## 🚀 Quick Manual Copy

### Step 1: Run as Administrator
```powershell
# Open PowerShell as Administrator
# Navigate to your project directory
cd D:\PracticeDevOps\MVC  # or your project path
```

### Step 2: Execute Manual Copy Script
```powershell
# Run the manual copy script
.\scripts\manual-copy-deployment.ps1
```

The script will:
- ✅ Check Administrator privileges
- ✅ Verify temporary files exist
- ✅ Create IIS directory with proper permissions
- ✅ Stop IIS services safely
- ✅ Copy all files from temp to IIS directory
- ✅ Start IIS services
- ✅ Show deployment summary

## 🔧 Manual Steps (Alternative)

If you prefer to do it manually:

### 1. Create IIS Directory
```powershell
# Run as Administrator
New-Item -ItemType Directory -Path "C:\inetpub\wwwroot\TodoApp" -Force
```

### 2. Set Permissions
```powershell
icacls "C:\inetpub\wwwroot\TodoApp" /grant "IIS_IUSRS:(OI)(CI)F" /T
icacls "C:\inetpub\wwwroot\TodoApp" /grant "IUSR:(OI)(CI)R" /T
icacls "C:\inetpub\wwwroot\TodoApp" /grant "IIS AppPool\TodoMVCAppPool:(OI)(CI)F" /T
```

### 3. Stop IIS Services
```powershell
Import-Module WebAdministration
Stop-WebAppPool -Name "TodoMVCAppPool"
Stop-Website -Name "TodoMVCApp"
```

### 4. Copy Files
```powershell
$tempPath = "C:\Windows\SERVIC~1\NETWOR~1\AppData\Local\Temp\TodoApp_Deploy_Test"
$iisPath = "C:\inetpub\wwwroot\TodoApp"
Copy-Item -Path "$tempPath\*" -Destination $iisPath -Recurse -Force
```

### 5. Start IIS Services
```powershell
Start-WebAppPool -Name "TodoMVCAppPool"
Start-Website -Name "TodoMVCApp"
```

## 🎯 Long-term Solution: Fix Runner Privileges

### Option 1: Install Runner as Service (Recommended)
```powershell
# Stop current runner
# Navigate to runner directory
cd C:\actions-runner  # or your runner path

# Install as Windows service (run as Administrator)
.\svc.sh install
.\svc.sh start
```

### Option 2: Run Runner as Administrator
```powershell
# Stop current runner service if running
Get-Service -Name "*actions.runner*" | Stop-Service

# Run PowerShell as Administrator
cd C:\actions-runner  # or your runner path
.\run.cmd
```

### Option 3: Create Dedicated Deployment User
```powershell
# Create deployment user with admin privileges
net user "DeployUser" "SecurePassword123!" /add
net localgroup "Administrators" "DeployUser" /add

# Configure runner to run as this user
```

## 🔍 Troubleshooting

### Issue: Temp Directory Not Found
**Solution**: Run the GitHub Actions deployment first to create the temporary directory with files.

### Issue: Permission Denied
**Solution**: Make sure you're running PowerShell as Administrator.

### Issue: IIS Services Won't Start
**Check**:
```powershell
# Check application pool status
Get-IISAppPool -Name "TodoMVCAppPool"

# Check website status  
Get-IISSite -Name "TodoMVCApp"

# Check for errors in Event Viewer
Get-EventLog -LogName Application -Source "ASP.NET*" -Newest 5
```

### Issue: Website Not Accessible
**Verify**:
1. IIS is running: `Get-Service W3SVC`
2. Website is started: `Get-IISSite -Name "TodoMVCApp"`
3. Application pool is started: `Get-IISAppPool -Name "TodoMVCAppPool"`
4. Firewall allows HTTP traffic
5. Files exist in IIS directory: `Get-ChildItem "C:\inetpub\wwwroot\TodoApp"`

## ✅ Verification Steps

After deployment, verify:

### 1. Check Files
```powershell
Get-ChildItem "C:\inetpub\wwwroot\TodoApp" | Format-Table Name, Length, LastWriteTime
```

### 2. Check IIS Status
```powershell
Get-IISAppPool -Name "TodoMVCAppPool" | Select-Object Name, State
Get-IISSite -Name "TodoMVCApp" | Select-Object Name, State
```

### 3. Test Application
- Open browser and navigate to `http://localhost` (or your configured domain)
- Check that the Todo application loads correctly
- Test basic functionality (create, edit, delete todos)

## 📋 Deployment Checklist

- [ ] GitHub Actions deployment completed successfully
- [ ] Temporary directory contains all files (73+ files expected)
- [ ] Running PowerShell as Administrator
- [ ] IIS directory created with proper permissions
- [ ] Files copied from temp to IIS directory
- [ ] IIS services restarted
- [ ] Website accessible in browser
- [ ] Application functionality tested
- [ ] Temporary directory cleaned up (optional)

---

**Note**: This manual process is a workaround. For production environments, it's recommended to configure the GitHub Actions runner with proper Administrator privileges to enable fully automated deployments. 