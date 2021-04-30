# This function is used to check if all required XmlElement are defined. Using the .Item() method, because .name would return the name of the parent if element is missing. 
Function Test-CTXOERegistryInput ([Xml.XmlElement]$Params) {
    # 'Path' is the only property that is  required for all registry operations
    If ($Params.Item("path") -isnot [Xml.XmlElement]) {Throw "Required property 'Path' is missing"}; 
    
    # DeleteKey requires only path, but doesn't care about value name. We don't need to validate any other parameters and can exit
    If ($Params.Value -eq "CTXOE_DeleteKey") {Return;}

    # "Name" is just an optional parameter. If it is not specified, Optimizer will just create empty registry key. However if 'Name' is provided, we need to make sure that also 'ValueType' and 'Value' are provided
    If ($Params.Item("name") -is [Xml.XmlElement]) {
        If ($Params.Item("value") -isnot [Xml.XmlElement]) {Throw "Required property Value is missing"};
        If ($Params.Item("valuetype") -isnot [Xml.XmlElement] -and $Params.value -ne "CTXOE_DeleteValue") {Throw "Required property ValueType is missing"};
    } Else {
        If ($Params.Value -eq "CTXOE_DeleteValue") {Throw "Required property Name is missing"};
    }
    
}

Function Invoke-CTXOERegistryAnalyze ([Xml.XmlElement]$Params) {
    Test-CtxOEREgistryInput -Params $Params

    # When modifications are made to default user, we need to load the registry hive file first
    # Since there are few different places where code can be returned in Test-CTXOERegistryValue function, we are handling hive loading here

    [Boolean]$m_IsDefaultUserProfile = $Params.Path -like "HKDU\*" -or $Params.Path -like "HKEY_USERS\DefaultUser\*";

    If ($m_IsDefaultUserProfile) {
            # Mount DefaultUser
            Reg Load "HKU\DefaultUser" "C:\Users\Default\NTUSER.DAT" | Out-Null;
            New-PSDrive -Name DefaultUser -PSProvider Registry -Root HKEY_USERS\DefaultUser | Out-Null;
    
            # Replace HKDU\ with actual registry path
            $Params.Path = $Params.Path -Replace "HKDU\\", "HKEY_USERS\DefaultUser\";
    }

    # Using psbase.InnerText because it's the only way how to handle (optional) XML elements. If we use $Params.Name and 'name' doesn't exist, parent element (params) is used by function instead.
    [Hashtable]$m_Result = CTXOE\Test-CTXOERegistryValue -Key $Params.Path -Name $Params.Item("name").psbase.InnerText -Value $Params.Item("value").psbase.InnerText
    $Global:CTXOE_Result = $m_Result.Result
    $Global:CTXOE_Details = $m_Result.Details

    If ($m_IsDefaultUserProfile) {
        # Unmount DefaultUser
        Remove-PSDrive -Name DefaultUser;
        [GC]::Collect();
        Reg Unload "HKU\DefaultUser" | Out-Null;
    }
    
}

Function Invoke-CTXOERegistryExecuteInternal ([Xml.XmlElement]$Params, [Boolean]$RollbackSupported = $False) {
    Test-CtxOEREgistryInput -Params $Params

    # When modifications are made to default user, we need to load the registry hive file first
    # Since there are few different places where code can be returned in Test-CTXOERegistryValue function, we are handling hive loading here

    [Boolean]$m_IsDefaultUserProfile = $Params.Path -Like "HKDU\*" -or $Params.Path -Like "HKEY_USERS\DefaultUser\*";

    If ($m_IsDefaultUserProfile) {
            # Mount DefaultUser
            Reg Load "HKU\DefaultUser" "C:\Users\Default\NTUSER.DAT" | Out-Null;
            New-PSDrive -Name DefaultUser -PSProvider Registry -Root HKEY_USERS\DefaultUser | Out-Null;
    
            # Replace HKDU\ with actual registry path
            $Params.Path = $Params.Path -Replace "HKDU\\","HKEY_USERS\DefaultUser\";
    }

    # Test if value is already configured or not
    [Hashtable]$m_Result = CTXOE\Test-CTXOERegistryValue -Key $Params.Path -Name $Params.Item("name").psbase.InnerText -Value $Params.Item("value").psbase.InnerText
    
    # If the value is not configured, change it
    If ($m_Result.Result -ne $true) {
        [Hashtable]$m_Result = CTXOE\Set-CTXOERegistryValue -Key $Params.Path -ValueType $Params.Item("valuetype").psbase.InnerText -Value $Params.Item("value").psbase.InnerText -Name $Params.Item("name").psbase.InnerText
        $Global:CTXOE_SystemChanged = $true;
        
        If ($RollbackSupported) {
            [Xml.XmlDocument]$m_RollbackElement = CTXOE\ConvertTo-CTXOERollbackElement -Element $Params
            $m_RollbackElement.rollbackparams.value = $m_Result.OriginalValue.ToString();
            $Global:CTXOE_ChangeRollbackParams = $m_RollbackElement
        }
    }

    $Global:CTXOE_Result = $m_Result.Result
    $Global:CTXOE_Details = $m_Result.Details

    If ($m_IsDefaultUserProfile) {
        # Unmount DefaultUser
        Remove-PSDrive -Name DefaultUser;
        [GC]::Collect();
        Reg Unload "HKU\DefaultUser" | Out-Null;
    }
}

