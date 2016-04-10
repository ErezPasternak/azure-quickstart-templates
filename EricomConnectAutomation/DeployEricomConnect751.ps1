param (
  [switch]$AutoStart = $false
)

Write-Output "AutoStart: $AutoStart"
#Requires -RunAsAdministrator

# loads the BitsTransfer Module
Import-Module BitsTransfer
Write-Host "BitsTransfer Module is loaded"

# Settings Section

#download 
$EC_download_url = "https://www.ericom.com/demos/EricomConnectPOC.exe"
$EC_local_path   = "C:\Windows\Temp\EricomConnectPOC.exe"

#grid
$AdminUser         = "Ericom"
$AdminPassword     = "Ericom123$"
$GridName          = "EricomGrid"
$HostOrIp          = $env:computername
$SaUser            = ""
$SaPassword        = ""
$DatabaseServer    = $env:computername
$DatabaseName      = "EricomGRID"
$ConnectConfigurationToolPath = "\Ericom Software\Ericom Connect Configuration Tool\EricomConnectConfigurationTool.exe"
$UseWinCredentials = "true"
$LookUpHosts       = $env:computername


# Download EricomConnect
function Download-EricomConnect()
{
    Write-Output "Download-EricomConnect  -- Start"

    #if we have an installer near the ps1 file we will use it and not download
    $myInstaller = Join-Path $pwd "EricomConnectPOC.exe"

    if (Test-Path $myInstaller){
        Copy-Item $myInstaller -Destination $EC_local_path
    }
    if (!(Test-Path $EC_local_path )) {
        Write-Output "Downloading $EC_download_url"
       # (New-Object System.Net.WebClient).DownloadFile($EC_download_url, "C:\Windows\Temp\EricomConnectPOC.exe")
       Start-BitsTransfer -Source $EC_download_url -Destination $EC_local_path 
    }
    Write-Output "Download-EricomConnect  -- End"
}

function Install-SingleMachine([string] $sourceFile)
{
    Write-Output "Ericom Connect POC installation has been started."
    $exitCode = (Start-Process -Filepath $sourceFile -NoNewWindow -ArgumentList "/silent LAUNCH_CONFIG_TOOL=False" -Wait -Passthru).ExitCode
    if ($exitCode -eq 0) {
        Write-Output "Ericom Connect Grid Server has been succesfuly installed."
    } else {
        Write-Output "Ericom Connect Grid Server could not be installed. Exit Code: "  $exitCode
    }
    Write-Output "Ericom Connect POC installation has been endded."
}

function Config-CreateGrid($config = $Settings)
{
    Write-Output "Ericom Connect Grid configuration has been started."
    $_adminUser = $AdminUser
    $_adminPass = $AdminPassword
    $_gridName = $GridName
    $_hostOrIp = $HostOrIp
    $_saUser = $SaUser
    $_saPass = $SaUser
    $_databaseServer = $DatabaseServer
    $_databaseName = $DatabaseName

    $configPath = Join-Path $env:ProgramFiles -ChildPath $ConnectConfigurationToolPath.Trim()

    if ($UseWinCredentials -eq $true) {
        Write-Output "Configuration mode: with windows credentials"
        $args = " NewGrid /AdminUser $_adminUser /AdminPassword $_adminPass /GridName $_gridName /HostOrIp $_hostOrIp /DatabaseServer $_databaseServer /DatabaseName $_databaseName /UseWinCredForDBAut"
    } else {
        Write-Output "Configuration mode: without windows credentials"
        $args = " NewGrid /AdminUser $_adminUser /AdminPassword $_adminPass /GridName $_gridName /SaDatabaseUser $_saUser /SaDatabasePassword $_saPass /DatabaseServer $_databaseServer /disconnect /noUseWinCredForDBAut"
    }

    $baseFileName = [System.IO.Path]::GetFileName($configPath);
    $folder = Split-Path $configPath;
    cd $folder;
    $exitCode = (Start-Process -Filepath "$baseFileName" -ArgumentList "$args" -Wait -Passthru).ExitCode
    if ($exitCode -eq 0) {
        Write-Output "Ericom Connect Grid Server has been succesfuly configured."
    } else {
        Write-Output "Ericom Connect Grid Server could not be configured. Exit Code: "  $exitCode
    }
    Write-Output "Ericom Connect Grid configuration has been ended."
}

function Install-Apps
{
    Write-Output "Apps installation has been started."

    iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))

    Write-Output "Installing fireofx"
    choco install -y firefox

    Write-Output "Installing powerpoint.viewer"
    choco install -y powerpoint.viewer

    Write-Output "Installing excel.viewer"
    choco install -y excel.viewer

    Write-Output "Installing bginfo"
    choco install -y bginfo
    
    Write-Output "Installing notepadplusplus.install"
    choco install -y notepadplusplus.install

    Write-Output "Apps installation has been ended."
}

function Setup-Bginfo ([string] $LocalPath)
{
    $GITBase     = "https://raw.githubusercontent.com/ErezPasternak/azure-quickstart-templates/EricomConnect/EricomConnectAutomation/BGinfo/" 
    $GITBginfo   = $GITBase + "BGInfo.zip"
    $GITBgConfig = $GITBase + "bginfo_config.bgi"
    $LocalBgConfig = Join-Path $LocalPath  "bginfo_config.bgi"
    $GITBgWall   = $GITBase + "wall.jpg"
    $localWall   = Join-Path $LocalPath "wall.jpg"

    Start-BitsTransfer -Source $GITBginfo -Destination “C:\BGInfo.zip”
    Expand-ZIPFile –File “C:\BGInfo.zip” –Destination $LocalPath
     
    Start-BitsTransfer -Source $GITBgConfig -Destination $LocalBgConfig 
    Start-BitsTransfer -Source $GITBgWall -Destination $localWall 

    New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -Name BgInfo -PropertyType String -Value "C:\BgInfo\bginfo.exe C:\BgInfo\bginfo_config.bgi /silent /accepteula /timer:0"
    C:\BgInfo\bginfo.exe C:\BgInfo\bginfo_config.bgi /silent /accepteula /timer:0
}

function Expand-ZIPFile($file, $destination)
{
    $shell = new-object -com shell.application
    $zip = $shell.NameSpace($file)
    New-Item -ItemType Directory -Path $destination -Force -ErrorAction SilentlyContinue 
    
    foreach($item in $zip.items())
    {
        $shell.Namespace($destination).copyhere($item)
    }
}

function Install-WindowsFeatures
{
    Install-WindowsFeature Net-Framework-Core
    Install-WindowsFeature RDS-RD-Server
    Install-WindowsFeature Web-Server
    Install-WindowsFeature RSAT-AD-PowerShell
    Install-WindowsFeature NET-Framework-45-Features
}

function ConfigureFirewall
{
    Import-Module NetSecurity
    Set-NetFirewallProfile -Profile Domain -Enabled False
}

function AddUsersToRemoteDesktopGroup
{
    $baseADGroupRDP = "Domain Users"
    Invoke-Command { param([String]$RDPGroup) net localgroup "Remote Desktop Users" "$RDPGroup" /ADD } -computername "localhost" -ArgumentList "$baseADGroupRDP"
 
}

# Main Code 
Install-WindowsFeatures

Download-EricomConnect

Install-SingleMachine -sourceFile C:\Windows\Temp\EricomConnectPOC.exe

Config-CreateGrid -config $Settings

Install-Apps

Setup-Bginfo -LocalPath C:\BgInfo

Write-Output $PSScriptRoot 
#bootstrape apps

if ($AutoStart -eq $true) {
   Start-EricomServices
}
 
