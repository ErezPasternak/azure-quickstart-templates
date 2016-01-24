# TODO: rename this file: Start-Server.ps1
param(
    [Parameter(Mandatory)][String]$EC_AdminUser,
    [Parameter(Mandatory)][String]$EC_AdminPass
)
Import-Module HTTPListener -Force
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
Start-HTTPListener -verbose -port 1232 -path $scriptDir -AdminUser $EC_AdminUser -AdminPass -$EC_AdminPass
