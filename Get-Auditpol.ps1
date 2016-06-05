<#
Get-Auditpol v1.0
Kurt Falde MSFT
Script to gather Auditpol and other Audit relevant output from remote targetted systems and gather back to system running this script.
Goal is to gather the current effective audit policy from all systems in a Forest vs trying to figure out what policy 'should' be from GPO's etc

Requirements:
    Uses WMI / RPC to gather data so must have WMI/RPC connectivity to all systems from a network connectivity perspective
    Must utilize an account with administrative access to all hosts in the forest i.e. Enterprise Admin type of account.
    Copies back auditpol output via Admin Shares on systems so those must be enabled
#>

Import-Module poshrsjob
Import-Module activedirectory

#Number of Runspaces to use
$RunspaceThreads = 1000

#Set Working Directory
cd C:\get-auditpol

#Create Output Directories for today's date
$ResultsPath = "C:\Get-Auditpol\Data"
New-Item -ItemType Directory $ResultsPath -Force

#Create Sets of computers to iterate through

    #Create set of all DC's in Forest
    $DomainControllers = (Get-ADForest).Domains | %{ (Get-ADDomainController -Filter * -Server $_) }

    #Create set of all currently supported Workstation OS's in the Forest
    $Workstations = (Get-ADForest).Domains | %{ (Get-ADComputer -Filter 'OperatingSystem -notlike "*server*" -and OperatingSystemVersion -ge "6"' -Server $_) }

    #Create set of all currently supported Server OS's in the Forest
    $Servers = (Get-ADForest).Domains | %{ (Get-ADComputer -Filter 'OperatingSystem -like "*server*" -and OperatingSystemVersion -ge "6" -and PrimaryGroupID -ne "516"' -Server $_ -Properties DistinguishedName,DNSHostName,Name,OperatingSystem,OperatingSystemVersion ) }

#Send computer arrays to Runspace Jobs

    #MetaResults Runspace Jobs
        $DCsMetaResultsFile = $ResultsPath + "\DCsMetaResults.csv"
        If(Test-Path -Path $DCsMetaResultsFile){del $DCsMetaResultsFile}
        $DCsmtx = New-Object System.Threading.Mutex($false, "DCsMutex")
        $DCsScriptBlock = get-command .\DCsScriptBlock.ps1 | select -ExpandProperty ScriptBlock
        $DomainControllers | Start-RSJob -ScriptBlock $DCsScriptBlock -name {$_} -Throttle $RunspaceThreads -ArgumentList $DCsmtx, $DCsMetaResultsFile

        $WorkstationsMetaResultsFile = $ResultsPath + "\WorkstationsMetaResults.csv"
        If(Test-Path -Path $WorkstationsMetaResultsFile){del $WorkstationsMetaResultsFile}
        $Workstationsmtx = New-Object System.Threading.Mutex($false, "WorkstationsMutex")
        $WorkstationsScriptBlock = get-command .\WorkstationsScriptBlock.ps1 | select -ExpandProperty ScriptBlock
        $Workstations | Start-RSJob -ScriptBlock $WorkstationsScriptBlock -name {$_} -Throttle $RunspaceThreads -ArgumentList $Workstationsmtx, $WorkstationsMetaResultsFile

        $ServersMetaResultsFile = $ResultsPath + "\ServersMetaResults.csv"
        If(Test-Path -Path $ServersMetaResultsFile){del $ServersMetaResultsFile}
        $Serversmtx = New-Object System.Threading.Mutex($false, "ServersMutex")
        $ServersScriptBlock = get-command .\ServersScriptBlock.ps1 | select -ExpandProperty ScriptBlock
        $Servers | Start-RSJob -ScriptBlock $ServersScriptBlock -name {$_} -Throttle $RunspaceThreads -ArgumentList $Serversmtx, $ServersMetaResultsFile

    #Auditpol Runspace Jobs    
        $DCAuditPolResultsFile = $ResultsPath + "\DCAuditPolResults.csv"
        If(Test-Path -Path $DCAuditPolResultsFile){del $DCAuditPolResultsFile}
        $DCAuditPolmtx = New-Object System.Threading.Mutex($false, "DCAuditPolMutex")
        $DCAuditPolScriptBlock = get-command .\DCAuditPolScriptBlock.ps1 | select -ExpandProperty ScriptBlock
        $DomainControllers | Start-RSJob -ScriptBlock $DCAuditPolScriptBlock -name {$_} -Throttle $RunspaceThreads -ArgumentList $DCAuditPolmtx, $DCAuditPolResultsFile

        $WorkstationAuditPolResultsFile = $ResultsPath + "\WorkstationAuditPolResults.csv"
        If(Test-Path -Path $WorkstationAuditPolResultsFile){del $WorkstationAuditPolResultsFile}
        $WorkstationAuditPolmtx = New-Object System.Threading.Mutex($false, "WorkstationAuditPolMutex")
        $WorkstationAuditPolScriptBlock = get-command .\WorkstationAuditPolScriptBlock.ps1 | select -ExpandProperty ScriptBlock
        $Workstations | Start-RSJob -ScriptBlock $WorkstationAuditPolScriptBlock -name {$_} -Throttle $RunspaceThreads -ArgumentList $WorkstationAuditPolmtx, $WorkstationAuditPolResultsFile

        $ServerAuditPolResultsFile = $ResultsPath + "\ServerAuditPolResults.csv"
        If(Test-Path -Path $ServerAuditPolResultsFile){del $ServerAuditPolResultsFile}
        $ServerAuditPolmtx = New-Object System.Threading.Mutex($false, "ServerAuditPolMutex")
        $ServerAuditPolScriptBlock = get-command .\ServerAuditPolScriptBlock.ps1 | select -ExpandProperty ScriptBlock
        $Servers | Start-RSJob -ScriptBlock $ServerAuditPolScriptBlock -name {$_} -Throttle $RunspaceThreads -ArgumentList $ServerAuditPolmtx, $ServerAuditPolResultsFile
