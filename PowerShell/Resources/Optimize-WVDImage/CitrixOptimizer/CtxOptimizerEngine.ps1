<#
.SYNOPSIS
    Citrix Optimization Engine helps to optimize operating system to run better with XenApp or XenDesktop solutions.

.DESCRIPTION
    Citrix Optimization Engine helps to optimize operating system to run better with XenApp or XenDesktop solutions. This script can run in three different modes - Analyze, Execute and Rollback. Each execution will automatically generate an XML file with a list of performed actions (stored under .\Logs folder) that can be used to rollback the changes applied. 

.PARAMETER Source
    Source XML file that contains the required configuration. Typically located under .\Templates folder. This file provides instructions that CTXOE can process. Template can be specified with or without .xml extension and can be full path or just a filename. If you specify only filename, template must be located in .\Templates folder.
    If -Source or -Template is not specified, Optimizer will automatically try to detect the best suitable template. It will look in .\Templates folder for file called <templateprefix>_<OS>_<build>. See help for -templateprefix to learn more about using your own custom templates.

.PARAMETER TemplatePrefix
    When -Source or -Template parameter is not specified, Optimizer will try to find the best matching template automatically. By default, it is looking for templates that start with "Citrix_Windows" and are provided by Citrix as part of default Optimizer build. If you would like to use your own templates with auto-select, you can override the default templates prefix. 
    For example if your template is called My_Windows_10_1809.xml, use '-TemplatePrefix "My_Windows"' to automatically select your templates based on current operating system and build.

.PARAMETER Mode
    CTXOE supports three different modes:
        Analyze - Do not apply any changes, only show the recommended changes.
        Execute - Apply the changes to the operating system.
        Rollback - Revert the applied changes. Requires a valid XML backup from the previously run Execute phase. This file is usually called Execute_History.xml.

    WARNING: Rollback mode cannot restore applications that have been removed. If you are planning to remove UWP applications and want to be able to recover them, use snapshots instead of rollback mode.

.PARAMETER IgnoreConditions
    When you use -IgnoreConditions switch, all conditions are skipped and optimizations are applied without any environments tests. This is used mostly for troubleshooting and is not recommended for normal environments.

.PARAMETER Groups
    Array that allows you to specify which groups to process from a specified source file.

.PARAMETER OutputLogFolder
    The location where to save all generated log files. This will replace an automatically generated folder .\Logs and is typically used with ESD solutions like SCCM.

.PARAMETER OutputXml
    The location where the output XML should be saved. The XML with results is automatically saved under .\Logs folder, but you can optionally specify also other location. This argument can be used together with -OutputHtml.

.PARAMETER OutputHtml
    The location where the output HTML report should be saved. The HTML with results is automatically saved under .\Logs folder, but you can optionally specify another location. This argument can be used together with -OutputXml.

.PARAMETER OptimizerUI
    Parameter used by Citrix Optimizer UI to retrieve information from optimization engine. For internal use only.

.EXAMPLE
    .\CtxOptimizerEngine.ps1 -Source C:\Temp\Win10.xml -Mode Analyze
    Process all entries in Win10.xml file and display the recommended changes. Changes are not applied to the system.

.EXAMPLE
    .\CtxOptimizerEngine.ps1 -Source C:\Temp\Win10.xml -Mode Execute
    Process all entries from Win10.xml file. These changes are applied to the operating system.

.EXAMPLE
    .\CtxOptimizerEngine.ps1 -Source C:\Temp\Win10.xml -Mode Execute -Groups "DisableServices", "RemoveApplications"
    Process entries from groups "Disable Services" and "Remove built-in applications" in Win10.xml file. These changes are applied to the operating system.

.EXAMPLE
    .\CtxOptimizerEngine.ps1 -Source C:\Temp\Win10.xml -Mode Execute -OutputXml C:\Temp\Rollback.xml
    Process all entries from Win10.xml file. These changes are applied to the operating system. Save the rollback instructions in the file rollback.xml.

.EXAMPLE
    .\CtxOptimizerEngine.ps1 -Source C:\Temp\Rollback.xml -Mode Rollback
    Revert all changes from the file rollback.xml.

.NOTES
    Author: Martin Zugec
    Date:   February 17, 2017

.LINK
    https://support.citrix.com/article/CTX224676
#>

#Requires -Version 2

Param (
    [Alias("Template")]
    [System.String]$Source,

    [ValidateSet('analyze','execute','rollback')]

    [System.String]$Mode = "Analyze",

    [Array]$Groups,

    [String]$OutputLogFolder,

    [String]$OutputHtml,

    [String]$OutputXml,

    [Switch]$OptimizerUI,

    [Switch]$IgnoreConditions,

    [String]$TemplatePrefix
)

