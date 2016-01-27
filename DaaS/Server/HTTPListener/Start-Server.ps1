param(
    [Parameter()][String]$EC_AdminUser = "ericom@ericom.local",
    [Parameter()][String]$EC_AdminPass = "Ericom123$",
    [Parameter()][String]$WebsitePath = "C:\Website"
)

function Get-ScriptDirectory
{
  $Invocation = (Get-Variable MyInvocation -Scope 1).Value
  Split-Path $Invocation.MyCommand.Path
}


$modulePath = "$env:ProgramFiles\WindowsPowerShell\Modules";
$moduleName = "eHTTPListener"
New-Item -Path (Join-Path $modulePath -ChildPath $moduleName) -ItemType Directory -Force
$files = Join-Path (Get-ScriptDirectory).ToString() -ChildPath "eHTTPListener.*"
Copy-Item -Path $files -Destination (Join-Path $modulePath -ChildPath $moduleName) -Force -Recurse


Import-Module eHTTPListener -Force
Start-HTTPListener -verbose -port 2222 -AdminUser $EC_AdminUser -AdminPass -$EC_AdminPass -WebsitePath $WebsitePath
