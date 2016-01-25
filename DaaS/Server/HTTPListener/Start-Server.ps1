param(
    [Parameter(Mandatory)][String]$EC_AdminUser,
    [Parameter(Mandatory)][String]$EC_AdminPass,
    [Parameter()][String]$WebsitePath = "C:\Website"
)

function Get-ScriptDirectory
{
  $Invocation = (Get-Variable MyInvocation -Scope 1).Value
  Split-Path $Invocation.MyCommand.Path
}

$modulePath = "$env:ProgramFiles\WindowsPowerShell\Modules";
$moduleName = "HTTPListener"
New-Item -Path (Join-Path $modulePath -ChildPath $moduleName) -ItemType Directory -Force
$files = Join-Path (Get-ScriptDirectory).ToString() -ChildPath "HTTPListener.*"
Copy-Item -Path $files -Destination (Join-Path $modulePath -ChildPath $moduleName) -Force -Recurse


Import-Module HTTPListener -Force
Start-HTTPListener -verbose -port 1232 -AdminUser $EC_AdminUser -AdminPass -$EC_AdminPass -WebsitePath $WebsitePath
