# Define download directory
$languagesDir = 'C:\Languages\en-GB'

# Set date
$scriptActionStartTime = get-date

# Create languages software repository
Write-Host "Azure Image Builder: Creating 'Languages' software repository"
New-Item -ItemType Directory -Path $languagesDir -Force

# Begin language pack installation tasks
Write-host ('Azure Image Builder: Beginning en-GB language pack installation tasks [ '+(get-date) + ' ]')

# Download language ISO files
Write-Host "Azure Image Builder: Downloading language pack ISO files"
$progressPreference = 'SilentlyContinue'
Invoke-WebRequest "https://software-download.microsoft.com/download/pr/19041.1.191206-1406.vb_release_amd64fre_FOD-PACKAGES_OEM_PT1_amd64fre_MULTI.iso" -OutFile "$languagesDir\en-GB_FOD.iso"
Invoke-WebRequest "https://software-download.microsoft.com/download/pr/19041.1.191206-1406.vb_release_CLIENTLANGPACKDVD_OEM_MULTI.iso" -OutFile "$languagesDir\en-GB_Language.iso"

# Disable scheduled task for language pack cleanup
Write-Host "Azure Image Builder: Disabling scheduled task 'Pre-staged app cleanup'"
Disable-ScheduledTask -TaskPath "\Microsoft\Windows\AppxDeploymentClient\" -TaskName "Pre-staged app cleanup"

# Mount language ISO files
Write-Host "Azure Image Builder: Mounting language pack ISO file to system"
$mountResult = Mount-DiskImage -ImagePath "$languagesDir\en-GB_FOD.iso" -PassThru
$driveLetter = ($mountResult | Get-Volume).DriveLetter

[string]$LIPContent = $driveLetter+":"

# Install language packs
Write-Host "Azure Image Builder: Installing Language Features Basic"
Start-Process -FilePath PowerShell -ArgumentList "Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-LanguageFeatures-Basic-en-gb-Package~31bf3856ad364e35~amd64~~.cab" -Wait
Write-Host "Azure Image Builder: Installing Language Features Handwriting"
Start-Process -FilePath PowerShell -ArgumentList "Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-LanguageFeatures-Handwriting-en-gb-Package~31bf3856ad364e35~amd64~~.cab" -Wait 
Write-Host "Azure Image Builder: Installing Language Features OCR"
Start-Process -FilePath PowerShell -ArgumentList "Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-LanguageFeatures-OCR-en-gb-Package~1bf3856ad364e35~amd64~~.cab" -Wait 
Write-Host "Azure Image Builder: Installing Language Features Text-to-Speech"
Start-Process -FilePath PowerShell -ArgumentList "Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-LanguageFeatures-TextToSpeech-en-gb-Package~31bf3856ad364e35~amd64~~.cab" -Wait 
Write-Host "Azure Image Builder: Installing NetFx3 package"
Start-Process -FilePath PowerShell -ArgumentList "Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-NetFx3-OnDemand-Package~31bf3856ad364e35~amd64~en-gb~.cab" -Wait
Write-Host "Azure Image Builder: Installing Internet Explorer package"
Start-Process -FilePath PowerShell -ArgumentList "Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-InternetExplorer-Optional-Package~31bf3856ad364e35~amd64~en-gb~.cab" -Wait
Write-Host "Azure Image Builder: Installing MS Paint package"
Start-Process -FilePath PowerShell -ArgumentList "Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-MSPaint-FoD-Package~31bf3856ad364e35~amd64~en-gb~.cab" -Wait 
Write-Host "Azure Image Builder: Installing Notepad package"
Start-Process -FilePath PowerShell -ArgumentList "Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-Notepad-FoD-Package~31bf3856ad364e35~amd64~en-gb~.cab" -Wait 
Write-Host "Azure Image Builder: Installing PowerShell ISE package"
Start-Process -FilePath PowerShell -ArgumentList "Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-PowerShell-ISE-FOD-Package~31bf3856ad364e35~amd64~en-gb~.cab" -Wait 
Write-Host "Azure Image Builder: Installing Printing WFS package"
Start-Process -FilePath PowerShell -ArgumentList "Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-Printing-WFS-FoD-Package~31bf3856ad364e35~amd64~en-gb~.cab" -Wait 
Write-Host "Azure Image Builder: Installing Steps Recorder package"
Start-Process -FilePath PowerShell -ArgumentList "Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-StepsRecorder-Package~31bf3856ad364e35~amd64~en-gb~.cab" -Wait 
Write-Host "Azure Image Builder: Installing WordPad package"
Start-Process -FilePath PowerShell -ArgumentList "Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-WordPad-FoD-Package~31bf3856ad364e35~amd64~en-gb~.cab" -Wait 

# Dismount language ISO file
Write-Host "Azure Image Builder: Dismounting language pack ISO file from system"
Dismount-DiskImage -ImagePath "$languagesDir\en-GB_FOD.iso"

# Mount language ISO files
Write-Host "Azure Image Builder: Mounting language pack ISO file to system"
$mountResult = Mount-DiskImage -ImagePath "$languagesDir\en-GB_Language.iso" -PassThru
$driveLetter = ($mountResult | Get-Volume).DriveLetter

[string]$LIPContent = $driveLetter+":"

# Install language packs
Write-Host "Azure Image Builder: Installing Language Experience Pack"
Start-Process -FilePath PowerShell -ArgumentList "Add-AppProvisionedPackage -Online -PackagePath $LIPContent\LocalExperiencePack\en-GB\LanguageExperiencePack.en-GB.Neutral.appx -LicensePath $LIPContent\LocalExperiencePack\en-GB\License.xml" -Wait 
Write-Host "Azure Image Builder: Installing Client Language Pack"
Start-Process -FilePath PowerShell -ArgumentList "Add-WindowsPackage -Online -PackagePath $LIPContent\x64\langpacks\Microsoft-Windows-Client-Language-Pack_x64_en-gb.cab" -Wait

# Dismount language ISO file
Write-Host "Azure Image Builder: Dismounting language pack ISO file from system"
Dismount-DiskImage -ImagePath "$languagesDir\en-GB_Language.iso"

# Set Windows User Language
Write-Host "Azure Image Builder: Setting Windows User Language"
$LanguageList = Get-WinUserLanguageList
$LanguageList.Add("en-gb")
Set-WinUserLanguageList $LanguageList -Force

$scriptActionDuration = (get-date) - $scriptActionStartTime

Write-Host "*** Install en-GB language pack time: "$scriptActionDuration.Minutes "Minute(s), " $scriptActionDuration.seconds "Seconds and " $scriptActionDuration.Milliseconds "Milleseconds"
