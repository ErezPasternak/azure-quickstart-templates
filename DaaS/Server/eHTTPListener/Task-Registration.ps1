# Task Scheduler Registration
param(
    [Parameter()][String]$EC_AdminUser = "ericom@ericom.local",
    [Parameter()][String]$EC_AdminPass = "Ericom123$",
    [Parameter()][String]$WebsitePath = "C:\Website",
    [Parameter()][String]$ServerPath = "C:\Server",
    [Parameter()][String]$ServerPort = "2233",
    [Parameter()][String]$baseADGroupRDP = "DaaS-RDP"
)

$startServer = "Start-Server.ps1"
$monitorServer = "Monitor-Server.ps1"

$pathStartServer = Join-Path $ServerPath -ChildPath $startServer;
$pathMonitorServer = Join-Path $ServerPath -ChildPath $monitorServer;

# Register Start-Server
$trigger = New-JobTrigger -AtLogOn -User * -RandomDelay 00:00:02 -ErrorAction SilentlyContinue
$filePath = "C:\Windows\System32\WindowsPowershell\v1.0\powershell.exe"
$argForPS = "-executionPolicy bypass -noexit -file `"$pathStartServer`" `"$EC_AdminUser`" `"$EC_AdminPass`" `"$WebsitePath`" `"$ServerPort`" `"$baseADGroupRDP`""
Register-ScheduledJob -Trigger $trigger -Name "StartPSServer" -ErrorAction SilentlyContinue -ScriptBlock  {
    Write-Verbose "$args[0] $args[1]"
    $exitCode = (Start-Process -Filepath $args[0] -ArgumentList $args[1] -Wait -Passthru).ExitCode
} -ArgumentList $filePath, $argForPS

# Register Monitor-Server
$repeat = (New-TimeSpan -Minute 1)
$option = New-ScheduledJobOption -RunElevated -MultipleInstancePolicy StopExisting
$trigger = New-JobTrigger -Once -At (Get-Date).Date -RepeatIndefinitely -RepetitionInterval $repeat
$filePath = "C:\Windows\System32\WindowsPowershell\v1.0\powershell.exe"
$argForPS = "-executionPolicy bypass -noexit -file `"$pathMonitorServer`" `"$EC_AdminUser`" `"$EC_AdminPass`" `"$WebsitePath`" `"$ServerPath`" `"$ServerPort`" `"$baseADGroupRDP`" "
Register-ScheduledJob -ScheduledJobOption $option  -Trigger $trigger -Name "MonitorPSServer" -ErrorAction SilentlyContinue -ScriptBlock  {
    Write-Verbose "$args[0] $args[1]"
    $exitCode = (Start-Process -Filepath $args[0] -ArgumentList $args[1] -Wait -Passthru).ExitCode
} -ArgumentList $filePath, $argForPS