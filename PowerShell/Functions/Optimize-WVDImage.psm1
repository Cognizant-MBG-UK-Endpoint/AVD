function Optimize-WVDImage {
  
    <#
    .SYNOPSIS
    Function to perform an optimisation of a WVD master image

    .DESCRIPTION
    NOT YET COMPLETE
        
    .VERSION

        Written By: Paul Smith (New Signature UK)        
        Script Ver: 1.0.0 (02-11-2020)
           
    .PARAMETER TempDirectory (Required)
    Specify the folder containing the OneDrive binaries, or where to save the newly downloaded binaries to.

    .EXAMPLE
    Optimize-WVDImage -Optimiser Citrix -PathToResources "C:Scripts\Resources\Apply-WVDOptimisation" -TempDirectory "C:\Temp" -WhatIf $false

    .EXAMPLE    
    Optimize-WVDImage -Optimiser Citrix -PathToResources ("$ScriptPath\Resources\Apply-WVDOptimisation") -CitrixTemplate "Paul_Smith_DEMO_LAB_v1.0.xml" -TempDirectory $TempPath -WhatIf $true


    #>

    [CmdletBinding()]

    Param (

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [ValidateSet('Citrix','Microsoft','Manual')]
        [System.String[]]$Optimiser,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true            
        )]
        [System.String]$PathToResources,

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $false            
        )]
        [System.String]$CitrixTemplate = "Paul_Smith_LAB_Win10_2004_v1.0.xml",

        [Parameter(
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String]$TempDirectory,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [System.Boolean]$WhatIf = $true       
    )

    BEGIN {
        
        Set-StrictMode -Version Latest

        #Requires -RunAsAdministrator

        Write-Output ((Get-Date -Format HH:mm:ss) + " - Begining WVD Optimisation Process")

        # Create Temp Directory
        If(-not(Test-Path $TempDirectory))
        {
            Write-Verbose "Creating Temp Directory $TempDirectory"
            New-Item -ItemType Directory -Force -Path $TempDirectory | Out-Null        
        }

        if($Optimiser -eq "Citrix")
        {
            Write-Verbose ("Selected optimisation tool is Citrix")

            # Copy Citrix Optimiser locally
            if(Test-Path("$PathToResources\CitrixOptimizer"))
            {
                Write-Output ("Copying Citrix Optimiser tool locally")
                Write-Verbose ("Copying $PathToResources to $TempDirectory")
                Robocopy.exe "$PathToResources\CitrixOptimizer" "$TempDirectory\CitrixOptimizer" /MIR /LOG:"$TempDirectory\Robocopy-CitrixOptimizer.log"                                                   
            }
            else
            {
                Write-Error "The Citrix Optimiser tool cannot be found at the specified location. Unable to continue.`n -> Path: $PathToResources\CitrixOptimizer"
                exit
            }

            # Check the specified Template is available
            Write-Verbose ("Checking specified $CitrixTemplate template exists in $TempDirectory\CitrixOptimizer\Templates")            
            if(-not(Test-Path "$TempDirectory\CitrixOptimizer\Templates\$CitrixTemplate"))
            {
                Write-Error "The specifed Citrix Optimiser template file $CitrixTemplate cannot be found. Unable to continue.`n -> Path: $TempDirectory\CitrixOptimizer\Templates\$CitrixTemplate"
                exit
            }
        }
    
    } # Begin
    PROCESS {            if(-not $WhatIf)
        {            # CITRIX            if($Optimiser -eq "Citrix")
            {                    Write-Output "Executing Citrix Optimiser"                Write-Verbose (".`"$TempDirectory\CitrixOptimizer\CtxOptimizerEngine.ps1`" -Source `"$TempDirectory\CitrixOptimizer\Templates\$CitrixTemplate`" -Mode execute")                PowerShell ."$TempDirectory\CitrixOptimizer\CtxOptimizerEngine.ps1" -Source "$TempDirectory\CitrixOptimizer\Templates\$CitrixTemplate"  -Mode execute            }        }        else        {            # CITRIX            if($Optimiser -eq "Citrix")
            {                    Write-Output "WhatIf - Executing Citrix Optimiser"                Write-Verbose (".`"$TempDirectory\CitrixOptimizer\CtxOptimizerEngine.ps1`" -Source `"$TempDirectory\CitrixOptimizer\Templates\$CitrixTemplate`" -Mode execute")            }        }           Write-Output ((Get-Date -Format HH:mm:ss) + " - Completed WVD Optimisation Process")    }}