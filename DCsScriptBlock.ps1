        Param($DCsmtx, $DCsMetaResultsFile)
        $computer = $_
        
        #Test Connection and exit if not available
        If((Test-Connection -ComputerName $computer.name -Quiet) -eq $false){exit}
         
        #Audit Metadata Section for System
        #Creating object to output to .csv
        $Computercsv = New-Object psobject
                
        $Computercsv | Add-Member noteproperty "Machine Name" $computer.name

        $Computercsv | Add-Member noteproperty "Operating System" $computer.OperatingSystem

        $ComputerOU = $computer.DistinguishedName -creplace "^[^,]*,",""
        $Computercsv | Add-Member noteproperty ComputerOU $ComputerOU
        
        $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer.name)

        #Determine whether Advanced Audit Policies Forced is set and add to CSV Output object
        $RegKey= $Reg.OpenSubKey("SYSTEM\\CurrentControlSet\\Control\\Lsa")
        $AdvancedAuditForce = $RegKey.GetValue("scenoapplylegacyauditpolicy")
        If ($AdvancedAuditForce -ne 1){$AdvancedAuditForce = $false} else {$AdvancedAuditForce = $true}
        $Computercsv | Add-Member noteproperty "ForceAdvancedAudit" $AdvancedAuditForce

        #Determine whether CMD Line Auditing enabled for Process Creation Events and add to CSV Output object
        $RegKey= $Reg.OpenSubKey("Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System\\Audit")
        $ProcCreationCMDLine = $RegKey.GetValue("ProcessCreationIncludeCmdLine_Enabled")
        If ($ProcCreationCMDLine -ne 1){$ProcCreationCMDLine = $false} else {$ProcCreationCMDLine = $true}
        $Computercsv | Add-Member noteproperty "ProcessCreationCMDLineAuditing" $ProcCreationCMDLine

        #Determine whether AppLocker Appx Logging is enabled either in Enforced or Audit mode
        $RegKey= $Reg.OpenSubKey("SOFTWARE\\Policies\\Microsoft\\Windows\\SrpV2\\Appx")
        $AppxLogging = $RegKey.GetValue("EnforcementMode")
        If ($AppxLogging -eq 1 -or $AppxLogging -eq 0){$AppxLogging = $true} else {$AppxLogging = $false}
        $Computercsv | Add-Member noteproperty "AppxLoggingEnabled" $AppxLogging
        
        #Determine whether AppLocker DLL Logging is enabled either in Enforced or Audit mode
        $RegKey= $Reg.OpenSubKey("SOFTWARE\\Policies\\Microsoft\\Windows\\SrpV2\\Dll")
        $DllLogging = $RegKey.GetValue("EnforcementMode")
        If ($DllLogging -eq 1 -or $DllLogging -eq 0){$DllLogging = $true} else {$DllLogging = $false}
        $Computercsv | Add-Member noteproperty "DllLoggingEnabled" $DllLogging

        #Determine whether AppLocker EXE Logging is enabled either in Enforced or Audit mode
        $RegKey= $Reg.OpenSubKey("SOFTWARE\\Policies\\Microsoft\\Windows\\SrpV2\\Exe")
        $ExeLogging = $RegKey.GetValue("EnforcementMode")
        If ($ExeLogging -eq 1 -or $ExeLogging -eq 0){$ExeLogging = $true} else {$ExeLogging = $false}
        $Computercsv | Add-Member noteproperty "ExeLoggingEnabled" $ExeLogging

        #Determine whether AppLocker MSI Logging is enabled either in Enforced or Audit mode
        $RegKey= $Reg.OpenSubKey("SOFTWARE\\Policies\\Microsoft\\Windows\\SrpV2\\Msi")
        $MsiLogging = $RegKey.GetValue("EnforcementMode")
        If ($MsiLogging -eq 1 -or $MsiLogging -eq 0){$MsiLogging = $true} else {$MsiLogging = $false}
        $Computercsv | Add-Member noteproperty "MsiLoggingEnabled" $MsiLogging

        #Determine whether AppLocker Script Logging is enabled either in Enforced or Audit mode
        $RegKey= $Reg.OpenSubKey("SOFTWARE\\Policies\\Microsoft\\Windows\\SrpV2\\Script")
        $ScriptLogging = $RegKey.GetValue("EnforcementMode")
        If ($ScriptLogging -eq 1 -or $ScriptLogging -eq 0){$ScriptLogging = $true} else {$ScriptLogging = $false}
        $Computercsv | Add-Member noteproperty "ScriptLoggingEnabled" $ScriptLogging

        #Determine whether PowerShell Script Block Logging is enabled
        $RegKey= $Reg.OpenSubKey("SOFTWARE\\Policies\\Microsoft\\Windows\\PowerShell\\ScriptBlockLogging")
        $PSScriptBlockLogging = $RegKey.GetValue("EnableScriptBlockLogging")
        If ($PSScriptLogging -eq 1){$PSScriptBlockLogging = $true} else {$PSScriptBlockLogging = $false}
        $Computercsv | Add-Member noteproperty "PSScriptBlockLoggingEnabled" $PSScriptBlockLogging

        #Determine whether PowerShell Transcription Logging is enabled
        $RegKey= $Reg.OpenSubKey("SOFTWARE\\Policies\\Microsoft\\Windows\\PowerShell\\Transcription")
        $PSTranscriptLogging = $RegKey.GetValue("EnableTranscripting")
        If ($PSTranscriptLogging -eq 1){$PSTranscriptLogging = $true} else {$PSTranscriptLogging = $false}
        $Computercsv | Add-Member noteproperty "PSTranscriptLoggingEnabled" $PSTranscriptLogging

        #Determine whether the Special Groups audit key has been configured with any groups
        $RegKey= $Reg.OpenSubKey("System\\CurrentControlSet\\Control\\Lsa\\Audit")
        $SpecialGroupsAudit = $RegKey.GetValue("SpecialGroups")
        If ($SpecialGroupsAudit -ne $null){$SpecialGroupsAudit = $true} else {$SpecialGroupsAudit = $false}
        $Computercsv | Add-Member noteproperty "SpecialGroupsAuditConfigured" $SpecialGroupsAudit


        $DCsmtx.WaitOne(300000)
        $Computercsv | Export-Csv $DCsMetaResultsFile -Encoding ASCII -NoTypeInformation -Append
        $DCsmtx.ReleaseMutex()