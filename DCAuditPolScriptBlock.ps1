        Param($DCAuditPolmtx, $DCAuditPolResultsFile)
        $DC = $_

        #Test Connection and exit if not available
        If((Test-Connection -ComputerName $DC.name -Quiet) -eq $false){exit}

        #Invoke-WMI used to not be dependent on PoSH Remoting being enabled
        Invoke-WmiMethod -ComputerName $DC -Class Win32_Process -Name Create -ArgumentList "auditpol /backup /file:c:\windows\$($DC)-Auditpol.csv"
        Sleep -Seconds 10
        $AuditPolCSV = Import-Csv \\$DC\C$\windows\$DC-Auditpol.csv
        
        $DCAuditPolmtx.WaitOne(300000)
        $AuditPolCSV | Export-Csv $DCAuditPolResultsFile -Encoding ASCII -NoTypeInformation -Append
        $DCAuditPolmtx.ReleaseMutex()

        Remove-Item \\$DC\C$\windows\$DC-Auditpol.csv