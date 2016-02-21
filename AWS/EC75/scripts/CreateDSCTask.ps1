$action = New-ScheduledTaskAction –Execute PowerShell.exe -Argument "-NonInt -Command 'Invoke-CimMethod -Namespace root/Microsoft/Windows/DesiredStateConfiguration –ClassName MSFT_DSCLocalConfigurationManager -MethodName PerformRequiredConfigurationChecks -Arg @{Flags = [System.UInt32]3 }'"
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId SYSTEM -LogonType ServiceAccount -RunLevel Highest
$set = New-ScheduledTaskSettingsSet
$task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $set
Register-ScheduledTask '\Microsoft\Windows\Desired State Configuration\DSCBootTask' -InputObject $task