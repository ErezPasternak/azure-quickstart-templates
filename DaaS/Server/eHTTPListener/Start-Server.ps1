param(
    [Parameter()][String]$EC_AdminUser = "admin@test.local",
    [Parameter()][String]$EC_AdminPass = "admin",
    [Parameter()][String]$WebsitePath = "C:\Users\admin\Documents\Website",
    [Parameter()][String]$ServerPort = "2222"
)

function Get-ScriptDirectory
{
  $Invocation = (Get-Variable MyInvocation -Scope 1).Value
  Split-Path $Invocation.MyCommand.Path
}

Import-Module eHTTPListener -Force
Start-HTTPListener -verbose -Port ([convert]::ToInt32($ServerPort)) -AdminUser $EC_AdminUser -AdminPass -$EC_AdminPass -WebsitePath $WebsitePath
