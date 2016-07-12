<#

Features:
    1) This script reads the event log "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational" from multiple servers and outputs the human-readable results to a CSV.

Instructions:
    1) Before you run, edit this line to include one or several of your own servers.
    
Requirements:
    1) TBD
    
 
April 8 2015 - Version 0.2
Mike Crowley
 
http://BaselineTechnologies.com
 
#>


$SessionHosts = @('Server2', 'Server3', 'Server4', 'Server5')

foreach ($Server in $SessionHosts) {

    $LogFilter = @{
        LogName = 'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'
        ID = 21, 23, 24, 25
        }

    $AllEntries = Get-WinEvent -FilterHashtable $LogFilter -ComputerName $Server

    $AllEntries | Foreach { 
           $entry = [xml]$_.ToXml()
        [array]$Output += New-Object PSObject -Property @{
            TimeCreated = $_.TimeCreated
            User = $entry.Event.UserData.EventXML.User
            IPAddress = $entry.Event.UserData.EventXML.Address
            EventID = $entry.Event.System.EventID
            ServerName = $Server
            }        
           } 

}

$FilteredOutput += $Output | Select TimeCreated, User, ServerName, IPAddress, @{Name='Action';Expression={
            if ($_.EventID -eq '21'){"logon"}
            if ($_.EventID -eq '22'){"Shell start"}
            if ($_.EventID -eq '23'){"logoff"}
            if ($_.EventID -eq '24'){"disconnected"}
            if ($_.EventID -eq '25'){"reconnection"}
            }
        }

$Date = (Get-Date -Format s) -replace ":", "."
$FilteredOutput | Sort TimeCreated | Export-Csv $env:USERPROFILE\Desktop\$Date`_RDP_Report.csv -NoTypeInformation


#End
