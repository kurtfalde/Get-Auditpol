
        Param($ServerAuditPolmtx, $ServerAuditPolResultsFile)
        $Server = $_
        $Servername = $Server.Name

        #Test Connection and exit if not available
        If((Test-Connection -ComputerName $Servername -Quiet) -eq $false){exit}

        #Invoke-WMI used to not be dependent on PoSH Remoting being enabled
        Invoke-WmiMethod -ComputerName $Servername -Class Win32_Process -Name Create -ArgumentList "auditpol /backup /file:c:\windows\$($Servername)-Auditpol.csv"
        Sleep -Seconds 10
        $AuditPolCSV = Import-Csv \\$Servername\C$\windows\$Servername-Auditpol.csv

        $ServerAuditPolmtx.WaitOne(300000)
        $AuditPolCSV | Export-Csv $ServerAuditPolResultsFile -Encoding ASCII -NoTypeInformation -Append
        $ServerAuditPolmtx.ReleaseMutex()

        Remove-Item \\$Servername\C$\windows\$Servername-Auditpol.csv