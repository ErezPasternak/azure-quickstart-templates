param(
    [string]
    $Command
)

try {
    $action = New-ScheduledTaskAction –Execute PowerShell.exe -Argument "-NonInt -Command '$Command'"
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId SYSTEM -LogonType ServiceAccount -RunLevel Highest
    $set = New-ScheduledTaskSettingsSet
    $task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $set
    Register-ScheduledTask "$([guid]::NewGuid().Guid)" -InputObject $task
}
catch {
    $_.exception.message
}