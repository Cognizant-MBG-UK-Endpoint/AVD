function Install-FSLogix {
  
    <#
    .SYNOPSIS
    Function to install FSLogix.

    .DESCRIPTION
    This PowerShell function is designed to automate the installation of FSLogix.
    This script will automatically download the latest version, unless using a specific version is specified.
    
    .VERSION

        Written By: Paul Smith (New Signature UK)        
        Script Ver: 1.0.0 (30-10-2020)
           
    .PARAMETER PathToZipFile (Required)
    Specify the folder containing the FSLogix ZIP file, or where to save the newly downloaded ZIP file.

    .PARAMETER Download (Options)
    Automatically download the latest version from the internet, updating the existing file if one already exists. Defaults to enabled ($True).

    .PARAMETER ZipFileName (Otional)
    The name to use for the downloaded ZIP file. Defaults to fslogix.zip.
    
    .PARAMETER DownloadURL (Optional)
    The URL from where to download the latest FSLogix ZIP file. Defaults to https://aka.ms/fslogix_download

    .PARAMETER TempDirectory (Optional)
    The location where the FSLogix ZIP file will extracted. Defaults to %TEMP%

    .PARAMETER IncludeAppsRuleEditor (Optional)
    Specify if to include the FSLogix Apps Rules Editor during the install. Defaults to disabled ($false).

    .PARAMETER IncludeAppsJavaRuleEditor (Optional)
    Specify if to include the FSLogix Apps Java Rules Editor during the install. Defaults to disabled ($false).

    .PARAMETER Cleanup (Optional)
    Instruct the script to delete the contents of the TempDirectory once finished. Defaults to disabled ($false).

    .EXAMPLE
    Install-FSLogix -PathToZipFile "C:\TEMP" -IncludeAppsRuleEditor $true -IncludeAppsJavaRuleEditor $true -Cleanup $true -WhatIf $false

    .EXAMPLE    
    Install-FSLogix -PathToZipFile "C:\TEMP" -Download $false -IncludeAppsRuleEditor $false -IncludeAppsJavaRuleEditor $false -Cleanup $true -Verbose

    #>

    [CmdletBinding()]

    Param (

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true
        )]
        [System.Boolean]$Download = $true,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String]$PathToZipFile,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$ZipFileName = "fslogix.zip",

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$DownloadURL = "https://aka.ms/fslogix_download",

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$TempDirectory = ("$env:TEMP\FSLogix"),

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.Boolean]$IncludeAppsRuleEditor = $false,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.Boolean]$IncludeAppsJavaRuleEditor = $false,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.Boolean]$Cleanup = $false,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.Boolean]$WhatIf = $true

    )

    BEGIN {
        
        Set-StrictMode -Version Latest

        #Requires -RunAsAdministrator

        Write-Output ((Get-Date -Format HH:mm:ss) + " - Begining FSLogix Install")

        $FSLogixZip = $PathToZipFile + "\" + $ZipFileName

        Write-Verbose "PathToZipFile: $PathToZipFile"        
        Write-Verbose "ZipFileName:   $ZipFileName"        
        Write-Verbose "FSLogixZip:    $FSLogixZip"  
        Write-Verbose "TempDirectory: $TempDirectory"
        Write-Verbose "Download:      $Download"
        Write-Verbose "IncludeAppsRuleEditor:     $IncludeAppsRuleEditor"
        Write-Verbose "IncludeAppsJavaRuleEditor: $IncludeAppsJavaRuleEditor"

        # Create TempDirectory if not exist
        If(-not(Test-Path $TempDirectory))
        {
            Write-Verbose "Creating Temp Directory $TempDirectory"
            New-Item -ItemType Directory -Force -Path $TempDirectory | Out-Null        
        }

        # Determine if to download or use the existing copy
        If(-not(Test-Path ($FSLogixZip)) -and (-not($Download)))
        {
             Write-Error ("An existing FSlogix ZIP file cannot be found at the specified location $FSLogixZip and auto downloading the latest version is currently disabled.")
             exit
        }
        elseIf(-not(Test-Path ($FSLogixZip)) -and ($Download))
        {
            Write-Output "Creating FSLogix folder: $PathToZipFile"
            New-Item -ItemType Directory -Force -Path $PathToZipFile | Out-Null        

            Write-Output ("Downloading the latest version of FSLogix")
            (New-Object System.Net.WebClient).DownloadFile($DownloadURL, ($FSLogixZip))
        }
        elseIf((Test-Path ($FSLogixZip)) -and (-not($Download)))
        {
            Write-Output "Using an already downloaded version of FSLogix from $FSLogixZip" 
        }
        else
        {
            Write-Output "Downloading the latest version of FSLogix, replacing the existing one found in $FSLogixZip"
            (New-Object System.Net.WebClient).DownloadFile($DownloadURL, ($FSLogixZip))
        }       

    } # Begin
    PROCESS {

        Write-Output "Expanding ZIP file..."
        Write-Verbose "Expanding $FSLogixZip to $TempDirectory"
        Expand-Archive -Path ($FSLogixZip) -DestinationPath ($TempDirectory) -Force

        # Install FSLogix
        Write-Output "Installing FSLogix"                if(-not $WhatIf)        {            Start-Process "$TempDirectory\x64\Release\FSLogixAppsSetup.exe" -ArgumentList "/quiet /norestart" -wait        }        else        {            Write-Output "WhatIf - Start-Process `"$TempDirectory\x64\Release\FSLogixAppsSetup.exe`" -ArgumentList `"/quiet /norestart`" -wait"        }
        # FSLogix Apps Rules Editor
        if($IncludeAppsRuleEditor)
        {
            Write-Output "Installing FSLogix Apps Rules Editor"

            if(-not $WhatIf)            {
                Start-Process "$TempDirectory\x64\Release\FSLogixAppsRuleEditorSetup.exe" -ArgumentList "/quiet /norestart" -wait
            }
            else
            {
                Write-Output "WhatIf - Start-Process `"$TempDirectory\x64\Release\FSLogixAppsRuleEditorSetup.exe`" -ArgumentList `"/quiet /norestart`" -wait"
            }
        }
        else
        {
            Write-Verbose "Skipping the install of FSLogix Apps Rules Editor"
        }

        # FSLogix Java Apps Rules Editor
        if($IncludeAppsJavaRuleEditor)
        {
            Write-Output "Installing FSLogix Java Apps Rules Editor"

            if(-not $WhatIf)            {
                Start-Process "$TempDirectory\x64\Release\FSLogixAppsJavaRuleEditorSetup.exe" -ArgumentList "/quiet /norestart" -wait
            }
            else
            {
                Write-Output "WhatIf - Start-Process `"$TempDirectory\x64\Release\FSLogixAppsJavaRuleEditorSetup.exe`" -ArgumentList `"/quiet /norestart`" -wait"
            }
        }
        else
        {
            Write-Verbose "Skipping the install of FSLogix Java Apps Rules Editor"
        }

        if($Cleanup)
        {
            Write-Output "Cleaning up (deleting) extrated ZIP file contents from $TempDirectory"
                        if(-not $WhatIf)            {
                Remove-Item "$TempDirectory" -Recurse -Force
            }
            else
            {
                Write-Output "WhatIf - Remove-Item `"$TempDirectory`" -Recurse -Force"
            }
        }

    Write-Output ((Get-Date -Format HH:mm:ss) + " - Completed FSLogix Install")
    }
}
