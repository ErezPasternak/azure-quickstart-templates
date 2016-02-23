param(	
	[Parameter()][String]$EC_AdminUser = "ericom@ericom.local",
    [Parameter()][String]$EC_AdminPass = "Ericom123$",
    [Parameter()][String]$WebsitePath = "C:\DaaS-Portal\Website",
    [Parameter()][String]$ServerPort = "2233",
    [Parameter()][String]$baseADGroupRDP = "DaaS-RDP",
    [Parameter()][String]$externalFqdn = "localhost"
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
Start-HTTPListener -verbose -Port ([convert]::ToInt32($ServerPort)) -AdminUser $EC_AdminUser -AdminPass $EC_AdminPass -WebsitePath $WebsitePath -BaseADGroupRDP $baseADGroupRDP -externalFqdn $externalFqdn
