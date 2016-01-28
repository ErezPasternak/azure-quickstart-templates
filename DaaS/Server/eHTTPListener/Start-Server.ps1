param(
    [Parameter()][String]$EC_AdminUser = "ericom@ericom.local",
    [Parameter()][String]$EC_AdminPass = "Ericom123$",
    [Parameter()][String]$WebsitePath = "C:\Website",
    [Parameter()][String]$ServerPort = "2222"
)

function Get-ScriptDirectory
{
  $Invocation = (Get-Variable MyInvocation -Scope 1).Value
  Split-Path $Invocation.MyCommand.Path
}

Import-Module eHTTPListener -Force
Start-HTTPListener -verbose -port ([convert]::ToInt32($ServerPort)) -AdminUser $EC_AdminUser -AdminPass -$EC_AdminPass -WebsitePath $WebsitePath
