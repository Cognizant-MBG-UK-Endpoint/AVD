﻿# General function for execution of the plugins. 
Function Invoke-CTXOEPlugin ([String]$PluginName, [System.Xml.XmlElement]$Params, [String]$Mode) {

    [String]$m_FunctionName = "Invoke-CTXOE$($PluginName)$($Mode.ToString())"

    # First test if the required plugin and function is available 
    If ($(Get-Command "$m_FunctionName" -Module CTXOEP_$($PluginName) -ErrorAction SilentlyContinue) -isnot [System.Management.Automation.FunctionInfo]) {
        Throw "Failed to load the required plugin or required function has not been implemented.
        Module: CTXOEP_$($PluginName)
        Function: $m_FunctionName"
    }

    If ($Params -isnot [Object]) {
        Throw "<params /> element is invalid for current entry. Review the definition XML file."
    }

    # Run the plugin with arguments
    & (Get-ChildItem "Function:$m_FunctionName") -Params $Params

}

# Test if registry key (Key + Name) has the required value (Value). Returns a dictionary with two values - [Bool]Result and [String]Details. 
Function Test-CTXOERegistryValue ([String]$Key, [String]$Name, [String]$Value) {
    # Initialize $return object and always assume failure
    [Hashtable]$Return = @{}
    $Return.Result = $False

    [Boolean]$m_RegKeyExists = Test-Path Registry::$($Key)

    # If value is CTXOE_DeleteKey, check if key itself exists. We need to process this first, because DeleteKey does not require 'Name' parameter and next section would fail
    If ($Value -eq "CTXOE_DeleteKey") {
        $Return.Result = $m_RegKeyExists -eq $False;
        If ($Return.Result -eq $True) {
            $Return.Details = "Registry key does not exist";
        } Else {
            $Return.Details = "Registry key exists";
        }
        Return $Return;
    }

    # If value name ('name') is not defined, Optimizer will only test if key exists. This is used in scenarios where you only need to create registry key, but without any values.
    If ($Name.Length -eq 0) {
        $Return.Result = $m_RegKeyExists;
        If ($Return.Result -eq $True) {
            $Return.Details = "Registry key exists";
        } Else {
            $Return.Details = "Registry key does not exist";
        }
        Return $Return;
    }

    # Retrieve the registry item
    $m_RegObject = Get-ItemProperty -Path Registry::$($Key) -Name $Name -ErrorAction SilentlyContinue;

    # If value is CTXOE_DeleteValue (or legacy CTXOE_NoValue), check if value exists. This code doesn't care what is the actual value data, only if it exists or not.
    If (($Value -eq "CTXOE_NoValue") -or ($Value -eq "CTXOE_DeleteValue")) {
        $Return.Result = $m_RegObject -isnot [System.Management.Automation.PSCustomObject];
        If ($Return.Result -eq $True) {
            $Return.Details = "Registry value does not exist";
        } Else {
            $Return.Details = "Registry value exists";
        }
        Return $Return;
    }

    # Return false if registry value was not found
    If ($m_RegObject -isnot [System.Management.Automation.PSCustomObject]) {
        $Return.Details = "Registry value does not exists"
        Return $Return;
    }

    # Registry value can be different object types, for example byte array or integer. The problem is that PowerShell does not properly compare some object types, for example you cannot compare two byte arrays. 
    # When we force $m_Value to always be [String], we have more predictable comparison operation. For example [String]$([Byte[]]@(1,1,1)) -eq $([Byte[]]@(1,1,1)) will work as expected, but $([Byte[]]@(1,1,1)) -eq $([Byte[]]@(1,1,1)) will not
    [string]$m_Value = $m_RegObject.$Name; 

    # If value is binary array, we need to convert it to string first
    If ($m_RegObject.$Name -is [System.Byte[]]) {
        [Byte[]]$Value = $Value.Split(",");
    }

    # If value type is DWORD or QWORD, registry object returns decimal value, while template can use both decimal and hexadecimal. If hexa is used in template, convert to decimal before comparison
    If ($Value -like "0x*") {
        If ($m_RegObject.$Name -is [System.Int32]) {
            $Value = [System.Int32]$Value;
        } ElseIf ($m_RegObject.$Name -is [System.Int64]) {
            $Value = [System.Int64]$Value;
        }
    }
    
    # $m_Value is always [String], $Value can be [String] or [Byte[]] array
    If ($m_value -ne $Value) {
        $Return.Details = "Different value ($m_value instead of $Value)"
    } Else {
        $Return.Result = $True
        $Return.Details = "Requested value $Value is configured"
    }
    Return $Return
}

