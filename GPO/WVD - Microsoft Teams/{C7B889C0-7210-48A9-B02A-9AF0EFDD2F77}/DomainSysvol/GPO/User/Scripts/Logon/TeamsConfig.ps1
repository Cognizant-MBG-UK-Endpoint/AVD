param(
# Define parameters and values
[string]$newWebLanguage="en-gb",
[bool]$newDisableGpu=$true,
[string]$desktopConfigFile=“$env:userprofile\\AppData\Roaming\Microsoft\Teams\desktop-config.json”,
[string]$cookieFile="$env:userprofile\\AppData\Roaming\Microsoft\teams\Cookies",
[string]$installPath="C:\Program Files (x86)\Microsoft\Teams\current\Teams.exe",
[string]$processName="Teams"
)

#Allow time for Teams to be installed at first logon
Start-Sleep 60

#Check if Teams is installed
$installPathCheck = Get-ChildItem -Path $installPath -ErrorAction SilentlyContinue
#Check if Teams process is running
$processCheck = Get-Process $processName -ErrorAction SilentlyContinue
#Read the Teams desktop config file and convert from JSON
$config = (Get-Content -Path $desktopConfigFile | ConvertFrom-Json -ErrorAction SilentlyContinue)
#Check if required parameter value is already set within Teams desktop config file
$configCheck = $config | where {($_.currentWebLanguage -ne $newWebLanguage) -or ($_.appPreferenceSettings.disableGpu -ne $newDisableGpu)} -ErrorAction SilentlyContinue
#Check if Teams cookie file exists
$cookieFileCheck = Get-Item -path $cookieFile -ErrorAction SilentlyContinue

#1-If Teams is installed ($installPathCheck not null)
#2-If Teams desktop config settings current value doesn't match parameter value ($configCheck not null)
#3-If Teams process is running ($processCheck not null)
#4-Then terminate the Teams process and wait 5 seconds
if ($installPathCheck -and $configCheck -and $processCheck)
{
    Get-Process $processName | Stop-Process -Force
    Start-Sleep 5
}

#Check if Teams process is stopped
$processCheckFinal = Get-Process $processName -ErrorAction SilentlyContinue

#1-If Teams is installed ($installPathCheck not null)
#2-If Teams desktop config settings current value doesn't match parameter value ($configCheck not null)
#3-Then update Teams desktop config file with new parameter value
if ($installPathCheck -and $configCheck)
{
    $config.currentWebLanguage=$newWebLanguage
    $config.appPreferenceSettings.disableGpu=$newDisableGpu
    $config | ConvertTo-Json -Compress | Set-Content -Path $desktopConfigFile -Force

#1-If Teams process is stopped ($processCheckFinal is null)
#2-If Teams cookie file exists ($cookieFileCheck not null)
#3-Then delete cookies file

    if (!$processCheckFinal -and $cookieFileCheck)
    {
        Remove-Item -path $cookieFile -Force
        Start-Process $installPath
    }
}