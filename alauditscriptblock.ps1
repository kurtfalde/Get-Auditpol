        Param($alauditmtx, $ALAuditDataFile)


        $DCsmtx, $DCsMetaResultsFile
        $alauditmtx, $ALAuditDataFile

        $computer = $_

        

        #Test Connection and exit if not available

        If((Test-Connection -ComputerName $computer.name -Quiet) -eq $false){exit}

        
        #Creating object to output to .csv

        $aleventcsvdata = New-Object psobject

        $computer = get-adcomputer -Identity $computer 
        $ComputerOU = $computer.DistinguishedName -creplace "^[^,]*,",""       

        #Get events from Microsoft-Windows-AppLocker/EXE and DLL log

        $exedllevents = Get-WinEvent -LogName 'Microsoft-Windows-AppLocker/EXE and DLL' -FilterXPath "*[System[(EventID=8003 or EventID=8004)]]"

        foreach($exedllevent in $exedllevents){
            
            $exedlleventxml = [xml]$exedllevent.ToXml()
        
            $user = (Get-ADUser $exedlleventxml.Event.UserData.RuleAndFileData.TargetUser).UserPrincipalName

            $Computercsv | Add-Member noteproperty ComputerOU $ComputerOU

            Clear-Item $aleventcsvdata
       
            $aleventcsvdata = New-Object PSObject -Property @{            
                MachineName      = $computer.name                 
                MachineOU        = $ComputerOU             
                MachineOS        = $computer.OperatingSystem
                UserName         = $user            
                PolicyName       = $exedlleventxml.Event.UserData.RuleAndFileData.PolicyName           
                CreateDate       = $exedlleventxml.Event.System.TimeCreated           
                EventID          = $exedlleventxml.Event.System.EventID           
                FilePath         = $exedlleventxml.Event.UserData.RuleAndFileData.FilePath         
                FileHash         = $exedlleventxml.Event.UserData.RuleAndFileData.FileHash           
                Fqbn             = $exedlleventxml.Event.UserData.RuleAndFileData.Fqbn           
         
                }

        
            $alauditmtx.WaitOne(300000)
            $aleventcsvdata | Export-Csv $ALAuditDataFile -Encoding ASCII -NoTypeInformation -Append
            $alauditmtx.ReleaseMutex()


        }





        


        


