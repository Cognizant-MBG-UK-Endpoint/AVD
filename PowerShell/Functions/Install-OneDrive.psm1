function Install-OneDrive {
  
    <#
    .SYNOPSIS
    Function to install OneDrive in a WVD Environment.

    .DESCRIPTION
    This PowerShell function is designed to automate the installation of OneDrive.
        
    .VERSION

        Written By: Paul Smith (New Signature UK)        
        Script Ver: 1.0.0 (02-11-2020)
           
    .PARAMETER TempDirectory (Required)
    Specify the folder containing the OneDrive binaries, or where to save the newly downloaded binaries to.

    .PARAMETER Download (Optional)
    Automatically download the latest version from the internet, updating the existing file if one already exists. Defaults to enabled ($True).
    
    .PARAMETER OneDriveDownloadURL (Opional)
    Specifies the URL from where to download the latest WVD OneDriveSetup file from. Defaults to https://aka.ms/OneDriveWVD-Installer
    
    .PARAMETER OneDriveInstallerName (Optional)
    Specifies the filname to use for the OneDrive installer. Defaults to OneDriveSetup.exe

    .EXAMPLE
    Install-OneDrive -TempDirectory "C:\Temp" -WhatIf $false

    .EXAMPLE    
    Install-OneDrive -TempDirectory "C:\Temp" -Download $false -WhatIf $true -Verbose

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
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String]$TempDirectory,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$OneDriveDownloadURL = "https://aka.ms/OneDriveWVD-Installer",

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$OneDriveInstallerName = "OneDriveSetup.exe",

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.Boolean]$WhatIf = $true       
    )

    BEGIN {
        
        Set-StrictMode -Version Latest

        #Requires -RunAsAdministrator        Write-Output ((Get-Date -Format HH:mm:ss) + " - Begining OneDrive Install")        Write-Verbose "Download: $Download"        
        Write-Verbose "TempDirectory: $TempDirectory"        Write-Verbose "OneDrive Download URL: $OneDriveDownloadURL"        Write-Verbose "OneDrive Installer Name: $OneDriveInstallerName"        If(-not(Test-Path $TempDirectory))
        {
            Write-Verbose "Creating Temp Directory $TempDirectory"
            New-Item -ItemType Directory -Force -Path $TempDirectory | Out-Null        
        }        # Determine if to download or use existing files
        If((-not($Download)) -and ((-not(Test-Path ("$TempDirectory\$OneDriveInstallerName")))))
        {
             Write-Error ("The required installation files are not in the specified location $TempDirectory and downloading the latest versions is currently disabled.`nLooking for:`n -> $TempDirectory\$OneDriveInstallerName")
             exit
        }
        elseIf((-not($Download)) -and (((Test-Path ("$TempDirectory\$OneDriveInstallerName")))))
        {
            Write-Output "Using exiting $OneDriveInstallerName installation file located in $TempDirectory"
        }
        elseIf($Download)
        {
            Write-Output "Downloading the latest OneDrive WVD Installer"
            Write-Verbose "Downloading $OneDriveDownloadURL to $TempDirectory\$OneDriveInstallerName"
            (New-Object System.Net.WebClient).DownloadFile($OneDriveDownloadURL, ("$TempDirectory\$OneDriveInstallerName"))
        }
        else
        {
            Write-Error ("I'm not sure why the script ended up here so I'm gonna exit. Something must have gone wrong and I've not coded for this eventuality")
            exit
        }           
    } # Begin
    PROCESS {        if(-not $WhatIf)        {            # Uninstall existing built-in OneDrive            Write-Output "Removing the existing builtin OneDrive client"            Write-Verbose "Start-Process `"$TempDirectory\$OneDriveInstallerName`" -ArgumentList `"/uninstall`" -Wait"            Start-Process "$TempDirectory\$OneDriveInstallerName" -ArgumentList "/uninstall" -Wait            # Install WVD OneDrive per-machine            Write-Output "Installing OneDrive in Per-Machine Mode for WVD"                       Write-Verbose "New-Item -Path `"HKLM:\Software\Microsoft`" -Name `"OneDrive`" -FORCE | Out-Null"            Write-Verbose "New-ItemProperty -Path `"HKLM:\Software\Microsoft\OneDrive`" -Name `"AllUsersInstall`" -Value `"1`" -PropertyType `"DWORD`" -FORCE | Out-Null"            Write-Verbose "Start-Process `"$TempDirectory\$OneDriveInstallerName`" -ArgumentList `"/allusers /silent`" -Wait"            New-Item -Path "HKLM:\Software\Microsoft" -Name "OneDrive" -FORCE | Out-Null            New-ItemProperty -Path "HKLM:\Software\Microsoft\OneDrive" -Name "AllUsersInstall" -Value "1" -PropertyType "DWORD" -FORCE | Out-Null            Start-Process "$TempDirectory\$OneDriveInstallerName" -ArgumentList "/allusers /silent" -Wait            # Start OneDrive for All Users            Write-Output "Enabling OneDrive for All Users"            Write-Verbose "New-ItemProperty -Path `"HKLM:\Software\Microsoft\Windows\CurrentVersion\Run`" -Name `"OneDrive`" -Value `"C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe /background`" -PropertyType `"STRING`" -FORCE | Out-Null"            New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -Value "C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe /background" -PropertyType "STRING" -FORCE | Out-Null            Write-verbose "Note: OneDrive configuration settings such as KFM, Silent Configuration etc. will need to be controlled by GPO"                    }        else
        {            Write-Output "WhatIf - Removing the existing builtin OneDrive client"            Write-Verbose "Start-Process `"$TempDirectory\$OneDriveInstallerName`" -ArgumentList `"/uninstall`" -Wait"                Write-Output "WhatIf - Installing OneDrive in Per-Machine Mode for WVD"                       Write-Verbose "New-Item -Path `"HKLM:\Software\Microsoft`" -Name `"OneDrive`" -FORCE | Out-Null"            Write-Verbose "New-ItemProperty -Path `"HKLM:\Software\Microsoft\OneDrive`" -Name `"AllUsersInstall`" -Value `"1`" -PropertyType `"DWORD`" -FORCE | Out-Null"            Write-Verbose "Start-Process `"$TempDirectory\$OneDriveInstallerName`" -ArgumentList `"/allusers /silent`" -Wait"            Write-Output "WhatIf - Enabling OneDrive for All Users"            Write-Verbose "New-ItemProperty -Path `"HKLM:\Software\Microsoft\Windows\CurrentVersion\Run`" -Name `"OneDrive`" -Value `"C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe /background`" -PropertyType `"STRING`" -FORCE | Out-Null"            Write-verbose "Note: OneDrive configuration settings such as KFM, Silent Configuration etc. will need to be controlled by GPO"                    }        Write-Output ((Get-Date -Format HH:mm:ss) + " - Completed OneDrive Install")    }}