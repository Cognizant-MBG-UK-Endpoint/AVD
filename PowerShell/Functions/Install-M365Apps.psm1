function Install-M365Apps {
  
    <#
    .SYNOPSIS
    Function to install Office AKA M365 Apps in a WVD Environment.

    .DESCRIPTION
    This PowerShell function is designed to automate the installation of Office.
        
    .VERSION

        Written By: Paul Smith (New Signature UK)        
        Script Ver: 1.0.0 (02-11-2020)
           
    .PARAMETER PathToODT (Required)
    Specify the root folder containing the Office Deployment tool and configuration files.

    .PARAMETER TempDirectory (Required)
    Specify the local TempDirectory to use. e.g. C:\Temp.

    .PARAMETER XmlConfigFile (Optional)
    Specify the XML file to use when installing Office. Defaults to using WVD-MonthlyEnterprise-x64.xml

    .PARAMETER Download (Optional)
    Automatically download and use the latest version of the Office Deployment tool from the internet. Defaults to enabled ($True).
    
    .PARAMETER ODTDownloadURL (Opional)
    Specifies the URL from where to download the latest Office Deployment Tool from. Defaults to https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_13328-20292.exe
    

    .EXAMPLE
    Install-M365Apps -PathToODT "C:\Script\PowerShell\Resources\Install-M365Apps" -TempDirectory C:\Temp -WhatIf $false

    .EXAMPLE    
    Install-M365Apps -Download $false -PathToODT "C:\Script\PowerShell\Resources\Install-M365Apps" -TempDirectory C:\Temp -Verbose -WhatIf $false
     
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
        [System.String]$PathToODT,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $false
        )]
        [System.String]$XmlConfigFile = "WVD-MonthlyEnterprise-x64.xml",

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $false
        )]
        [System.String]$WVDUserProfileConfigCmdFileName = "ConfigureOffice.cmd",

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String]$TempDirectory,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.String]$ODTDownloadURL = "https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_13328-20292.exe",

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.Boolean]$WhatIf = $true       
    )

    BEGIN {
        
        Set-StrictMode -Version Latest

        ##Requires -RunAsAdministrator
        Write-Verbose "Download: $Download"
        Write-Verbose "ODT Download URL: $ODTDownloadURL"
        Write-Verbose "ODT Installer Name: $ODTInstallerName"
        Write-Verbose "ODT setup.exe: $ODTSetupExe"
        {
            Write-Verbose "Creating Temp Directory $TempDirectory"
            New-Item -ItemType Directory -Force -Path $TempDirectory | Out-Null                  
        }
        {
            Write-Verbose "Creating DeploymentTool Directory $TempDirectory\DeploymentTool"
            New-Item -ItemType Directory -Force -Path ("$TempDirectory\DeploymentTool") | Out-Null      
        if($Download)
        {
            Write-Output "Downloading the Office Deployment Tool (rather than using an existing copy)"
            Write-Verbose "Downloading $ODTDownloadURL to $TempDirectory\$ODTInstallerName"
            (New-Object System.Net.WebClient).DownloadFile($ODTDownloadURL, ("$TempDirectory\$ODTInstallerName"))
            Write-Output "Extracting setup.exe from the Office Deployment Tool"
            Write-Verbose "Extracting $TempDirectory\$ODTInstallerName to $TempDirectory\DeploymentTool"
            Start-Process ("$TempDirectory\$ODTInstallerName") -ArgumentList "/Extract:`"$TempDirectory\DeploymentTool`" /quiet" -wait
            $ODTSetupExe = "$TempDirectory\DeploymentTool\setup.exe"
            Write-Verbose "ODT setup.exe: $ODTSetupExe (Path Updated)"
        }
        elseIf((-not($Download)) -and ((-not(Test-Path ("$ODTSetupExe")))))
        {
             Write-Error ("The Office Deployment tool in not avaialable in the specified location and downloading the latest versions is currently disabled.`nLooking for:`n -> $ODTSetupExe")
             exit
        }
        elseIf((-not($Download)) -and ((Test-Path ("$ODTSetupExe"))))
        {
            Write-Output "Using exiting ODT file located in $ODTSetupExe"
            Write-Verbose "Copying deployment tool from $ODTSetupExe to $TempDirectory\DeploymentTool\setup.exe"
            Copy-Item -Path $ODTSetupExe -Destination ("$TempDirectory\DeploymentTool") -Force | Out-Null
            $ODTSetupExe = "$TempDirectory\DeploymentTool\setup.exe"
            Write-Verbose "ODT setup.exe: $ODTSetupExe (Path Updated)"
        }
        else
        {
            Write-Error ("I'm not sure why the script ended up here so I'm gonna exit. Something must have gone wrong and I've not coded for this eventuality")
            exit
        }        
             exit            
             exit            
    PROCESS {