param(
    [Parameter()][String]$EC_AdminUser = "administrator@daas.local",
    [Parameter()][String]$EC_AdminPass = "Mc10vin!!!",
    [Parameter()][String]$WebsitePath = "C:\DaaS-Portal\Website",
    [Parameter()][String]$ServerPort = "2244",
    [Parameter()][String]$baseADGroupRDP = "DaaS-RDP",
    [Parameter()][String]$externalFqdn = "daaswin2k12-ericom-server.daas.local"
)

Set-ExecutionPolicy Unrestricted -Confirm:$false -Force
Unblock-File "C:\Program Files\WindowsPowerShell\Modules\eHTTPListener\eHTTPListener.psd1"
Unblock-File "C:\Program Files\WindowsPowerShell\Modules\eHTTPListener\eHTTPListener.psm1"

function Get-ScriptDirectory
{
  $Invocation = (Get-Variable MyInvocation -Scope 1).Value
  Split-Path $Invocation.MyCommand.Path
}

Import-Module eHTTPListener -Force
Start-HTTPListener -verbose -Port ([convert]::ToInt32($ServerPort)) -AdminUser $EC_AdminUser -AdminPass -$EC_AdminPass -WebsitePath $WebsitePath -BaseADGroupRDP $baseADGroupRDP -externalFqdn $externalFqdn
