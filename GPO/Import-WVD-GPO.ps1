
$path = "C:\Temp"

# Import Computer settings GPO
Write-Host "Importing 'WVD - Computer Settings' Group Policy Object"
Import-GPO -BackupGpoName 'WVD - Computer Settings' -TargetName 'WVD - Computer Settings' -Path "$path\WVD - Computer Settings" -CreateIfNeeded

# Import Disable Hardware Acceleration GPO
Write-Host "Importing 'WVD - Disable Hardware Acceleration' Group Policy Object"
Import-GPO -BackupGpoName 'WVD - Disable Hardware Acceleration' -TargetName 'WVD - Disable Hardware Acceleration' -Path "$path\WVD - Disable Hardware Acceleration" -CreateIfNeeded

# Import FSLogix AppMasking GPO
Write-Host "Importing 'WVD - FSLogix AppMasking' Group Policy Object"
Import-GPO -BackupGpoName 'WVD - FSLogix AppMasking' -TargetName 'WVD - FSLogix AppMasking' -Path "$path\WVD - FSLogix AppMasking" -CreateIfNeeded

# Import FSLogix Office Containers GPO
Write-Host "Importing 'WVD - FSLogix Office Containers' Group Policy Object"
Import-GPO -BackupGpoName 'WVD - FSLogix Office Containers' -TargetName 'WVD - FSLogix Office Containers' -Path "$path\WVD - FSLogix Office Containers" -CreateIfNeeded

# Import FSLogix Profile Containers GPO
Write-Host "Importing 'WVD - FSLogix Profile Containers' Group Policy Object"
Import-GPO -BackupGpoName 'WVD - FSLogix Profile Containers' -TargetName 'WVD - FSLogix Profile Containers' -Path "$path\WVD - FSLogix Profile Containers" -CreateIfNeeded

# Import Microsoft 365 Apps for Enterprise GPO
Write-Host "Importing 'WVD - Microsoft 365 Apps for Enterprise' Group Policy Object"
Import-GPO -BackupGpoName 'WVD - Microsoft 365 Apps for Enterprise' -TargetName 'WVD - Microsoft 365 Apps for Enterprise' -Path "$path\WVD - Microsoft 365 Apps for Enterprise" -CreateIfNeeded

# Import Microsoft OneDrive for Business GPO
Write-Host "Importing 'WVD - Microsoft OneDrive for Business' Group Policy Object"
Import-GPO -BackupGpoName 'WVD - Microsoft OneDrive for Business' -TargetName 'WVD - Microsoft OneDrive for Business' -Path "$path\WVD - Microsoft OneDrive for Business" -CreateIfNeeded

# Import Microsoft Teams GPO
Write-Host "Importing 'WVD - Microsoft Teams' Group Policy Object"
Import-GPO -BackupGpoName 'WVD - Microsoft Teams' -TargetName 'WVD - Microsoft Teams' -Path "$path\WVD - Microsoft Teams" -CreateIfNeeded

# Import OS Optimization Tool GPO
Write-Host "Importing 'WVD - OS Optimization Tool' Group Policy Object"
Import-GPO -BackupGpoName 'WVD - OS Optimization Tool' -TargetName 'WVD - OS Optimization Tool' -Path "$path\WVD - OS Optimization Tool" -CreateIfNeeded

# Import RDP Shortpath GPO
Write-Host "Importing 'WVD - RDP Shortpath' Group Policy Object"
Import-GPO -BackupGpoName 'WVD - RDP Shortpath' -TargetName 'WVD - RDP Shortpath' -Path "$path\WVD - RDP Shortpath" -CreateIfNeeded

# Import Region & Language GPO
Write-Host "Importing 'WVD - Region & Language' Group Policy Object"
Import-GPO -BackupGpoName 'WVD - Region & Language' -TargetName 'WVD - Region & Language' -Path "$path\WVD - Region & Language" -CreateIfNeeded

# Import Security Settings GPO
Write-Host "Importing 'WVD - Security Settings' Group Policy Object"
Import-GPO -BackupGpoName 'WVD - Security Settings' -TargetName 'WVD - Security Settings' -Path "$path\WVD - Security Settings" -CreateIfNeeded

# Import Start Menu & Taskbar GPO
Write-Host "Importing 'WVD - Start Menu & Taskbar' Group Policy Object"
Import-GPO -BackupGpoName 'WVD - Start Menu & Taskbar' -TargetName 'WVD - Start Menu & Taskbar' -Path "$path\WVD - Start Menu & Taskbar" -CreateIfNeeded

# Import Web Browsers GPO
Write-Host "Importing 'WVD - Web Browsers' Group Policy Object"
Import-GPO -BackupGpoName 'WVD - Web Browsers' -TargetName 'WVD - Web Browsers' -Path "$path\WVD - Web Browsers" -CreateIfNeeded