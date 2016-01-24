#to start working 
#a. put CloudConnect.exe on the desktop.
#b. fix the wanted config in the EricomConnect.xml
#c. run the script.

$myDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# Import settings from config file
[xml]$Settings = Get-Content "$myDir\EricomConnect.xml"

#remove the first install connect app.
function UnInstall-Grid([string] $UnInstallsourceFile)
{
    Write-Output "Starting to uninstall Ericom Connect Grid Server."
    $exitCode = (Start-Process -Filepath $UnInstallsourceFile "/silent /remove" -Wait -Passthru).ExitCode
    if ($exitCode -eq 0) {
        Write-Output "Ericom Connect Grid Server has been succesfuly UnInstalled."
    } else {
        Write-Output "Ericom Connect Grid Server could not be UnInstalled. Exit Code: "  $exitCode
    }
}

<#
$installedServer = Get-WmiObject -Class win32_product #-Filter "Name like '%Ericom%'"
$installedServer 
foreach($item in $installedServer)
{
}
"------------------------------------------------------------"
$installedServer = Get-WmiObject -Class win32_product -Filter "Name like '%Ericom Connect%'"
$installedServer
#
#$installedServer.Uninstall()
#>

function Install-SingleMachine([string] $sourceFile)
{
    Write-Output "Ericom Connect installation has been started."
    $exitCode = (Start-Process -Filepath $sourceFile -NoNewWindow -ArgumentList "/silent LAUNCH_CONFIG_TOOL=False" -Wait -Passthru).ExitCode
    if ($exitCode -eq 0) {
        Write-Output "Ericom Connect Grid Server has been succesfuly installed."
    } else {
        Write-Output "Ericom Connect Grid Server could not be installed. Exit Code: "  $exitCode
    }
}


function Config-CreateGrid($config = $Settings)
{
    Write-Output "Ericom Connect Grid configuration has been started."
    $_adminUser      = $config.Configuration.GridConfiguration.AdminUser
    $_adminPass      = $config.Configuration.GridConfiguration.AdminPassword
    $_gridName       = $config.Configuration.GridConfiguration.GridName
    $_hostOrIp       = $config.Configuration.GridConfiguration.HostOrIp
    $_saUser         = $config.Configuration.GridConfiguration.SaUser
    $_saPass         = $config.Configuration.GridConfiguration.SaPassword
    $_databaseServer = $config.Configuration.GridConfiguration.DatabaseServer
    $_databaseName   = $config.Configuration.GridConfiguration.DatabaseName

    $configPath = $env:ProgramFiles + $config.Configuration.GridConfiguration.ConnectConfigurationToolPath

    if ($config.Configuration.GridConfiguration.UseWinCredentials -eq $true) {
        Write-Output "Configuration mode: with windows credentials"
        $args = " NewGrid /AdminUser $_adminUser /AdminPassword $_adminPass /GridName $_gridName /HostOrIp $_hostOrIp /DatabaseServer $_databaseServer /DatabaseName $_databaseName /UseWinCredForDBAut"
    } else {
        Write-Output "Configuration mode: without windows credentials"
        $args = " NewGrid /AdminUser $_adminUser /AdminPassword $_adminPass /GridName $_gridName /SaDatabaseUser $_saUser /SaDatabasePassword $_saPass /DatabaseServer $_databaseServer /disconnect /noUseWinCred /DatabaseName $_databaseName"
    }

    $args
    $exitCode = (Start-Process -Filepath $configPath -ArgumentList $args -Wait -Passthru).ExitCode
    if ($exitCode -eq 0) {
        Write-Output "Ericom Connect Grid Server has been succesfuly configured."
    } else {
        Write-Output "Ericom Connect Grid Server could not be configured. Exit Code: "  $exitCode
        exit
    }
}

function Post-Config-Cli{
    $config = $Settings
    $_adminUser      = $config.Configuration.GridConfiguration.AdminUser
    $_adminPass      = $config.Configuration.GridConfiguration.AdminPassword
    $env:EC_ADMIN_USER="ccadmin"
    $env:EC_ADMIN_PASSWORD=".Admin1!"
    $env:Path = 'C:\Program Files\Ericom Software\Ericom Connect Configuration Tool;'+$env:Path

    $cliPath = 'C:\Program Files\Ericom Software\Ericom Connect Configuration Tool\ConnectCLI.exe'
    $Cred = "/adminUser $_adminUser /adminPassword $_adminPass "
    $args1 = "setloglevel verbose"
    $args1
    $exitCode = (Start-Process -Filepath .\ConnectCLI.exe -ArgumentList $args1 -Wait -Passthru).ExitCode
    $exitCode
<#
    $args1 = "systemconfig EsgHostAddress=srv12lo2-4.cloudconnect.local:8012"
    $args1
    $exitCode = (Start-Process -Filepath .\ConnectCLI.exe -ArgumentList $args1 -Wait -Passthru).ExitCode
    $exitCode
#>
    $args1 = "esgconfig common Network" + "$" + "SecuredPort=8012"
    $args1
    $exitCode = (Start-Process -Filepath .\ConnectCLI.exe -ArgumentList $args1 -Wait -Passthru).ExitCode
    $exitCode

    $args1 = "connectionconfig seamless_S_type=ericom"
    $args1
    $exitCode = (Start-Process -Filepath .\ConnectCLI.exe -ArgumentList $args1 -Wait -Passthru).ExitCode
    $exitCode

#Add new Tenant
    $args1 = "tenant add t1"
    $args1
    $exitCode = (Start-Process -Filepath .\ConnectCLI.exe -ArgumentList $args1 -Wait -Passthru).ExitCode
    $exitCode

#Enable clients login
    $args1 = "tenantconfig /tenant t1urlprefix  ClientLoginEnabled=true"
    $args1
    $exitCode = (Start-Process -Filepath .\ConnectCLI.exe -ArgumentList $args1 -Wait -Passthru).ExitCode
    $exitCode
}


function Publish-Apps($config = $Settings)
{
    $_adminUser      = $config.Configuration.GridConfiguration.AdminUser
    $_adminPass      = $config.Configuration.GridConfiguration.AdminPassword
    $scriptToRun = Join-Path ($myDir) publishResorce.ps1 
    [array]$apps = "paint","calculator","notepad","Remote Desktop Connection"

    foreach($app in $apps){
        $Args = " -adminUser $_adminUser -adminPassword $_adminPass -applicationName $app"
        Invoke-Expression "$scriptToRun + $Args" 
    }
}



$installedServer = Get-WmiObject -Class win32_product -Filter "Name like '%Ericom Connect Data Grid%'"
Write-Output "Uninstalling version: " $installedServer.Version

UnInstall-Grid "C:\Program Files (x86)\InstallShield Installation Information\{E79180E2-AE69-4A26-9581-287C2926D2E1}\EricomConnect.exe"

Install-SingleMachine -sourceFile C:\Users\ccadmin\Desktop\EricomConnect.exe

Config-CreateGrid -config $Settings

Post-Config-Cli

Publish-Apps

$installedServer = Get-WmiObject -Class win32_product -Filter "Name like '%Ericom Connect Data Grid%'"
Write-Output "New installed version: " $installedServer.Version

