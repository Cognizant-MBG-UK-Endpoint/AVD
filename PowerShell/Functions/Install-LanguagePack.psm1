function Install-LanguagePack {
  
    <#
    .SYNOPSIS
    Function to install language(s) with all approriate features on demand.

    .DESCRIPTION
    This PowerShell function is designed to automate the installation of the languages. It builds on the initial idea from Jim Moyle https://github.com/JimMoyle/Install-LanguagePack
    This script will automatically download the required ISO files if they are not already present on the system in the path specified.    

    This script requires 5 external resources for this script to run correctly:

        LPtoFODFile            - CSV file mapping the necessary CAB files to langauge and Windows version
        ISOLookupFile          - CSV file mapping Windows version to FOD and LP ISO file names and URLs for download
        FOD ISO File           - The ISO file containing Features on Demand (Will be downloaded if it does not exist using data from ISOLookupFile)
        LP ISO File            - The ISO file containing Language Pack files (Will be downloaded if it does not exist using data from ISOLookupFile)
                                 https://docs.microsoft.com/en-us/azure/virtual-desktop/language-packs
        Regional Settings File - XML file containing content to set the systems Regional and Language settings. Must be in the format en-GB.xml or de-DE.xml and in the same location as LPtoFODFile.
                                 https://docs.microsoft.com/en-us/troubleshoot/windows-client/deployment/automate-regional-language-settings

                                 When creating or modifying the Regional settings file, the following sources are useful
                                 https://docs.microsoft.com/en-gb/windows/win32/intl/table-of-geographical-locations
                                 https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/default-input-locales-for-windows-language-packs

    .VERSION

        Written By: Paul Smith (New Signature UK)        
        Script Ver: 1.0.0 (30-10-2020)
        
    .PARAMETER LanguageCode (Required)
    This is the language codes to include. The first parameter is used as the systems default language. The parameter will only allow valid codes.
    The LPtoFODFile CSV file must contain the necessary 

    .PARAMETER PathToLookupCSVs (Required)
    This is the path to the root of a folder containing the 2 CSV control files. Any SMB location should work

    .PARAMETER WindowsVersion (Optional)
    This specifies which Windows build (1903, 1909, 2004 etc.) to install language packs for. The parameter will only allow valid codes.
    If specified it overwrites the built-in logic that identifies the current Windows version. Intended for testing script logic and wouldn't normally be used.
    
    .PARAMETER PathToISOs (Required)
    This is the path to the root of a folder that will contain or store the ISO files. Any SMB location should work
    If the desired ISO do not already exist in this location, the script will download it

    .PARAMETER LPtoFODFile (Optional)
    This is the CSV file listing the FOD file names to language and Windows build. Defaults to looking for Windows-10-FOD-to-LP-Mapping-Table.csv

    .PARAMETER ISOLookupFile (Optional)
    This is the CSV file listing the URLs to download the Language and FOD ISO files for each Windows version. Defaults to looking for Windows-10-FOD-and-LP-Source-ISO.csv

    .PARAMETER TimeZoneName (Optional)
    Specify the Time Zone. Defaults to setting GMT Standard Time
    Available options listed on https://support.microsoft.com/en-gb/help/973627/microsoft-time-zone-index-values
    
    .EXAMPLE
    Install-LanguagePacks -LanguageCode en-gb, fr-fr, de-de -WindowsVersion 2004 -PathToLookupCSVs "C:\Scripts" -PathToISOs "C:\Temp" -Verbose 

    .EXAMPLE
    Install-LanguagePacks -LanguageCode en-gb, de-de -PathToLookupCSVs "C:\Scripts" -PathToISOs "C:\Temp" -LPtoFODFile "file1.csv" -ISOLookupFile "file2.csv"

    #>

    [CmdletBinding()]

    Param (
        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [ValidateSet('en-gb','fr-fr','de-de')]
        [System.String[]]$LanguageCode,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,           
            Mandatory = $false
        )]
        [ValidateSet('1903','1909','2004','2009')]
        [System.String]$WindowsVersion,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [System.String]$PathToISOs,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [System.String]$PathToLookupCSVs,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$LPtoFODFile = "Windows-10-FOD-to-LP-Mapping-Table.csv",

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$ISOLookupFile = "Windows-10-FOD-and-LP-Source-ISO.csv",

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$TimeZoneName = "GMT Standard Time",

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.Boolean]$WhatIf = $true

    )

    BEGIN {
        
        Set-StrictMode -Version Latest

        #Requires -RunAsAdministrator

        Write-Output ((Get-Date -Format HH:mm:ss) + " - Begining language pack install for " + $LanguageCode.count + " languages")

        # Identify Windows Version
        $ComputerInfo = Get-ComputerInfo
        Write-Output ("Windows 10 version detected : " + $ComputerInfo.WindowsVersion)

        If($WindowsVersion -eq "")
        {            
            $WindowsVersion = $ComputerInfo.WindowsVersion.ToString()
        }
        else
        {            
            Write-Output ("Windows 10 version specified: " + $WindowsVersion)
            Write-Verbose "A command line paramater has specified a different Windows 10 version to that detected by the script. This is unexpected outside of script development"
        }

        # Set Default Language
        $DefaultLanguage = $LanguageCode[0]
        Write-Output ("The default language will be set to: $DefaultLanguage")

        # Check for FOD and LP ISO Lookup CSV file and read it
        if (Test-Path ("$PathToLookupCSVs\$ISOLookupFile"))
        {            
            $ISOLookup = Import-Csv -Path ("$PathToLookupCSVs\$ISOLookupFile") | Where-Object {$_.WindowsVersion -eq $WindowsVersion}
            Write-verbose ("LP and FOD ISO lookup file     : " + $PathToLookupCSVs+"\"+$ISOLookupFile)           
            $LP = @($ISOLookup | Where-Object {$_.ISOType -eq "LP"})
            $FOD = @($ISOLookup | Where-Object {$_.ISOType -eq "FOD"})
           
            # Check the import is as expected i.e. no more than 1 
            If(($LP -is [array]) -and ($LP.count -ne 1) -or ($LP -eq $null))
            {
                Write-Error ("An unexpected number of ISO files have been returned for use.`nLanguage Pack ISOs returned: " + $LP.count + " (Exprected 1)`nFeatures on Demand ISOs returned: " + $FOD.count + " (Expected 1)")
                exit
            }
        }
        else
        {
            Write-Error "Unable to access the LP and FoD ISO mapping file specified at $PathToLookupCSVs\$ISOLookupFile"
            exit
        }

        # Check for the LP to FOD CSV File and read it
        if (Test-Path ("$PathToLookupCSVs\$LPtoFODFile"))
        {
            $LPtoFOD = Import-Csv -Path ("$PathToLookupCSVs\$LPtoFODFile") | Where-Object {$_.WindowsVersion -eq $WindowsVersion}
            Write-verbose ("LP and FOD langauge file       : " + $PathToLookupCSVs+"\"+$LPtoFODFile)
        }
        else
        {
            Write-Error "Unable to access the LP and FoD language lookup file specified at $PathToLookupCSVs\$LPtoFODFile"
            exit
        }

        # Calculate ISO names and local sources
        $LPISOFileName = $LP.URL.Split("/")[($LP.URL.Split("/")).Count-1]      # Extract filename from URL string
        $FODISOFileName = $FOD.URL.Split("/")[($FOD.URL.Split("/")).Count-1]   # Extract filename from URL string
        
        if ($PathToISOs.Length -eq 0)
        {
            $LPISOFilePath = ".\" + $LPISOFileName
            $FODISOFilePath = ".\" + $FODISOFileName
        }
        else
        {
            $LPISOFilePath = $PathToISOs +"\" + $LPISOFileName
            $FODISOFilePath = $PathToISOs +"\" + $FODISOFileName
        }

        Write-Verbose ("Language Pack Windows Version  : " + $LP.WindowsVersion)
        Write-Verbose ("Language Pack download URL     : " + $LP.URL)
        Write-Verbose ("Language Pack ISO File Name    : " + $LPISOFileName)
        Write-Verbose ("Path to Language Pack ISO      : " + $LPISOFilePath)

        Write-Verbose ("Features on Demand Version     : " + $FOD.WindowsVersion)
        Write-Verbose ("Features on Demand URL         : " + $FOD.URL)
        Write-Verbose ("Features on Demand ISO File    : " + $FODISOFileName)
        Write-Verbose ("Path to Features on Demand ISO : " + $FODISOFilePath)

        # Check Regional Language Settings XML file exists for default language
        $RegionalSettingsXMLFile = "$PathToLookupCSVs\$DefaultLanguage.xml"
        if (Test-Path ($RegionalSettingsXMLFile))
        {            
            Write-Verbose ("Path to Regional Settings File : " + $RegionalSettingsXMLFile)
        }
        else
        {
            Write-Error ("Unable to access the Regional Settings XML file $RegionalSettingsXMLFile")
            exit
        }

        # Check ISO Folder Path Exists and create if necessary
        If(-not (Test-Path $PathToISOs))
        {
            Write-Output "Creating ISO folder: $PathToISOs"
            New-Item -ItemType Directory -Force -Path $PathToISOs | Out-Null
        }

        # Download Languages ISO (if not already present)
        If(-not (Test-Path $LPISOFilePath))
        {
            Write-Output ((Get-Date -Format HH:mm:ss) + " - Downloading Language Pack ISO for Windows 10 version " + $LP.WindowsVersion + " ...")               
            (New-Object System.Net.WebClient).DownloadFile($LP.URL, ($LPISOFilePath))       
        }
        else
        {
            Write-Output ("Language Pack ISO for Windows 10 version " + $LP.WindowsVersion + " already present. No need to download.")
        }

        # Download Features on Demand ISO (if not already present)
        If(-not (Test-Path $FODISOFilePath))
        {
            Write-Output ((Get-Date -Format HH:mm:ss) + " - Downloading Features on Demand ISO for Windows 10 version " + $FOD.WindowsVersion + " ...")
            (New-Object System.Net.WebClient).DownloadFile($FOD.URL, ($FODISOFilePath))
        }
        else
        {
            Write-Output ("Features on Demand ISO for Windows 10 version " + $LP.WindowsVersion + " already present. No need to download.")
        }

        # Disable Language Pack Cleanup## (do not re-enable)
        if(-not $WhatIf)
        {
            Write-Output "Disabling Scheduled Task - Pre-staged app cleanup"
            Disable-ScheduledTask -TaskPath "\Microsoft\Windows\AppxDeploymentClient\" -TaskName "Pre-staged app cleanup" | Out-Null
        }
        else
        {
            Write-Output "WhatIf - Disable Scheduled Task - Pre-staged app cleanup"
        }
              
    } # Begin
    PROCESS {

        foreach ($Language in $LanguageCode)
        {
            Write-Output ((Get-Date -Format HH:mm:ss) + " - Installing language code: $Language")
            #LP
            if(Test-Path $LPISOFilePath)
            {
                # Mount LP ISO
                Write-Output "Mounting Language Pack ISO"
                $ISO = Mount-DiskImage -ImagePath ("$LPISOFilePath") -PassThru      
                $DriveLetter = ($ISO | Get-Volume).DriveLetter + ":"
                Write-Output " -> Drive Letter: $DriveLetter"

                # Language Experience Pack
                $LanguageExperiencePackAppx = $DriveLetter + "\" + "LocalExperiencePack\" + $Language + "\LanguageExperiencePack." + $Language + ".Neutral.appx"
                $LanguageExperiencePackLicence = $DriveLetter + "\" + "LocalExperiencePack\" + $Language + "\License.xml"               
                Write-Verbose ("Install Language Experience APPX $LanguageExperiencePackAppx using licence file $LanguageExperiencePackLicence")               

                if((Test-Path $LanguageExperiencePackAppx) -and (Test-Path $LanguageExperiencePackLicence))
                {
                    if(-not $WhatIf)
                    {
                        Write-Output " -> Adding $Language Experience Pack Appx"
                        Add-AppProvisionedPackage -Online -PackagePath $LanguageExperiencePackAppx -LicensePath $LanguageExperiencePackLicence -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
                    }
                    else
                    {
                        Write-Output "WhatIf - Add-AppProvisionedPackage -Online -PackagePath $LanguageExperiencePackAppx -LicensePath $LanguageExperiencePackLicence"
                    }                    
                }
                else
                {
                    Write-Error "Unable to find Language Experience Pack files at the expected locations. `nAppx: $LanguageExperiencePackAppx `nLicense: $LanguageExperiencePackLicence"
                }

                # Language Pack
                $LanguagePack = $DriveLetter + "\x64\langpacks\Microsoft-Windows-Client-Language-Pack_x64_" + $Language +".cab"
                Write-Verbose ("Install Language Pack $LanguagePack")

                if(Test-Path $LanguagePack)
                {
                    if(-not $WhatIf)
                    {
                        Write-Output " -> Adding $Language Language Pack"
                        Add-WindowsPackage -Online -PackagePath $LanguagePack | Out-Null
                    }
                    else
                    {
                        Write-Output "WhatIf - Add-WindowsPackage -Online -PackagePath $LanguagePack"
                    }
                }
                else
                {
                    Write-Error "Unable to find $Language Language Pack at this location: $LanguagePack"
                }

                # Dismount Language ISO                Dismount-DiskImage -ImagePath ("$LPISOFilePath") | Out-Null                Write-Output "Dismounting Language Pack ISO"
            }
            else
            {
                Write-Output ("Language Pack ISO $LPISOFilePath not found.")
                exit
            }
        
            # Features on Demand
            if(Test-Path $FODISOFilePath)
            {
                # Mount LP ISO
                Write-Output "Mounting Features on Demand ISO"
                $ISO = Mount-DiskImage -ImagePath ("$FODISOFilePath") -PassThru      
                $DriveLetter = ($ISO | Get-Volume).DriveLetter + ":"
                Write-Output " -> Drive Letter: $DriveLetter"                

                # Select the files from the CSV applicable to the current language
                $CurrentLanguageCabFiles = $LPtoFOD.Where{$_.Language -eq $Language}
                if($CurrentLanguageCabFiles.count -eq 0)
                {
                    Write-Error "There are no Features on Demand CAB files specified in the CSV file for the $Language language"
                }
                else
                {
                    foreach ($CabFile in $CurrentLanguageCabFiles)
                    {
                        $CabFilePath = ($DriveLetter + "\" + $CabFile.FileName)                    
                        Write-Verbose ("Install Feature on Demand package $CabFilePath")
                        if(Test-Path $CabFilePath)
                        {
                            if(-not $WhatIf)
                            {                            
                                Write-Output " -> Adding $CabFilePath Package"
                                Add-WindowsPackage -Online -PackagePath $CabFilePath | Out-Null
                            }
                            else
                            {
                                Write-Output "WhatIf - Add-WindowsPackage -Online -PackagePath $CabFilePath"
                            }
                        }
                        else
                        {
                            Write-Error "Unable to find $CabFilePath at this location"
                        }                   
                    }

                    if(-not $WhatIf)
                    {                       
                        Write-Output " -> Adding $Language to OS Language List"   
                        $LanguageList = Get-WinUserLanguageList
                        $LanguageList.Add($Language)
                        Set-WinUserLanguageList $LanguageList -force
                    }              
                    else
                    {
                        Write-Output "WhatIf - Adding $Language to OS Language List"
                    }
                }

                # Dismount FOD ISO                Dismount-DiskImage -ImagePath ("$FODISOFilePath") | Out-Null                Write-Output "Dismounting Language Pack ISO"
                Write-Output ((Get-Date -Format HH:mm:ss) + " - Completed installing language code: $Language")
            }
            else
            {
                Write-Output ("Features on Demand ISO $FODISOFilePath not found.")
                exit
            }
        }        

        if(-not $WhatIf)
        {
            Write-Output ("Applying $DefaultLanguage as this systems default Regional Settings ...")
            Set-WinSystemLocale -SystemLocale $DefaultLanguage
            Set-Culture -CultureInfo $DefaultLanguage
            Set-WinUserLanguageList $DefaultLanguage -Force
            & $env:SystemRoot\System32\control.exe "intl.cpl,,/f:`"$RegionalSettingsXMLFile`""
            ##Set Timezone
            & tzutil /s "$TimeZoneName"
        }
        else
        {
            Write-Output "WhatIf - Applying $DefaultLanguage as this systems default Regional Settings ..."
            Write-Output "WhatIf - Set-WinSystemLocale -SystemLocale $DefaultLanguage"
            Write-Output "WhatIf - Set-Culture -CultureInfo $DefaultLanguage"
            Write-Output "WhatIf - Set-WinUserLanguageList $DefaultLanguage -Force"
            Write-Output ("WhatIf - $env:SystemRoot\System32\control.exe intl.cpl,,/f:`"$RegionalSettingsXMLFile`"")
            Write-Output ("WhatIf - tzutil /s `"$TimeZoneName`"")
        }        

        Write-Output ((Get-Date -Format HH:mm:ss) + " - Completed language pack install for " + $LanguageCode.count + " languages")
        Write-Output "Please Note: A system restart is required for these changes to take effect"

    } 
}  #function Install-LanguagePack