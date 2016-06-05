
        Param($WorkstationAuditPolmtx, $WorkstationAuditPolResultsFile)
        $Workstation = $_
        $Workstationname = $Workstation.Name
       
        #Test Connection and exit if not available
        If((Test-Connection -ComputerName $Workstationname -Quiet) -eq $false){exit} 

	#Invoke-WMI used to not be dependent on PoSH Remoting being enabled
        Invoke-WmiMethod -ComputerName $Workstationname -Class Win32_Process -Name Create -ArgumentList "auditpol /backup /file:c:\windows\$($Workstationname)-Auditpol.csv"
        Sleep -Seconds 10
        $AuditPolCSV = Import-Csv \\$Workstationname\C$\windows\$Workstationname-Auditpol.csv

        $WorkstationAuditPolmtx.WaitOne(300000)
        $AuditPolCSV | Export-Csv $WorkstationAuditPolResultsFile -Encoding ASCII -NoTypeInformation -Append
        $WorkstationAuditPolmtx.ReleaseMutex()

        Remove-Item \\$Workstationname\C$\windows\$Workstationname-Auditpol.csv

        