[String]$OptimizerVersion = "2.7";
# Retrieve friendly OS name (e.g. Winodws 10 Pro)
[String]$m_OSName = $(Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName;
# If available, retrieve a build number (yymm like 1808). This is used on Windows Server 2016 and Windows 10, but is not used on older operating systems and is optional
[String]$m_OSBuild = $(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ReleaseID -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ReleaseID);

Write-Host "------------------------------"
Write-Host "| Citrix Optimization Engine |"
Write-Host "| Version $OptimizerVersion                |"
Write-Host "------------------------------"
Write-Host

Write-Host "Running in " -NoNewline
Write-Host -ForegroundColor Yellow $Mode -NoNewLine
Write-Host " mode"

# Error handling. We want Citrix Optimizer to abort on any error, so error action preference is set to "Stop".
# The problem with this approach is that if Optimizer is called from another script, "Stop" instruction will apply to that script as well, so failure in Optimizer engine will abort calling script(s).
# As a workaround, instead of terminating the script, Optimizer has a global error handling procedure that will restore previous setting of ErrorActionPreference and properly abort the execution.
$OriginalErrorActionPreferenceValue = $ErrorActionPreference;
$ErrorActionPreference = "Stop";

Trap {
    Write-Host "Citrix Optimizer engine has encountered a problem and will now terminate";
    $ErrorActionPreference = $OriginalErrorActionPreferenceValue;
    Write-Error $_;

    # Update $Run_Status with error encountered and save output XML file.
    If ($Run_Status) {
        $Run_Status.run_successful = $False.ToString();
        $Run_Status.run_details = "Error: $_";
        $Run_Status.time_end = [DateTime]::Now.ToString('yyyy-MM-dd_HH-mm-ss') # Saving DateTime in predefined format. This is required, since we don't know the target localization settings and want to make sure that UI and engine can communicate in same language.
        $PackDefinitionXml.Save($ResultsXml);
    }

    Return $False;
}

# Create enumeration for PluginMode. Enumeration cannot be used in the param() section, as that would require a DynamicParam on a script level.
[String]$PluginMode = $Mode;

# Just in case if previous run failed, make sure that all modules are reloaded
Remove-Module CTXOE*;

# Create $CTXOE_Main variable that defines folder where the script is located. If code is executed manually (copy & paste to PowerShell window), current directory is being used
If ($MyInvocation.MyCommand.Path -is [Object]) {
    [string]$Global:CTXOE_Main = $(Split-Path -Parent $MyInvocation.MyCommand.Path);
} Else {
    [string]$Global:CTXOE_Main = $(Get-Location).Path;
}

# Create Logs folder if it doesn't exists
If ($OutputLogFolder.Length -eq 0) {
    $Global:CTXOE_LogFolder = "$CTXOE_Main\Logs\$([DateTime]::Now.ToString('yyyy-MM-dd_HH-mm-ss'))"
} Else {
    $Global:CTXOE_LogFolder = $OutputLogFolder;
}

If ($(Test-Path "$CTXOE_LogFolder") -eq $false) {
    Write-Host "Creating Logs folder $(Split-Path -Leaf $CTXOE_LogFolder)"
    MkDir $CTXOE_LogFolder | Out-Null
}

# Report the location of log folder to UI
If ($OptimizerUI) {
    $LogFolder = New-Object -TypeName PSObject
    $LogFolder.PSObject.TypeNames.Insert(0,"logfolder")
    $LogFolder | Add-Member -MemberType NoteProperty -Name Location -Value $CTXOE_LogFolder
    Write-Output $LogFolder
}

# Initialize debug log (transcript). PowerShell ISE doesn't support transcriptions at the moment.
# Previously, we tried to determine if current host supports transcription or not, however this functionality is broken since PowerShell 4.0. Using Try/Catch instead.
Write-Host "Starting session log"
Try {
    $CTXOE_DebugLog = "$CTXOE_LogFolder\Log_Debug_CTXOE.log"
    Start-Transcript -Append -Path "$CTXOE_DebugLog" | Out-Null
} Catch { Write-Host "An exception happened when starting transcription: $_" -ForegroundColor Red }

# Check if user is administrator
Write-Host "Checking permissions"
If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Throw "You must be administrator in order to execute this script"
}

# Check if template name has been provided. If not, try to detect proper template automatically
If ($Source.Length -eq 0 -or $Source -eq "AutoSelect") {
    Write-Host "Template not specified, turning on auto-select mode";
    
    # Multiple template prefixes can be used - users can have their own custom templates.
    [array]$m_TemplatePrefixes = @();
    If ($TemplatePrefix.Length -gt 0) {
        Write-Host "Custom template prefix detected: $TemplatePrefix";
        $m_TemplatePrefixes += $TemplatePrefix;
    }
    $m_TemplatePrefixes += "Citrix_Windows";
    
    # Strip the description, keep only numbers. Special processing is required to include "R2" versions. Result of this regex is friendly version number (7, 10 or '2008 R2' for example)
    [String]$m_TemplateNameOSVersion = $([regex]"([0-9])+\sR([0-9])+|[(0-9)]+").Match($m_OSName).Captures[0].Value.Replace(" ", "");
    
    # Go through all available template prefixes, starting with custom prefix. Default Citrix prefix is used as a last option
    ForEach ($m_TemplateNamePrefix in $m_TemplatePrefixes) {

        Write-Host "Trying to find matching templates for prefix $m_TemplateNamePrefix"

        # If this is server OS, include "Server" in the template name. If this is client, don't do anything. While we could include _Client in the template name, it just looks weird.
        If ((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name InstallationType).InstallationType -eq "Server") {
            $m_TemplateNamePrefix += "_Server";
            If ($TemplatePrefix.Length -gt 0) {$m_TemplateNameCustomPrefix += "_Server";}
        }

        # First, we try to find if template for current OS and build is available. If not, we tried to find last build for the same OS version. If that is not available, we finally check for generic version of template (not build specific)
        If (Test-Path -Path "$CTXOE_Main\Templates\$(($m_TemplateNamePrefix) + '_' + ($m_TemplateNameOSVersion) + '_' + ($m_OSBuild)).xml") {
            Write-Host "Template detected - using optimal template for current version and build";
            $Source = "$CTXOE_Main\Templates\$(($m_TemplateNamePrefix) + '_' + ($m_TemplateNameOSVersion) + '_' + ($m_OSBuild)).xml";
            Break;
        } Else {
            [array]$m_PreviousBuilds = Get-ChildItem -Path "$CTXOE_Main\Templates" -Filter $($m_TemplateNamePrefix + '_' + ($m_TemplateNameOSVersion) + '_*');
            # Older versions of PowerShell (V2) will automatically delect object instead of initiating an empty array.
            If ($m_PreviousBuilds -isnot [Object] -or $m_PreviousBuilds.Count -eq 0) {
                If (Test-Path -Path "$CTXOE_Main\Templates\$(($m_TemplateNamePrefix) + '_' + ($m_TemplateNameOSVersion)).xml") {
                    Write-Host "Template detected - using generic template for OS version";
                    $Source = "$CTXOE_Main\Templates\$(($m_TemplateNamePrefix) + '_' + ($m_TemplateNameOSVersion)).xml";
                    Break;
                }
            } Else {
                Write-Host "Template detected - using previous OS build";
                $Source = "$CTXOE_Main\Templates\$($m_PreviousBuilds | Sort-Object Name | Select-Object -ExpandProperty Name -Last 1)";
                Break;
            }
        }
    
    }

    If ($Source.Length -eq 0 -or $Source -eq "AutoSelect")  {Throw "Auto-detection of template failed, no suitable template has been found"}

}

