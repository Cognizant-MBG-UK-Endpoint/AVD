function Install-Teams {
  
    <#
    .SYNOPSIS
    Function to install Teams in a WVD Environment.

    .DESCRIPTION
    This PowerShell function is designed to automate the installation of Teams.
    This script will automatically download the latest version of 
    
    .VERSION

        Written By: Paul Smith (New Signature UK)        
        Script Ver: 1.0.0 (30-10-2020)
           
    .PARAMETER TempDirectory (Required)
    Specify the folder containing the Teams binaries, or where to save the newly downloaded binaries to.

    .PARAMETER Download (Optional)
    Automatically download the latest version from the internet, updating the existing file if one already exists. Defaults to enabled ($True).

    .PARAMETER Architecture (Optional)
    Specifies which architecture Teams client to install 32-bit or 64-bit. Defaults to 64-bit.

    .PARAMETER VisualCPlusPlusDownloadURLx64 (Optional)
    URL to download the latest Visual C++ runtime from. Defaults to https://aka.ms/vs/16/release/vc_redist.x64.exe

    .PARAMETER TeamsWVDDownloadURLx86 (Optional)
    URL to download the latest 32-bit version of the WVD Teams installer. Defaults to https://statics.teams.cdn.office.net/production-windows/1.3.00.21759/Teams_windows.msi

    .PARAMETER TeamsWVDDownloadURLx64 (Optional)
    URL to download the latest 64-bit version of the WVD Teams installer. Defaults to https://statics.teams.cdn.office.net/production-windows-x64/1.3.00.21759/Teams_windows_x64.msi

    .PARAMETER TeamsWebSocketServiceDownloadURL (Optional)
    URL to download the latest Teams WebSocket Service from. Defaults to https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4AQBt

    .PARAMETER InstallerLogFilePath (Optional)
    Path to save insterller log files. Defaults to $env:TEMP\TeamsInstall

    .EXAMPLE
    Install-Teams -TempDirectory C:\TEMP -WhatIf $false

    .EXAMPLE    
    Install-Teams -Download $false -Architecture '32-Bit' -TempDirectory C:\TEMP -WhatIf $false

    #>

    [CmdletBinding()]

    Param (

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $false
        )]
        [System.Boolean]$Download = $true,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,           
            Mandatory = $false
        )]
        [ValidateSet('32-Bit', '64-Bit')]
        [System.String]$Architecture="64-Bit",

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String]$TempDirectory,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$VisualCPlusPlusDownloadURLx64 = "https://aka.ms/vs/16/release/vc_redist.x64.exe",

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$TeamsWVDDownloadURLx86 = "https://statics.teams.cdn.office.net/production-windows/1.3.00.21759/Teams_windows.msi",

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$TeamsWVDDownloadURLx64 = "https://statics.teams.cdn.office.net/production-windows-x64/1.3.00.21759/Teams_windows_x64.msi",

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$TeamsWebSocketServiceDownloadURL = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4AQBt",

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$TeamsWebSocketServiceInstallerName = "MsRdcWebRTCSvc_HostSetup_1.0.2006.11001_x64.msi",          
        
        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$InstallerLogFilePath = ("$env:TEMP\TeamsInstall"),                   

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.Boolean]$WhatIf = $true        

    )

    BEGIN {
        
        Set-StrictMode -Version Latest

        #Requires -RunAsAdministrator

        Write-Output ((Get-Date -Format HH:mm:ss) + " - Begining Teams Install")

        Write-Verbose "Download: $Download"
        Write-Verbose "Architecture: $Architecture"
        Write-Verbose "TempDirectory: $TempDirectory"
        Write-Verbose "Visual C++ runtimes download URL: $VisualCPlusPlusDownloadURLx64"
        Write-Verbose "Teams WebSocket Service download URL: $TeamsWebSocketServiceDownloadURL"

        # Calculate file names

        if($Architecture -eq "32-Bit")
        {
            $TeamsWVDDownloadURL = $TeamsWVDDownloadURLx86
        }

        if($Architecture -eq "64-Bit")
        {           
            $TeamsWVDDownloadURL = $TeamsWVDDownloadURLx64
        }

        $TeamsInstallerName = $TeamsWVDDownloadURL.Split("/")[($TeamsWVDDownloadURL.Split("/")).Count-1] # Extract filename from URL string                      
        $VisualCPlusPlusInstallerName = $VisualCPlusPlusDownloadURLx64.Split("/")[($VisualCPlusPlusDownloadURLx64.Split("/")).Count-1] # Extract filename from URL string

        Write-Verbose "Teams VVD installer download URL : $TeamsWVDDownloadURL"
        Write-Verbose "Visual C++ Installer File Name: $VisualCPlusPlusInstallerName"
        Write-Verbose "Teams WebSocket Service Installer File Name: $TeamsWebSocketServiceInstallerName"
        Write-Verbose "Teams WVD Installer File Name: $TeamsInstallerName"

        If(-not(Test-Path $TempDirectory))
        {
            Write-Verbose "Creating Temp Directory $TempDirectory"
            New-Item -ItemType Directory -Force -Path $TempDirectory | Out-Null        
        }

        # Determine if to download or use existing files
        If((-not($Download)) -and ((-not(Test-Path ("$TempDirectory\$VisualCPlusPlusInstallerName"))) -or (-not(Test-Path ("$TempDirectory\$TeamsWebSocketServiceInstallerName"))) -or (-not(Test-Path ("$TempDirectory\$TeamsInstallerName")))))
        {
             Write-Error ("The required installation files are not in the specified location $TempDirectory and downloading the latest versions is currently disabled.`nLooking for:`n -> $TempDirectory\$VisualCPlusPlusInstallerName`n -> $TempDirectory\$TeamsWebSocketServiceInstallerName`n -> $TempDirectory\$TeamsInstallerName")
             exit
        }
        elseIf((-not($Download)) -and (((Test-Path ("$TempDirectory\$VisualCPlusPlusInstallerName"))) -and ((Test-Path ("$TempDirectory\$TeamsWebSocketServiceInstallerName"))) -and ((Test-Path ("$TempDirectory\$TeamsInstallerName")))))
        {
            Write-Output "Using exiting installation files located in $TempDirectory"
        }
        elseIf($Download)
        {
            Write-Output "Downloading Visual C++ Redistributable Runtimes"
            Write-Verbose "Downloading $VisualCPlusPlusDownloadURLx64 to $TempDirectory\$VisualCPlusPlusInstallerName"
            (New-Object System.Net.WebClient).DownloadFile($VisualCPlusPlusDownloadURLx64, ("$TempDirectory\$VisualCPlusPlusInstallerName"))

            Write-Output "Downloading Teams WebSocket Service"
            Write-Verbose "Downloading $TeamsWebSocketServiceDownloadURL to $TempDirectory\$TeamsWebSocketServiceInstallerName"
            (New-Object System.Net.WebClient).DownloadFile($TeamsWebSocketServiceDownloadURL, ("$TempDirectory\$TeamsWebSocketServiceInstallerName"))

            Write-Output "Downloading Teams WVD installer"
            Write-Verbose "Downloading $TeamsWVDDownloadURL to $TempDirectory\$TeamsInstallerName"                                   
            (New-Object System.Net.WebClient).DownloadFile($TeamsWVDDownloadURL, ("$TempDirectory\$TeamsInstallerName"))
        }
        else
        {
            Write-Error ("I'm not sure why the script ended up here so I'm gonna exit. Something must have gone wrong and I've not coded for this eventuality")
            exit
        }

    } # Begin
    PROCESS {
                if(-not $WhatIf)        {             # Create Registry Keys                       Write-Verbose "Creating registry keys so Teams identifies this system as a WVD environment"            New-Item -Path "HKLM:\Software\Microsoft" -Name "Teams" -FORCE | Out-Null            New-ItemProperty -Path "HKLM:\Software\Microsoft\Teams" -Name "IsWVDEnvironment" -Value "1" -PropertyType "DWORD" -FORCE | Out-Null        
            
            # Install C++
            Write-Output "Installing C++ 2015-2019 Redistributable"
            Write-Verbose "Start-Process `"$TempDirectory\$VisualCPlusPlusInstallerName`" -ArgumentList `"/quiet /norestart /log $InstallerLogFilePath\vc_redist.x64.log`" -wait"
            Start-Process ("$TempDirectory\$VisualCPlusPlusInstallerName") -ArgumentList "/quiet /norestart /log $InstallerLogFilePath\vc_redist.x64.log" -wait
            
            # Install Teams WebSocket Service
            Write-Output "Installing Teams Websocket Service"
            Write-Verbose "Start-Process msiexec.exe -ArgumentList `"/i `"$TempDirectory\$TeamsWebSocketServiceInstallerName`" /qn /l*v $InstallerLogFilePath\TeamsWebSocketService.log`" -wait"
            Start-Process msiexec.exe -ArgumentList "/i `"$TempDirectory\$TeamsWebSocketServiceInstallerName`" /qn /l*v $InstallerLogFilePath\TeamsWebSocketService.log" -wait

            # Install Teams
            Write-Output "Installing Teams Machine-Wide Installer"
            Write-Verbose "Start-Process msiexec.exe -ArgumentList `"/i `"$TempDirectory\$TeamsInstallerName`" ALLUSER=1 ALLUSERS=1 /qn /l*v $InstallerLogFilePath\Teams.log`" -wait"
            Start-Process msiexec.exe -ArgumentList "/i `"$TempDirectory\$TeamsInstallerName`" ALLUSER=1 ALLUSERS=1 /qn /l*v $InstallerLogFilePath\Teams.log" -wait
        }
        else
        {
            Write-Output "WhatIf - Create registry keys so Teams identifies this system as a WVD environment"
            Write-Output "WhatIf - Installing C++ 2015-2019 Redistributable"           
            Write-Verbose "Start-Process `"$TempDirectory\$VisualCPlusPlusInstallerName`" -ArgumentList `"/quiet /norestart /log $InstallerLogFilePath\vc_redist.x64.log`" -wait"
            
            Write-Output "WhatIf - Installing Teams Websocket Service"            
            Write-Verbose "Start-Process msiexec.exe -ArgumentList `"/i `"$TempDirectory\$TeamsWebSocketServiceInstallerName`" /qn /l*v $InstallerLogFilePath\TeamsWebSocketService.log`" -wait"
            
            Write-Output "WhatIf - Installing Teams Machine-Wide Installer"
            Write-Verbose "Start-Process msiexec.exe -ArgumentList `"/i `"$TempDirectory\$TeamsInstallerName`" ALLUSER=1 ALLUSERS=1 /qn /l*v $InstallerLogFilePath\Teams.log`" -wait"
        }
    
        Write-Output ((Get-Date -Format HH:mm:ss) + " - Completed Teams Install")
    }
}