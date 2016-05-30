# Task Scheduler Registration
param(
)
try {
    Unregister-ScheduledJob KillIEProcess -Force -Confirm:$false
} catch { }

$PathKillIEProcess = "c:\demos\StopIEAfter5Minutes.ps1"

# Register KillIEProcess
$repeat = (New-TimeSpan -Minute 5)
$option = New-ScheduledJobOption -RunElevated -MultipleInstancePolicy StopExisting
$trigger = New-JobTrigger -Once -At (Get-Date).Date -RepeatIndefinitely -RepetitionInterval $repeat
$filePath = "C:\Windows\System32\WindowsPowershell\v1.0\powershell.exe"
$argForPS = "-executionPolicy bypass -noexit -file `"$PathKillIEProcess`" "
Register-ScheduledJob -ScheduledJobOption $option  -Trigger $trigger -Name "KillIEProcess" -ErrorAction SilentlyContinue -ScriptBlock  {
    Write-Verbose "$args[0] $args[1]"
    $exitCode = (Start-Process -Filepath $args[0] -ArgumentList $args[1] -Wait -Passthru).ExitCode
} -ArgumentList $filePath, $argForPS