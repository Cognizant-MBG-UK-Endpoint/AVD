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

        ##Requires -RunAsAdministrator        Write-Output ((Get-Date -Format HH:mm:ss) + " - Begining M365 Apps for Enterprise (Office 365 Client) Install")        $ODTSetupExe = "$PathToODT\DeploymentTool\setup.exe"        $ODTXmlFile = "$PathToODT\Configs\$XmlConfigFile"        $WVDUserProfileConfigPath = "$PathToODT\Configs"         $WVDUserProfileConfigCmd = "$WVDUserProfileConfigPath\$WVDUserProfileConfigCmdFileName"        $ODTInstallerName = $ODTDownloadURL.Split("/")[($ODTDownloadURL.Split("/")).Count-1]         Write-Verbose "TempDirectory: $TempDirectory"
        Write-Verbose "Download: $Download"
        Write-Verbose "ODT Download URL: $ODTDownloadURL"
        Write-Verbose "ODT Installer Name: $ODTInstallerName"
        Write-Verbose "ODT setup.exe: $ODTSetupExe"        Write-Verbose "ODT XML file to use: $ODTXmlFile"               Write-Verbose "User profile configuration script: $WVDUserProfileConfigCmd"        If(-not(Test-Path $TempDirectory))
        {
            Write-Verbose "Creating Temp Directory $TempDirectory"
            New-Item -ItemType Directory -Force -Path $TempDirectory | Out-Null                  
        }        If(-not(Test-Path ("$TempDirectory\DeploymentTool")))
        {
            Write-Verbose "Creating DeploymentTool Directory $TempDirectory\DeploymentTool"
            New-Item -ItemType Directory -Force -Path ("$TempDirectory\DeploymentTool") | Out-Null              }        # Determine if to download or use existing ODT
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
        }                        # Check that the specified XML File is present         If(-not(Test-Path $ODTXmlFile))        {             Write-Error ("The XML file specified to control the Office installation cannot be found. Unable to continue:`n -> $ODTXmlFile")
             exit                    }        # Check that the specified Profile Config File is present         If(Test-Path $WVDUserProfileConfigCmd)        {            Write-Verbose "Copying $WVDUserProfileConfigCmdFileName from $WVDUserProfileConfigPath to $TempDirectory\DeploymentTool"            Copy-Item -Path $WVDUserProfileConfigCmd -Destination ("$TempDirectory\DeploymentTool") -Force | Out-Null                        $WVDUserProfileConfigCmd = "$TempDirectory\DeploymentTool\$WVDUserProfileConfigCmdFileName"            Write-Verbose "User profile configuration script: $WVDUserProfileConfigCmd (Path Updated)"        }        else        {             Write-Error ("The User profile configuration script specified cannot be found. Unable to continue:`n -> $WVDUserProfileConfigCmdFile")
             exit                    }    } # Begin
    PROCESS {        if(-not $WhatIf)        {            Write-Output "Installing M365 Apps..."            Write-Verbose "Start-Process `"$ODTSetupExe`" -ArgumentList `"/configure $ODTXmlFile`" -Wait"            Start-Process "$ODTSetupExe" -ArgumentList "/configure $ODTXmlFile" -Wait            Write-Output "Configuring default user profile"            Write-Verbose "Start-Process `"$WVDUserProfileConfigCmd`" -Wait"            Start-Process "$WVDUserProfileConfigCmd" -Wait        }        else        {            Write-Output "WhatIf - Installing M365 Apps..."            Write-Verbose "Start-Process `"$ODTSetupExe`" -ArgumentList `"/configure $ODTXmlFile`" -Wait"            Write-Output "WhatIf - Configuring default user profile"            Write-Verbose "Start-Process `"$WVDUserProfileConfigCmd`" -Wait"        }        Write-Output ((Get-Date -Format HH:mm:ss) + " - Completed M365 Apps for Enterprise (Office 365 Client) Install")    }}