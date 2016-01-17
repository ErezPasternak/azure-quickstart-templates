function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

#publishResorce
#$scriptToRun = Join-Path (Get-ScriptDirectory) publishResorce.ps1 
#$Args = " -adminUser ccadmin -adminPassword .Admin1! -applicationName paint"
#Invoke-Expression "$scriptToRun + $Args" 
#or alternatively
#E:\PM\Dev\CloudConnect\Code\CloudConnect\PsScripts\publishResorce.ps1  -adminUser "ccadmin" -adminPassword ".Admin1!" -applicationName "paint"


#$scriptToRun = Join-Path (Get-ScriptDirectory) listOfTS.ps1 
#$Args = " -adminUser ccadmin -adminPassword .Admin1! -State Running"
#Invoke-Expression "$scriptToRun + $Args" 
#or alternatively
#E:\PM\Dev\CloudConnect\Code\CloudConnect\PsScripts\listOfTS.ps1  -adminUser "ccadmin" -adminPassword ".Admin1!" -State "Running"

#$scriptToRun = Join-Path (Get-ScriptDirectory) listOfConnectionForUser.ps1
#$Args = " -adminUser ccadmin -adminPassword .Admin1! -user user-0000000"
#Invoke-Expression "$scriptToRun + $Args" 
#or alternatively
#E:\PM\Dev\CloudConnect\Code\CloudConnect\PsScripts\listOfConnectionForUser.ps1  -adminUser "ccadmin" -adminPassword ".Admin1!" -user "user-0000000"

#$scriptToRun = Join-Path (Get-ScriptDirectory) connectionBlazeFileForAUser.ps1
#$Args = " -adminUser ccadmin -adminPassword .Admin1! -user user-0000000 -app paint#1" 
#Invoke-Expression "$scriptToRun + $Args" 
#or alternatively
#E:\PM\Dev\CloudConnect\Code\CloudConnect\PsScripts\connectionBlazeFileForAUser.ps1  -adminUser "ccadmin" -adminPassword ".Admin1!" -user "user-0000000" -app "paint#1"

$scriptToRun = Join-Path (Get-ScriptDirectory) listOfAllAppsOnaTS.ps1
#$Args = " -adminUser ccadmin -adminPassword .Admin1! -outFile out2.txt" 
$Args = " -adminUser ccadmin -adminPassword .Admin1!" 
Invoke-Expression "$scriptToRun + $Args" 
#or alternatively
#E:\PM\Dev\CloudConnect\Code\CloudConnect\PsScripts\listOfAllAppsOnaTS.ps1  -adminUser "ccadmin" -adminPassword ".Admin1!"