# Check if -Source is a fullpath or just name of the template. If it's just the name, expand to a fullpath.
If (-not $Source.Contains("\")) {
    If (-not $Source.ToLower().EndsWith(".xml")) {
         $Source = "$Source.xml";
    }

    $Source = "$CTXOE_Main\Templates\$Source";
}

# Specify the default location of output XML
[String]$ResultsXml = "$CTXOE_LogFolder\$($PluginMode)_History.xml"
If ($OutputHtml.Length -eq 0) {
    [String]$OutputHtml = "$CTXOE_LogFolder\$($PluginMode)_History.html"
}

Write-Host
Write-Host "Processing definition file $Source"
[Xml]$PackDefinitionXml = Get-Content $Source

# Try to find if this template has been executed before. If <runstatus /> is present, move it to history (<previousruns />). This is used to store all previous executions of this template.
If ($PackDefinitionXml.root.run_status) {
    # Check if <previousruns /> exists. If not, create a new one.
    If (-not $PackDefinitionXml.root.previousruns) {
        $PackDefinitionXml.root.AppendChild($PackDefinitionXml.CreateElement("previousruns")) | Out-Null;
    }

    $PackDefinitionXml.root.Item("previousruns").AppendChild($PackDefinitionXml.root.run_status) | Out-Null;
}

# Create new XML element to store status of the execution.
[System.Xml.XmlElement]$Run_Status = $PackDefinitionXml.root.AppendChild($PackDefinitionXml.ImportNode($([Xml]"<run_status><run_mode /><time_start /><time_end /><entries_total /><entries_success /><entries_failed /><run_successful /><run_details /><optimizerversion /><targetos /><targetcomputer /></run_status>").DocumentElement, $True));
$Run_Status.run_successful = $False.ToString();
$Run_Status.run_mode = $PluginMode;
$Run_Status_Default_Message = "Run started, but never finished";
$Run_Status.run_details = $Run_Status_Default_Message;
$Run_Status.time_start = [DateTime]::Now.ToString('yyyy-MM-dd_HH-mm-ss') # Saving DateTime in predefined format. This is required, since we don't know the target localization settings and want to make sure that UI and engine can communicate in same language.
$Run_Status.optimizerversion = $OptimizerVersion;
$Run_Status.targetcomputer =  $Env:ComputerName;

If ($m_OSBuild.Length -gt 0) {
    $Run_Status.targetos = $m_OSName + " build " + $m_OSBuild;
} Else {
    $Run_Status.targetos = $m_OSName;
}

$PackDefinitionXml.Save($ResultsXml);

# Create new variables for counting of successful/failed/skipped entries execution. This is used in run_status reporting.
$Run_Status.entries_total = $PackDefinitionXml.SelectNodes("//entry").Count.ToString();
[Int]$Run_Status_Success = 0;
[Int]$Run_Status_Failed = 0;

# Add CTXOE modules to PSModulePath variable. With this modules can be loaded dynamically based on the prefix.
Write-Host "Adding CTXOE modules"
$Global:CTXOE_Modules = "$CTXOE_Main\Modules"
$Env:PSModulePath = "$([Environment]::GetEnvironmentVariable("PSModulePath"));$($Global:CTXOE_Modules)"

# Older version of PowerShell cannot load modules on-demand. All modules are pre-loaded.
If ($Host.Version.Major -le 2) {
    Write-Host "Detected older version of PowerShell. Importing all modules manually."
    ForEach ($m_Module in $(Get-ChildItem -Path "$CTXOE_Main\Modules" -Recurse -Filter "*.psm1")) {
        Import-Module -Name $m_Module.FullName
    }
}

# If mode is rollback, check if definition file contains the required history elements
If ($PluginMode -eq "Rollback") {
    If ($PackDefinitionXml.SelectNodes("//rollbackparams").Count -eq 0) {
        Throw "You need to select a log file from execution for rollback. This is usually called execute_history.xml. The file specified doesn't include instructions for rollback"
    }
}

# Display metadata for selected template. This acts as a header information about template
$PackDefinitionXml.root.metadata.ChildNodes | Select-Object Name, InnerText | Format-Table -HideTableHeaders

# First version of templates organized groups in packs. This was never really used and < pack/> element was removed in schema version 2.0
# This code is used for backwards compatibility with older templates
If ($PackDefinitionXml.root.pack -is [System.Xml.XmlElement]) {
    Write-host "Old template format has been detected, you should migrate to newer format" -for Red;
    $GroupElements = $PackDefinitionXml.SelectNodes("/root/pack/group");
} Else {
    $GroupElements = $PackDefinitionXml.SelectNodes("/root/group");
}

# Check if template has any conditions to process. In rollback mode, we do not need to process conditions - they've been already resolved to $True in execute mode and we should be able to rollback all changes.
If ($PluginMode -ne "rollback" -and -not $IgnoreConditions -and $PackDefinitionXml.root.condition -is [Object]) {
    Write-Host
    Write-Host "Template condition detected"
    [Hashtable]$m_TemplateConditionResult = CTXOE\Test-CTXOECondition -Element $PackDefinitionXml.root.condition; 
    Write-Host "Template condition result: $($m_TemplateConditionResult.Result)"
    Write-Host "Template condition details: $($m_TemplateConditionResult.Details)"
    Write-Host
    If ($m_TemplateConditionResult.Result -eq $False) {
        $Run_Status.run_details = "Execution stopped by template condition: $($m_TemplateConditionResult.Details)";
    }
}

# Check if template supports requested mode. If not, abort execution and throw an error
If ($PackDefinitionXml.root.metadata.SelectSingleNode("$($PluginMode.ToLower())_not_supported") -is [System.Xml.XmlElement]) {
    $Run_Status.run_details = "This template does NOT support requested mode $($PluginMode)!";
}


# Process template
ForEach ($m_Group in $GroupElements) {
    Write-Host
    Write-Host "        Group: $($m_Group.DisplayName)"
    Write-Host "        Group ID: $($m_Group.ID)"

    # Proceed only if the current run status message has NOT been modified. This is used to detect scenarios where template is reporting that run should not proceed, e.g. when conditions are used or mode is unsupported.
    If ($Run_Status.run_details -ne $Run_Status_Default_Message) {
        Write-Host "        Template processing failed, skipping"
        Continue
    }

    If ($Groups.Count -gt 0 -and $Groups -notcontains $m_Group.ID) {
        Write-Host "        Group not included in the -Groups argument, skipping"
        Continue
    }

    If ($m_Group.Enabled -eq "0") {
        Write-Host "    This group is disabled, skipping" -ForegroundColor DarkGray
        Continue
    }
    
    # Check if group supports requested mode. If not, move to next group
    [Boolean]$m_GroupModeNotSupported = $m_Group.SelectSingleNode("$($PluginMode.ToLower())_not_supported") -is [System.Xml.XmlElement]

    If ($m_GroupModeNotSupported) {
        Write-Host "    This group does not support $($PluginMode.ToLower()) mode, skipping" -ForegroundColor DarkGray
    }

    # PowerShell does not have concept of loop scope. We need to clear all variables from previous group before we process next group.
    Remove-Variable m_GroupConditionResult -ErrorAction SilentlyContinue;

    # Check if group has any conditions to process. 
    If ($PluginMode -ne "rollback" -and -not $IgnoreConditions -and $m_Group.condition -is [Object]) {
        Write-Host
        Write-Host "        Group condition detected"
        [Hashtable]$m_GroupConditionResult = CTXOE\Test-CTXOECondition -Element $m_Group.condition; 
        Write-Host "        Group condition result: $($m_GroupConditionResult.Result)"
        Write-Host "        Group condition details: $($m_GroupConditionResult.Details)"
        Write-Host
    }

    ForEach ($m_Entry in $m_Group.SelectNodes("./entry")) {
        Write-Host "            $($m_Entry.Name) - " -NoNewline

        If ($m_Entry.Enabled -eq "0") {
            Write-Host "    This entry is disabled, skipping" -ForegroundColor DarkGray
            CTXOE\New-CTXOEHistoryElement -Element $m_Entry -SystemChanged $False -StartTime $([DateTime]::Now) -Result $False -Details "Entry is disabled"
            Continue
        }

        If ($m_Entry.Execute -eq "0") {
            Write-Host " Entry is not marked for execution, skipping" -ForegroundColor DarkGray
            CTXOE\New-CTXOEHistoryElement -Element $m_Entry -SystemChanged $False -StartTime $([DateTime]::Now) -Result $False -Details "Entry is not marked for execution, skipping"
            Continue
        }

        # Check if entry supports requested mode. If not, move to next entry. If parent group does not support this mode, all entries should be skipped.
        # We need to make sure that ALL entries that are skipped have "Execute" set to 0 - otherwise status summary will fail to properly determine if script run was successful or not
        If (($m_GroupModeNotSupported -eq $True) -or ($m_Entry.SelectSingleNode("$($PluginMode.ToLower())_not_supported") -is [System.Xml.XmlElement])) {
            Write-Host "    This entry does not support $($PluginMode.ToLower()) mode, skipping" -ForegroundColor DarkGray
            CTXOE\New-CTXOEHistoryElement -Element $m_Entry -SystemChanged $False -StartTime $([DateTime]::Now) -Result $False -Details "This entry does not support $($PluginMode.ToLower()) mode, skipping"
            $m_Entry.Execute = "0";
            Continue
        }

        # Check if entry supports requested mode. If not, move to next entry
        If ($m_Entry.SelectSingleNode("$($PluginMode.ToLower())_not_supported") -is [System.Xml.XmlElement]) {
            Write-Host "    This entry does not support $($PluginMode.ToLower()) mode, skipping" -ForegroundColor DarkGray
            CTXOE\New-CTXOEHistoryElement -Element $m_Entry -SystemChanged $False -StartTime $([DateTime]::Now) -Result $False -Details "This entry does not support $($PluginMode.ToLower()) mode, skipping"

            Continue
        }

        # Section to process (parent) group conditions and entry conditions. Can be skipped if -IgnoreConditions is used or in rollback mode
        If ($PluginMode -ne "Rollback" -and -not $IgnoreConditions ) {
            # Check if the group condition has failed. If yes, none of the entries should be processed
            If ($m_GroupConditionResult -is [object] -and $m_GroupConditionResult.Result -eq $False) {
                Write-Host "    This entry is disabled by group condition, skipping" -ForegroundColor DarkGray;
                CTXOE\New-CTXOEHistoryElement -Element $m_Entry -SystemChanged $False -StartTime $([DateTime]::Now) -Result $False -Details "FILTERED: $($m_GroupConditionResult.Details)";
                $m_Entry.Execute = "0";
                Continue
            }

            # PowerShell does not have concept of loop scope. We need to clear all variables from previous group before we process next group.
            Remove-Variable m_ItemConditionResult -ErrorAction SilentlyContinue;

            # Check if this item has any conditions to process. 
            If ($m_Entry.condition -is [Object]) {
                Write-Host
                Write-Host "            Entry condition detected"
                [Hashtable]$m_ItemConditionResult = CTXOE\Test-CTXOECondition -Element $m_Entry.condition; 
                Write-Host "            Entry condition result: $($m_ItemConditionResult.Result)"
                Write-Host "            Entry condition details: $($m_ItemConditionResult.Details)"
                Write-Host
                
                If ($m_ItemConditionResult.Result -eq $False) {
                    Write-Host "    This entry is disabled by condition, skipping" -ForegroundColor DarkGray;
                    CTXOE\New-CTXOEHistoryElement -Element $m_Entry -SystemChanged $False -StartTime $([DateTime]::Now) -Result $False -Details "FILTERED: $($m_ItemConditionResult.Details)";
                    $m_Entry.Execute = "0";
                    Continue;
                }
            }
        }

        $m_Action = $m_Entry.SelectSingleNode("./action")
        Write-Verbose "            Plugin: $($m_Action.Plugin)"

        # While some plugins can use only a single set of instructions to perform all the different operations (typically services or registry keys), this might not be always possible.

        # Good example is "PowerShell" plugin - different code can be used to analyze the action and execute the action (compare "Get-CurrentState -eq $True" for analyze to "Set-CurrentState -Mode Example -Setup Mode1" for execute mode).

        # In order to support this scenarios, it is possible to override the default <params /> element with a custom element for analyze and rollback phases. Default is still <params />. With this implementation, there can be an action that will implement all three elements (analyzeparams, rollbackparams and executeparams).

        [String]$m_ParamsElementName = "params"
        [String]$m_OverrideElement = "$($PluginMode.ToLower())$m_ParamsElementName"

        If ($m_Action.$m_OverrideElement -is [Object]) {
            Write-Verbose "Using custom <$($m_OverrideElement) /> element"
            $m_ParamsElementName = $m_OverrideElement
        }

        # To prevent any unexpected damage to the system, Rollback mode requires use of custom params object and cannot use the default one.
        If ($PluginMode -eq "Rollback" -and $m_Action.$m_OverrideElement -isnot [Object]) {
            If ($m_Entry.history.systemchanged -eq "0") {
                Write-Host "This entry has not changed, skip" -ForegroundColor DarkGray
                Continue
            } Else {
                Write-Host "Rollback mode requires custom instructions that are not available, skip" -ForegroundColor DarkGray
                Continue
            }
        }

        # Reset variables that are used to report the status
        [Boolean]$Global:CTXOE_Result = $False;
        $Global:CTXOE_Details = "No data returned by this entry (this is unexpected)";

        # Two variables used by rollback. First identify that this entry has modified the system. The second should contain information required for rollback of those changes (if possible). This is required only for "execute" mode.
        [Boolean]$Global:CTXOE_SystemChanged = $False

        $Global:CTXOE_ChangeRollbackParams = $Null

        [DateTime]$StartTime = Get-Date;
        CTXOE\Invoke-CTXOEPlugin -PluginName $($m_Action.Plugin) -Params $m_Action.$m_ParamsElementName -Mode $PluginMode -Verbose

        # Test if there is custom details message for current mode or general custom message. This allows you to display friendly message instead of generic error.
        # This can be either mode-specific or generic (message_analyze_true or message_true). Last token (true/false) is used to identify if custom message should be displayed for success or failure
        # If custom message is detected, output from previous function is ignored and CTXOE_Details is replaced with custom text
        [string]$m_OverrideOutputMessageMode = "message_$($PluginMode.ToLower())_$($Global:CTXOE_Result.ToString().ToLower())";
        [string]$m_OverrideOutputMessageGeneric = "message_$($Global:CTXOE_Result.ToString().ToLower())";

        If ($m_Entry.$m_OverrideOutputMessageMode -is [Object]) {
            $Global:CTXOE_Details = $($m_Entry.$m_OverrideOutputMessageMode);
        } ElseIf ($m_Entry.$m_OverrideOutputMessageGeneric -is [Object]) {
            $Global:CTXOE_Details = $($m_Entry.$m_OverrideOutputMessageGeneric);
        }

		# This code is added to have a situation where CTXOE_Result is set, but not to boolean value (for example to empty string). This will prevent engine from crashing and report which entry does not behave as expected.
		# We do this check here so following code does not need to check if returned value exists
		If ($Global:CTXOE_Result -isnot [Boolean]) {
			$Global:CTXOE_Result = $false;
			$Global:CTXOE_Details = "While processing $($m_Entry.Name) from group $($m_Group.ID), there was an error or code did not return expected result. This value should be boolean, while returned value is $($Global:CTXOE_Result.GetType().FullName)."; 
		}

        If ($Global:CTXOE_Result -eq $false) {
            $Run_Status_Failed += 1;
            Write-Host -ForegroundColor Red $CTXOE_Details
        } Else {
            $Run_Status_Success += 1;
            Write-Host -ForegroundColor Green $CTXOE_Details
        }

        # Save information about changes as an element
        CTXOE\New-CTXOEHistoryElement -Element $m_Entry -SystemChanged $CTXOE_SystemChanged -StartTime $StartTime -Result $CTXOE_Result -Details $CTXOE_Details -RollbackInstructions $CTXOE_ChangeRollbackParams

        If ($OptimizerUI) {
            $history = New-Object -TypeName PSObject
            $history.PSObject.TypeNames.Insert(0,"history")
            $history | Add-Member -MemberType NoteProperty -Name GroupID -Value $m_Group.ID
            $history | Add-Member -MemberType NoteProperty -Name EntryName -Value $m_Entry.Name
            $history | Add-Member -MemberType NoteProperty -Name SystemChanged -Value $m_Entry.SystemChanged
            $history | Add-Member -MemberType NoteProperty -Name StartTime -Value $m_Entry.History.StartTime
            $history | Add-Member -MemberType NoteProperty -Name EndTime -Value $m_Entry.History.EndTime
            $history | Add-Member -MemberType NoteProperty -Name Result -Value $m_Entry.History.Return.Result
            $history | Add-Member -MemberType NoteProperty -Name Details -Value $m_Entry.History.Return.Details

            Write-Output $history
        }
    }
}

#Region "Run status processing"
# Finish processing of run_status, save everything to return XML file
$Run_Status.time_end = [DateTime]::Now.ToString('yyyy-MM-dd_HH-mm-ss') # Saving DateTime in predefined format. This is required, since we don't know the target localization settings and want to make sure that UI and engine can communicate in same language.

$Run_Status.entries_success = $Run_Status_Success.ToString();
$Run_Status.entries_failed = $Run_Status_Failed.ToString();

# Run status should be determined ONLY if template has not aborted execution before.
If ($Run_Status.run_details -eq $Run_Status_Default_Message) {
    
    # Count all entries that were expected to execute (execute=1), but have not finished successfully (result!=1)
    [Int]$m_EntriesNotExecuted = $PackDefinitionXml.SelectNodes("//entry[execute=1 and not(history/return/result=1)]").Count

    # If we have entries that are not successful
    If ($m_EntriesNotExecuted -gt 0) {
        If ($m_EntriesNotExecuted -eq 1) {
            $Run_Status.run_details = "$m_EntriesNotExecuted entry has failed";
        } Else {
            $Run_Status.run_details = "$m_EntriesNotExecuted entries have failed";
        }
    # If anything is marked as failed
    } ElseIf ($Run_Status_Failed -gt 0) {
        If ($Run_Status_Failed -eq 1) {
            $Run_Status.run_details = "$Run_Status_Failed entry from this template failed";
        } Else {
            $Run_Status.run_details = "$Run_Status_Failed entries from this template failed";
        }
    # If nothing was actually executed
    } ElseIf ($Run_Status_Success -eq 0) {
        $Run_Status.run_details = "No entries from this template have been processed";
    # Nothing failed, something was successful = sounds good
    } ElseIf ($Run_Status_Success -gt 0 -and $Run_Status_Failed -eq 0) {
        $Run_Status.run_successful = $True.ToString();
        $Run_Status.run_details = "Template has been processed successfully";
    } Else {
        $Run_Status.run_details = "Unknown condition when evaluating run result";  
    }
}
#EndRegion

# Send the overall execute result for UI to show
If ($OptimizerUI) {
    $overallresult = New-Object -TypeName PSObject
    $overallresult.PSObject.TypeNames.Insert(0,"overallresult")
    $overallresult | Add-Member -MemberType NoteProperty -Name run_successful -Value $Run_Status.run_successful
    $overallresult | Add-Member -MemberType NoteProperty -Name run_details -Value $Run_Status.run_details
    $overallresult | Add-Member -MemberType NoteProperty -Name entries_success -Value $Run_Status.entries_success
    $overallresult | Add-Member -MemberType NoteProperty -Name entries_failed -Value $Run_Status.entries_failed

    Write-Output $overallresult
}
# end

# Save the output in XML format for further parsing\history
$PackDefinitionXml.Save($ResultsXml);

#Region "Registry status reporting"

# If mode is 'execute', then save registry status. If mode is 'rollback' (and registry status exists), remove it. No action required for 'analyze' mode

[String]$m_RegistryPath = "HKLM:\SOFTWARE\Citrix\Optimizer\" + $PackDefinitionXml.root.metadata.category;

If ($PluginMode -eq "execute") {
    # Check if registry key exists
    If ($(Test-Path $m_RegistryPath) -eq $False) {
        # If registry key doesn't exist, create it
        New-Item -Path $m_RegistryPath -Force | Out-Null;
    }

    # Save location of XML file that contains more details about execution
    New-ItemProperty -Path $m_RegistryPath -Name "log_path" -PropertyType "string" -Value $ResultsXml -Force | Out-Null;

    # Save all <metadata /> and <run_status />
    ForEach ($m_Node in $PackDefinitionXml.root.metadata.SelectNodes("*")) {
        New-ItemProperty -Path $m_RegistryPath -Name $m_Node.Name -PropertyType "string" -Value $m_Node.InnerText -Force | Out-Null;
    }
    ForEach ($m_Node in $PackDefinitionXml.root.run_status.SelectNodes("*")) {
        New-ItemProperty -Path $m_RegistryPath -Name $m_Node.Name -PropertyType "string" -Value $m_Node.InnerText -Force | Out-Null;
    }

} ElseIf ($PluginMode -eq "rollback") {
    # Check if registry key exists
    If ($(Test-Path $m_RegistryPath) -eq $True) {
        # If registry key exists, delete it
        Remove-Item -Path $m_RegistryPath -Force | Out-Null;
    }
}
#EndRegion

# Use transformation file to generate HTML report
$XSLT = New-Object System.Xml.Xsl.XslCompiledTransform;
$XSLT.Load("$CTXOE_Main\CtxOptimizerReport.xslt");
$XSLT.Transform($ResultsXml, $OutputHtml);

# If another location is requested, save the XML file here as well.
If ($OutputXml.Length -gt 0) {
    $PackDefinitionXml.Save($OutputXml);
}

# If the current host is transcribing, save the transcription
Try {
    Stop-Transcript | Out-Null
} Catch { Write-Host "An exception happened when stopping transcription: $_" -ForegroundColor Red }

# SIG # Begin signature block
# MIIa+wYJKoZIhvcNAQcCoIIa7DCCGugCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUbjVnJLq6VF8AAnA0YtMhWrRF
# aSKgghTvMIIFJDCCBAygAwIBAgIQCpJdJFWANibhh6AFcJolkDANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgVGltZXN0YW1waW5nIENBMB4XDTE4MDgwMTAwMDAwMFoXDTIzMDkw
# MTAwMDAwMFowYDELMAkGA1UEBhMCVVMxHTAbBgNVBAoTFENpdHJpeCBTeXN0ZW1z
# LCBJbmMuMQ0wCwYDVQQLEwRHTElTMSMwIQYDVQQDExpDaXRyaXggVGltZXN0YW1w
# IFJlc3BvbmRlcjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANjWtJ4e
# cpVfB34YnxfYNvb1Rp2JbBu5/G9Boe8aEBQc2zidW82ousZrXj2QD2qUA1Ee8noo
# t1KGcQdY0WzzbSIU7KHePB5KaESWjtHVJ3BW6W9q+U24m2dPD/oaNxGx6DtD7M0N
# lMBIRZKo7aNIsRIlHkg7wnNQzqi0jTkzBO7S34holaqhfuQgqkgKqGmcoSIXVqNm
# EFaU+5kpYFqpMo6x1sSAgfgNEcIgGjnj8xzdU1rnh6iNYMxOt8guMWk2z+KKNbux
# H6YLAA9VBYW417Zf153/5L4ejuxxUhCp03JkoUIWjSRjz3m24HD9K8NSgJ0AdDpN
# E8ZPmIJCMFi9FYcCAwEAAaOCAcYwggHCMB8GA1UdIwQYMBaAFPS24SAd/imu0uRh
# pbKiJbLIFzVuMB0GA1UdDgQWBBS1Y37AhXUHPaYuvS/SUsWFFisSbTAMBgNVHRMB
# Af8EAjAAMA4GA1UdDwEB/wQEAwIHgDAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDBP
# BgNVHSAESDBGMDcGCWCGSAGG/WwHATAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3
# dy5kaWdpY2VydC5jb20vQ1BTMAsGCWCGSAGG/WwDFTBxBgNVHR8EajBoMDKgMKAu
# hixodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vc2hhMi1hc3N1cmVkLXRzLmNybDAy
# oDCgLoYsaHR0cDovL2NybDQuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC10cy5j
# cmwwgYUGCCsGAQUFBwEBBHkwdzAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGln
# aWNlcnQuY29tME8GCCsGAQUFBzAChkNodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRTSEEyQXNzdXJlZElEVGltZXN0YW1waW5nQ0EuY3J0MA0GCSqG
# SIb3DQEBCwUAA4IBAQBrQ4tHgdu37madmYML6Ikfb8bNWoritioGcrlVfsMEGdLN
# LAsPYqrMo9mZmNzKTE7UVzGVdwb+Cfz9IRfD6hmK6hhEuom+XNzC8LGQ3o7U2ede
# YF/xuIcFZAwmQnXOoVl4yDWKrfyalOIO9wpQ6bDV7f0CPa8j3Qj2eNJ2u2qKnRE+
# x5Iz8j5lsjQeefIriGVHd27R93ai0li9WZMT9KKOAk06R0Z0qyG70jXhoUp4Or5c
# lv5mmVJgmxr1hMjVg7v95WGY50p2+cfhqLlViu2cu0LCg31IUb0lbTYNbgY1eca2
# cr8F0ppVnrt55YVfb1M80huj9DeYYjeFSKkcN+6xMIIFMDCCBBigAwIBAgIQBAkY
# G1/Vu2Z1U0O1b5VQCDANBgkqhkiG9w0BAQsFADBlMQswCQYDVQQGEwJVUzEVMBMG
# A1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQw
# IgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMTMxMDIyMTIw
# MDAwWhcNMjgxMDIyMTIwMDAwWjByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGln
# aUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhE
# aWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMIIBIjANBgkq
# hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA+NOzHH8OEa9ndwfTCzFJGc/Q+0WZsTrb
# RPV/5aid2zLXcep2nQUut4/6kkPApfmJ1DcZ17aq8JyGpdglrA55KDp+6dFn08b7
# KSfH03sjlOSRI5aQd4L5oYQjZhJUM1B0sSgmuyRpwsJS8hRniolF1C2ho+mILCCV
# rhxKhwjfDPXiTWAYvqrEsq5wMWYzcT6scKKrzn/pfMuSoeU7MRzP6vIK5Fe7SrXp
# dOYr/mzLfnQ5Ng2Q7+S1TqSp6moKq4TzrGdOtcT3jNEgJSPrCGQ+UpbB8g8S9MWO
# D8Gi6CxR93O8vYWxYoNzQYIH5DiLanMg0A9kczyen6Yzqf0Z3yWT0QIDAQABo4IB
# zTCCAckwEgYDVR0TAQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0l
# BAwwCgYIKwYBBQUHAwMweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRw
# Oi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRz
# LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwgYEGA1Ud
# HwR6MHgwOqA4oDaGNGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFz
# c3VyZWRJRFJvb3RDQS5jcmwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwTwYDVR0gBEgwRjA4BgpghkgB
# hv1sAAIEMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9D
# UFMwCgYIYIZIAYb9bAMwHQYDVR0OBBYEFFrEuXsqCqOl6nEDwGD5LfZldQ5YMB8G
# A1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA0GCSqGSIb3DQEBCwUAA4IB
# AQA+7A1aJLPzItEVyCx8JSl2qB1dHC06GsTvMGHXfgtg/cM9D8Svi/3vKt8gVTew
# 4fbRknUPUbRupY5a4l4kgU4QpO4/cY5jDhNLrddfRHnzNhQGivecRk5c/5CxGwcO
# kRX7uq+1UcKNJK4kxscnKqEpKBo6cSgCPC6Ro8AlEeKcFEehemhor5unXCBc2XGx
# DI+7qPjFEmifz0DLQESlE/DmZAwlCEIysjaKJAL+L3J+HNdJRZboWR3p+nRka7Lr
# ZkPas7CM1ekN3fYBIM6ZMWM9CBoYs4GbT8aTEAb8B4H6i9r5gkn3Ym6hU/oSlBiF
# LpKR6mhsRDKyZqHnGKSaZFHvMIIFMTCCBBmgAwIBAgIQCqEl1tYyG35B5AXaNpfC
# FTANBgkqhkiG9w0BAQsFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNl
# cnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdp
# Q2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMTYwMTA3MTIwMDAwWhcNMzEwMTA3
# MTIwMDAwWjByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkw
# FwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEy
# IEFzc3VyZWQgSUQgVGltZXN0YW1waW5nIENBMIIBIjANBgkqhkiG9w0BAQEFAAOC
# AQ8AMIIBCgKCAQEAvdAy7kvNj3/dqbqCmcU5VChXtiNKxA4HRTNREH3Q+X1NaH7n
# tqD0jbOI5Je/YyGQmL8TvFfTw+F+CNZqFAA49y4eO+7MpvYyWf5fZT/gm+vjRkcG
# GlV+Cyd+wKL1oODeIj8O/36V+/OjuiI+GKwR5PCZA207hXwJ0+5dyJoLVOOoCXFr
# 4M8iEA91z3FyTgqt30A6XLdR4aF5FMZNJCMwXbzsPGBqrC8HzP3w6kfZiFBe/WZu
# VmEnKYmEUeaC50ZQ/ZQqLKfkdT66mA+Ef58xFNat1fJky3seBdCEGXIX8RcG7z3N
# 1k3vBkL9olMqT4UdxB08r8/arBD13ays6Vb/kwIDAQABo4IBzjCCAcowHQYDVR0O
# BBYEFPS24SAd/imu0uRhpbKiJbLIFzVuMB8GA1UdIwQYMBaAFEXroq/0ksuCMS1R
# i6enIZ3zbcgPMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMG
# A1UdJQQMMAoGCCsGAQUFBwMIMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYY
# aHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2Fj
# ZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGB
# BgNVHR8EejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNl
# cnRBc3N1cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMFAGA1UdIARJMEcwOAYK
# YIZIAYb9bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5j
# b20vQ1BTMAsGCWCGSAGG/WwHATANBgkqhkiG9w0BAQsFAAOCAQEAcZUS6VGHVmnN
# 793afKpjerN4zwY3QITvS4S/ys8DAv3Fp8MOIEIsr3fzKx8MIVoqtwU0HWqumfgn
# oma/Capg33akOpMP+LLR2HwZYuhegiUexLoceywh4tZbLBQ1QwRostt1AuByx5jW
# PGTlH0gQGF+JOGFNYkYkh2OMkVIsrymJ5Xgf1gsUpYDXEkdws3XVk4WTfraSZ/tT
# YYmo9WuWwPRYaQ18yAGxuSh1t5ljhSKMYcp5lH5Z/IwP42+1ASa2bKXuh1Eh5Fhg
# m7oMLSttosR+u8QlK0cCCHxJrhO24XxCQijGGFbPQTS2Zl22dHv1VjMiLyI2skui
# SpXY9aaOUjCCBVowggRCoAMCAQICEAK9K4g2WTuaInnewE1iUo0wDQYJKoZIhvcN
# AQELBQAwcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcG
# A1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBB
# c3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTAeFw0xOTA4MDkwMDAwMDBaFw0yMDA4
# MTMxMjAwMDBaMIGWMQswCQYDVQQGEwJVUzEQMA4GA1UECBMHRmxvcmlkYTEXMBUG
# A1UEBxMORnQuIExhdWRlcmRhbGUxHTAbBgNVBAoTFENpdHJpeCBTeXN0ZW1zLCBJ
# bmMuMR4wHAYDVQQLExVYZW5BcHAoU2VydmVyIFNIQTI1NikxHTAbBgNVBAMTFENp
# dHJpeCBTeXN0ZW1zLCBJbmMuMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
# AQEArQMpLa36b5d+7KEh0WhnfMrWEer3ahkGK1rwzrqDu25SLcogHIhngXsf7c+G
# zDMJnBcYsw/JIZrDmkC/2AwtBPOcVAcZg8Wt1JeTd+cnD9UMblz9ARMf7WGUtSbl
# zTpfQAGp/WX2rO9hB8S8wpFbSWShSiwbGGaPLfwrOWYc2WqrapM0TRW8AAw0AB4S
# fxZ6V7gEEEs6gtW9Kl4d46zqbmS0Nege1p+QBYhJk0XXRh/N/Y6YGQyLvKe3d5u8
# jXR+cKgmHI2bEfZvTI24nUuXNS6uHh9A40uvXxv/V5Sh62lihCrok/IhV2aomrzm
# 04P/s2a5eUNCXwPBmMVNp0UkowIDAQABo4IBxTCCAcEwHwYDVR0jBBgwFoAUWsS5
# eyoKo6XqcQPAYPkt9mV1DlgwHQYDVR0OBBYEFHKt5/YlHq46vaRF9OTsCmpMnVli
# MA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzB3BgNVHR8EcDBu
# MDWgM6Axhi9odHRwOi8vY3JsMy5kaWdpY2VydC5jb20vc2hhMi1hc3N1cmVkLWNz
# LWcxLmNybDA1oDOgMYYvaHR0cDovL2NybDQuZGlnaWNlcnQuY29tL3NoYTItYXNz
# dXJlZC1jcy1nMS5jcmwwTAYDVR0gBEUwQzA3BglghkgBhv1sAwEwKjAoBggrBgEF
# BQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAIBgZngQwBBAEwgYQG
# CCsGAQUFBwEBBHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQu
# Y29tME4GCCsGAQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGln
# aUNlcnRTSEEyQXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIw
# ADANBgkqhkiG9w0BAQsFAAOCAQEAi8nNwAzehBcZE7xZAIioZkM6RBnFmL2iamAW
# 3jS4RS+B8feqtWks15ELgMKfwkUUt3HRDMc1wNNpgHPpRrEtZJCBS3f5wHOIwCKB
# 6qeXocNgcZJtoLv502VNEOrrHddYtv1xP3g6ytZERY+j021nXCJV/vD1VQbl/uBo
# GVDjFza6HBKvLKihKoW5eDOIHq/T/RMAQFSM4w0GvQIIINpTtmSbijVr5fs7KNOy
# F6wtk63rynUCTgX7rc7cxVtT4aTHmGaJMeMqPFFsWP4Z6LI25gAx2ucdHAhY2RJl
# YOTegfGLjhnPVoOEmVZvxyDJeUN4F3dz2pcf/fSONbQkNmzkvzGCBXYwggVyAgEB
# MIGGMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNV
# BAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNz
# dXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0ECEAK9K4g2WTuaInnewE1iUo0wCQYFKw4D
# AhoFAKCBxDAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgEL
# MQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUCtwIV89SQ4nthFlpP9qO
# ws+uMEIwZAYKKwYBBAGCNwIBDDFWMFSgOIA2AEMAaQB0AHIAaQB4ACAAUwB1AHAA
# cABvAHIAdABhAGIAaQBsAGkAdAB5ACAAVABvAG8AbABzoRiAFmh0dHA6Ly93d3cu
# Y2l0cml4LmNvbSAwDQYJKoZIhvcNAQEBBQAEggEATjcEjVNHAH7Ru4B0FB6QQz6V
# ODa6/Gp7pIsxmN8vqRxKxQIr1ZOgRG2WSPNpeebMnn+gOY4owzYNlOKev5WdrsPs
# SlJkenN3tHycZbI9Iy1i7bt/MchSkemr4SS+zakMGTlm/q8WnOjnSfOhQFjOGwrR
# W3YfsWty7v6hdHGLf0EMwZ6liT0geZFwKwHozjubizoF6IP3jGKk9k/WpkPNSHMS
# mhYOpUnZYJyH1L1Zx3Tnb4a5GNEGxhbfu54FVk7a2FtTrqqg/yo5XkeMIVCZByTQ
# P3XunLudV2AAFGF/XZ/EwUqdWmI5dQLk9DGxTnTMIT89Di0CkAFx40IFNayUJqGC
# Av0wggL5BgkqhkiG9w0BCQYxggLqMIIC5gIBATCBhjByMQswCQYDVQQGEwJVUzEV
# MBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29t
# MTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgVGltZXN0YW1waW5n
# IENBAhAKkl0kVYA2JuGHoAVwmiWQMA0GCWCGSAFlAwQCAQUAoIIBNDAYBgkqhkiG
# 9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yMDA0MDcwOTE3NDNa
# MC8GCSqGSIb3DQEJBDEiBCBMGETlwdgMIBBBJmTfrWpjFbYoBikw6V7QpkIym05e
# dzCByAYLKoZIhvcNAQkQAi8xgbgwgbUwgbIwga8EILAqztuhstdlrNbpxQZ6VhvR
# VOGFMgwcz15jJralby6jMIGKMHakdDByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMM
# RGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQD
# EyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgVGltZXN0YW1waW5nIENBAhAKkl0k
# VYA2JuGHoAVwmiWQMA0GCSqGSIb3DQEBAQUABIIBALWuZB5oHUPpIvbvA8RdvogW
# AgXNQRshiBFETHcdLV6Fp3uSakPquE8/ZKFTmfeX8lgIuy8wsHXHopQN5Z0LFRBR
# RB6bLQZ39ucAvjnmu7TlY/9EvA2gVpIffira0p49mJEHCoa1vBno2J+SrDgAcx7E
# pxoHjaw2MUyRuY8Q8vYOGFfZC5acdQ2RXt8cP8ugxZTrOljpBKnJP4kIRYDBmVzQ
# +H7r6rF5AxPvZQwlTLYPhQLYkzfruOTFXkF8cvHtJetQQfyMoD/GWwgstRkX+tDp
# vVzkWF0OTnHucWiW3QvVhpmpOTmJhib8Gofms705t/aRqUwcUxCXLmVbLJLOoj8=
# SIG # End signature block