# Set value of a specified registry key. Returns a dictionary with two values - [Bool]Result and [String]Details.
# There are few special values - CTXOE_DeleteKey (delete whole registry key if present), CTXOE_DeleteValue (delete registry value if present) and LEGACY CTXOE_NoValue (use CTXOE_DeleteValue instead, this was original name)
Function Set-CTXOERegistryValue ([String]$Key, [String]$Name, [String]$Value, [String]$ValueType) {
    
    [Hashtable]$Return = @{"Result" = $False; "Details" = "Internal error in function"}; 

    [Boolean]$m_RegKeyExists = Test-Path Registry::$Key;

    # First we need to handle scenario where whole key should be deleted
    If ($Value -eq "CTXOE_DeleteKey") {
        If ($m_RegKeyExists -eq $True) {
            Remove-Item -Path Registry::$Key -Force -ErrorAction SilentlyContinue | Out-Null
        }

        # Test if registry key exists or not. We need to pass value, so test function understands that we do NOT expect to find anything at target location
        [Hashtable]$Return = Test-CTXOERegistryValue -Key $Key -Value $Value;

        # When we delete whole registry key, we cannot restore it (unless we completely export it before, which is not supported yet)
        $Return.OriginalValue = "CTXOE_DeleteKey";

        Return $Return;

    }
    
    # If parent registry key does not exists, create it
    If ($m_RegKeyExists -eq $False) {
        New-Item Registry::$Key -Force | Out-Null;
        $Return.OriginalValue = "CTXOE_DeleteKey";
    }

    # If 'Name' is not defined, we need to only create a key and not any values
    If ($Name.Length -eq 0) {
        [Hashtable]$Return = Test-CTXOERegistryValue -Key $Key;
        # We need to re-assign this value again - $Return is overwritten by function Test-CTXOERegistryValue
        If ($m_RegKeyExists -eq $False) {
            $Return.OriginalValue = "CTXOE_DeleteKey";
        }
        Return $Return;
    }

    # Now change the value
    $m_ExistingValue = Get-ItemProperty -Path Registry::$Key -Name $Name -ErrorAction SilentlyContinue
    Try {
        If (($Value -eq "CTXOE_NoValue") -or ($Value -eq "CTXOE_DeleteValue")) {
            Remove-ItemProperty -Path Registry::$Key -Name $Name -Force -ErrorAction SilentlyContinue | Out-Null
        } Else {
            # If value type is binary, we need to convert string to byte array first. If this method is used directly with -Value argument (one line instead of two), it fails with error "You cannot call a method on a null-valued expression."
            If ($ValueType -eq "Binary") {
                [Byte[]]$m_ByteArray = $Value.Split(","); #[System.Text.Encoding]::Unicode.GetBytes($Value);
                New-ItemProperty -Path Registry::$Key -Name $Name -PropertyType $ValueType -Value $m_ByteArray -Force | Out-Null
            } Else {
                New-ItemProperty -Path Registry::$Key -Name $Name -PropertyType $ValueType -Value $Value -Force | Out-Null
            }
        }
    } Catch {
        $Return.Details = $($_.Exception.Message); 
        $Return.OriginalValue = "CTXOE_DeleteValue";
        Return $Return; 
    }

    # Re-run the validation test again
    [Hashtable]$Return = Test-CTXOERegistryValue -Key $Key -Name $Name -Value $Value
    
    # Save previous value for rollback functionality
    If ($m_RegKeyExists -eq $True) {
        If ($m_ExistingValue -is [Object]) {
            $Return.OriginalValue = $m_ExistingValue.$Name
        } Else {
            $Return.OriginalValue = "CTXOE_DeleteValue"
        }
    } Else {
        # We need to set this again, since $Return is overwritten by Test-CTXOERegistryValue function
        $Return.OriginalValue = "CTXOE_DeleteKey";
    }
    
    Return $Return
}
Function ConvertTo-CTXOERollbackElement ([Xml.XmlElement]$Element) {
    # Convert the element to XmlDocument. 
    [Xml]$m_TempXmlDocument = New-Object Xml.XmlDocument

    # Change the <params /> (or <executeparams /> to <rollbackparams />. 
    [Xml.XmlElement]$m_TempRootElement = $m_TempXmlDocument.CreateElement("rollbackparams")
    $m_TempRootElement.InnerXml = $Element.InnerXml
    $m_TempXmlDocument.AppendChild($m_TempRootElement) | Out-Null

    # Rollback is based on <value /> element. If this element doesn't exist already (in $Element), create an empty one. If we don't create this empty element, other functions that are trying to assign data to property .value will fail
    If ($m_TempRootElement.Item("value") -isnot [Xml.XmlElement]) {
        $m_TempRootElement.AppendChild($m_TempXmlDocument.CreateElement("value")) | Out-Null; 
    }

    # Return object
    Return $m_TempXmlDocument
}
Function New-CTXOEHistoryElement ([Xml.XmlElement]$Element, [Boolean]$SystemChanged, [DateTime]$StartTime, [Boolean]$Result, [String]$Details, [Xml.XmlDocument]$RollbackInstructions) {
    # Delete any previous <history /> from $Element
    If ($Element.History -is [Object]) {
        $Element.RemoveChild($Element.History) | Out-Null; 
    }

    # Get the parente XML document of the target element
    [Xml.XmlDocument]$SourceXML = $Element.OwnerDocument

    # Generate new temporary XML document. This is easiest way how to construct more complex XML structures with minimal performance impact. 
    [Xml]$m_TempXmlDoc = "<history><systemchanged>$([Int]$SystemChanged)</systemchanged><starttime>$($StartTime.ToString())</starttime><endtime>$([DateTime]::Now.ToString())</endtime><return><result>$([Int]$Result)</result><details>$Details</details></return></history>"

    # Import temporary XML document (standalone) as an XML element to our existing document
    $m_TempNode = $SourceXML.ImportNode($m_TempXmlDoc.DocumentElement, $true)
    $Element.AppendChild($m_TempNode) | Out-Null; 

    # If $RollbackInstructions is provided, save it as a <rollackparams /> element
    If ($RollbackInstructions -is [Object]) {
        $Element.Action.AppendChild($SourceXML.ImportNode($RollbackInstructions.DocumentElement, $true)) | Out-Null
    }
}