Function Invoke-CTXOERegistryExecute ([Xml.XmlElement]$Params) {
    Invoke-CTXOERegistryExecuteInternal -Params $Params -RollbackSupported $True
}

Function Invoke-CTXOERegistryRollback ([Xml.XmlElement]$Params) {
    Invoke-CTXOERegistryExecuteInternal -Params $Params -RollbackSupported $False
}
# SIG # Begin signature block
# MIIa+wYJKoZIhvcNAQcCoIIa7DCCGugCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUp0wagVClsN8G5qg6LDc0X+9f
# nW2gghTvMIIFJDCCBAygAwIBAgIQCpJdJFWANibhh6AFcJolkDANBgkqhkiG9w0B
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
# MQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUjwSKbERjHrRa2V3NR8TF
# BS7ivN0wZAYKKwYBBAGCNwIBDDFWMFSgOIA2AEMAaQB0AHIAaQB4ACAAUwB1AHAA
# cABvAHIAdABhAGIAaQBsAGkAdAB5ACAAVABvAG8AbABzoRiAFmh0dHA6Ly93d3cu
# Y2l0cml4LmNvbSAwDQYJKoZIhvcNAQEBBQAEggEAgkavGqdC9mycV3No6NYvscdC
# 2SJxlovZilJ7SlrL4RBK6nm3s57vUcle53DVTFgpaeRR173ZZEqMq3w1n5QKV3Kr
# IB40pFYJq+4Yd7mHU002nREPSjD3Vft1G82ThGWpwOufv7CJBO7NmcVK/0YIfDfA
# 1CXYYSNMPrjR7JB8+avdCFY50L9429MBPWMLKuab1YjUmbMX3sBUGydOh/rifA9x
# MmFLn5YCtXzoWf9iuOSpIMVBqNlUCJwmLKiqrqFa4MHhS6NUfKSViXuqZMrs3d7x
# 3qdF9m1Rjb4PgO+o6IxVDvycirGZAJT64wBrOU53AU88BP4wl2zTGk6LmXrQcaGC
# Av0wggL5BgkqhkiG9w0BCQYxggLqMIIC5gIBATCBhjByMQswCQYDVQQGEwJVUzEV
# MBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29t
# MTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgVGltZXN0YW1waW5n
# IENBAhAKkl0kVYA2JuGHoAVwmiWQMA0GCWCGSAFlAwQCAQUAoIIBNDAYBgkqhkiG
# 9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yMDA0MDcwOTE3NDha
# MC8GCSqGSIb3DQEJBDEiBCDK4m8K2b6QUQEQwnFETfRMiW50EfTZc0btZ9hF/211
# BzCByAYLKoZIhvcNAQkQAi8xgbgwgbUwgbIwga8EILAqztuhstdlrNbpxQZ6VhvR
# VOGFMgwcz15jJralby6jMIGKMHakdDByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMM
# RGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQD
# EyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgVGltZXN0YW1waW5nIENBAhAKkl0k
# VYA2JuGHoAVwmiWQMA0GCSqGSIb3DQEBAQUABIIBADGLkRxS2FTO/G3L38c4mmTW
# PtdWlGsAm0oOAuNs83RdD+oTOdEf4OweKHlqTbPNGTGpaguoH5jdVjrwFc/i2qlO
# l8gHNAobICqjMgppk3g1OlYYWh40jGXMaloBnwGfdAnyY4cgrsW6sFYyDtfLk+p1
# trFqBLIRVqvBNvdxFEnTMGPo+lPXPTX4D46u/N13JdAZt5uHAQR0wkLuwGdn+m1H
# j66nNgjaYrHL3Lybk99F3lvoKLPE7d8DfU9IPguymHJrrnqC4rXLCR+dbWk+OOIq
# kkLECC0NkvVGotnpt7jWG51AnKPeenaLRq+Neh1vsooWRme9cbzy6Ke3cO0rlvA=
# SIG # End signature block
