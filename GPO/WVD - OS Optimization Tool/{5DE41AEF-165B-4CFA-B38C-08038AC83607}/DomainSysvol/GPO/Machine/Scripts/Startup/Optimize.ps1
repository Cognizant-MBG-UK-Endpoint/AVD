$softwareRepo = "C:\Scripts"
$WantFile = "C:\Scripts\Virtual-Desktop-Optimization-Tool-main\Optimized.txt"
$FileExists = Test-Path $WantFile

# Run Windows 10 multi-session optimization script
If ($FileExists -eq $True) {exit}
Else {
# Create repository for WVD OS optimization tool
Write-Host "Creating repostiory for WVD OS optimization tool"
New-Item -ItemType Directory -Path $softwareRepo -Force -ErrorAction SilentlyContinue

# Download WVD OS optimization tool
Write-Host "Downloading WVD OS optimization tool"
Invoke-WebRequest -Uri "https://github.com/Cognizant-MBG-UK-Endpoint/WVD/blob/main/Optimize/Virtual-Desktop-Optimization-Tool-main.zip?raw=true" -OutFile "$softwareRepo\Optimize.zip"

# Extract WVD OS optimization tool
Write-Host "Extracting WVD OS optimization tool"
Expand-Archive -Path "$softwareRepo\Optimize.zip" -DestinationPath "$softwareRepo" -Force
Remove-Item -Path "$softwareRepo\Optimize.zip" -Force

# Execute WVD OS optimization tool
Write-Host "Executing WVD OS optimization tool"
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose
Start-Process -FilePath PowerShell.exe -ArgumentList "$softwareRepo\Virtual-Desktop-Optimization-Tool-main\Win10_VirtualDesktop_Optimize.ps1 -WindowsVersion 2009 -Verbose" -Wait
Write-Host "Completed WVD OS optimization"

# Create verification check text file
Write-Host "Creating verification check text file"
New-Item -ItemType File -Path "$softwareRepo\Virtual-Desktop-Optimization-Tool-main\Optimized.txt" -Force

# Restart computer
Write-Host "Restarting computer"
Restart-Computer -Force
}