# Function to validate conditions. Returns hashtable object with two properties - Result (boolean) and Details. Result should be $True
Function Test-CTXOECondition([Xml.XmlElement]$Element) {

    [Hashtable]$m_Result = @{}; 

    # Always assume that script will fail
    $m_Result.Result = $False;
    $m_Result.Details = "No condition message defined"

    # $CTXOE_Condition is variable that should be returned by code. Because it is global, we want to reset it first. Do NOT assign $Null to variable - it will not delete it, just create variable with $null value
    Remove-Variable -Force -Name CTXOE_Condition -ErrorAction SilentlyContinue -Scope Global;
    Remove-Variable -Force -Name CTXOE_ConditionMessage -ErrorAction SilentlyContinue -Scope Global;

    # Check if condition has all required information (code is most important)
    If ($Element.conditioncode -isnot [object]) {
        $m_Result.Details = "Invalid or missing condition code. Condition cannot be processed";
        Return $m_Result;
    }

    # Execute code. This code should always return $Global:CTXOE_Condition variable (required) and $Global:CTXOE_ConditionMessage (optional)
    Try {
        Invoke-Expression -Command $Element.conditioncode;
    } Catch {
        $m_Result.Details = "Unexpected failure while processing condition: $($_.Exception.Message)";
        Return $m_Result;
    }
    

    # Validate output

    # Test if variable exists
    If (-not $(Test-Path Variable:Global:CTXOE_Condition)) {
        $m_Result.Details = "Required variable (CTXOE_Condition) NOT returned by condition. Condition cannot be processed";
        Return $m_Result;
    }

    # Test if variable is boolean
    If ($Global:CTXOE_Condition -isnot [Boolean]) {
        $m_Result.Details = "Required variable (CTXOE_Condition) is NOT boolean ($True or $False), but $($Global:CTXOE_Condition.GetType().FullName). Condition cannot be processed";
        Return $m_Result;
    }

    # Assign value to variable
    $m_Result.Result = $Global:CTXOE_Condition;

    # If condition failed and failed message is specified in XML section for condition, assign it
    If ($Element.conditionfailedmessage -is [Object] -and $m_Result.Result -eq $False) {
        $m_Result.Details = $Element.conditionfailedmessage;
    }

    # If $CTXOE_ConditionMessage is returned by code, use it to override the failed message
    If ((Test-Path Variable:Global:CTXOE_ConditionMessage)) {
        $m_Result.Details = $Global:CTXOE_ConditionMessage
    }

    # Return object
    Return $m_Result;

}
# SIG # Begin signature block
# MIIa+wYJKoZIhvcNAQcCoIIa7DCCGugCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUE/feMsm6uRNHziGQG04Rpbyv
# lb+gghTvMIIFJDCCBAygAwIBAgIQCpJdJFWANibhh6AFcJolkDANBgkqhkiG9w0B
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
# MQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUhyfDXJwC873xeYmcdjBF
# hADw+x0wZAYKKwYBBAGCNwIBDDFWMFSgOIA2AEMAaQB0AHIAaQB4ACAAUwB1AHAA
# cABvAHIAdABhAGIAaQBsAGkAdAB5ACAAVABvAG8AbABzoRiAFmh0dHA6Ly93d3cu
# Y2l0cml4LmNvbSAwDQYJKoZIhvcNAQEBBQAEggEAq3CmeDtQX32dv4kIYJoZmLaA
# /teBs0bXJGCqtB9bOyDdgneZG+F+vINl7WK/M+8FE0sdfgJVNcn/VbKNnui0UOct
# zl6polEke+YSYC1sRtMNoc7VYxq9BbG0THRJA+B44Jvxu1f70wBWzvu/zY96YrJ5
# mwTZ3QTU8TcHvykWLt6C8IOFG056yxG6ui+QZ5sFitRnYEiLGDK9FYKrhLeMHcG5
# eueypB2DkznA17aGzOKCx9+tzdr0pgzVPagLKF/7koijDt5yeRdJJQ3SdG3KmcmD
# N8fZWXah7dFTLmWgCiA31hUT76tWvW2JBGTQ2h5m4wrMOJwd1o+J/xufbwfGwKGC
# Av0wggL5BgkqhkiG9w0BCQYxggLqMIIC5gIBATCBhjByMQswCQYDVQQGEwJVUzEV
# MBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29t
# MTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgVGltZXN0YW1waW5n
# IENBAhAKkl0kVYA2JuGHoAVwmiWQMA0GCWCGSAFlAwQCAQUAoIIBNDAYBgkqhkiG
# 9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yMDA0MDcwOTE3NTJa
# MC8GCSqGSIb3DQEJBDEiBCCUVqPTEMpBCyOTj1ljuQ0AEQT9qgBwOfC+zFU3wdT0
# 6zCByAYLKoZIhvcNAQkQAi8xgbgwgbUwgbIwga8EILAqztuhstdlrNbpxQZ6VhvR
# VOGFMgwcz15jJralby6jMIGKMHakdDByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMM
# RGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQD
# EyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgVGltZXN0YW1waW5nIENBAhAKkl0k
# VYA2JuGHoAVwmiWQMA0GCSqGSIb3DQEBAQUABIIBAGjfpRDCnW1R4dbD4USOg/fc
# AAkOOUAHvFrnmx+VndaEnPx79gto9AzTsjPYX9Zi3oB6bM15cy1mMyKj2WQfKG4+
# F9P+HZG7rdXscp5A5ayQxEx8WN394UOV9pfd0YyfHVXYwD389QJqgmFOLF5N3oB8
# DybDnjmIwG+Nv7FigrbC8RtyR5MAQTVB7PVgUd8aijz0tZDLIt7gXNb8grZOZPOo
# k+yq7I1HAyXfr1KgUN5dac9cQ688jC6nNJpAugG+xuzUDPKKZU/IoEOyDrVFCCJY
# cZsC4IV7cwasgRjj44k5v6YyWSxSEwVAh1faGFTpHdT59JQYMR0Q0pIv7fOaz50=
# SIG # End signature block
