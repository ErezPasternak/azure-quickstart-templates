<#
.Synopsis
Stops IE that runs more then $NumberOfSeconds


.NOTES   
Name: StopIEAfter5Minutes
Author: Erez Pasternak
Version: 1.0
DateCreated: 2016-05-29

#>
$NumberOfSeconds = 400
$LogFile = "c:\demos\ie.txt"
get-process -ErrorAction SilentlyContinue -IncludeUserName -name iexplore | ? { ([DateTime]::Now - $_.StartTime).TotalSeconds -gt $NumberOfSeconds } | foreach {(Get-date).ToString() +'  '+  $_.UserName  + " Name: " + $_.Name ,'Id: ' + $_.Id, 'Start:  '+$_.StartTime  +'  '+ 'Duration: ' + (new-timespan $_.StartTime (Get-date))   }  | Out-File -append -filepath $LogFile ; 

get-process -ErrorAction SilentlyContinue -IncludeUserName -name iexplore | ? { ([DateTime]::Now - $_.StartTime).TotalSeconds -gt $NumberOfSeconds } | stop-process -force