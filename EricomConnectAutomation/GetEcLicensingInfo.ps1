<#
.Synopsis
Get Ericom Connect Licensing info 

.NOTES   
Name: GetECLicensingInfo
Author: Erez Pasternak
Version: 1.0
DateCreated: 2016-05-29
DateUpdated: 2016-06-02
#>

# list of value to query 
# DatabaseStatus
# GridStatus
# LogMessageQueue
# ActiveRdpSessions
# DisconnectedRdpSessions
# LicenseStatus
# LicenseExpiration
# LicenseMaintenanceExpirationDate
# LicenseNumberOfTerminalServersAllowed
# LicenseNumberOfWorkstationsAllowed
# LicenseNumberOfApplicationsAllowed
# LicenseNumberOfTenantsAllowed


# Active Directory 
$AdminUser = "admin@test.local"
$AdminPassword = "admin"

# Ericom Connect Grid Setting
$GridName = "RDCB785"
$HostOrIp = (Get-NetIPAddress -AddressFamily IPv4)[0].IPAddress # [System.Net.Dns]::GetHostByName((hostname)).HostName


# Internal Code - DO NOT CHANGE  
$global:adminApi = $null
$global:adminSessionId = $null

$ConnectConfigurationToolPath = "\Ericom Software\Ericom Connect Configuration Tool\EricomConnectConfigurationTool.exe"


function Start-EricomConnection
{
	$Assem = Import-EricomLib
	
	$regularUser = New-Object Ericom.CloudConnect.Utilities.SpaceCredentials("regularUser")
	$_adminApi = [Ericom.MegaConnect.Runtime.XapApi.AdministrationProcessingUnitClassFactory]::GetInstance($regularUser)
	
	return $_adminApi
}

function EricomConnectConnector()
{
    if ( $adminSessionId -eq $null)
    {
        $_adminSessionId = ($adminApi.CreateAdminsession($AdminUser, $AdminPassword, "rooturl", "en-us")).AdminSessionId 
        return $_adminSessionId
    }
}
function EricomConnectDisconnector()
{
    if ( $adminSessionId -ne $null)
    {
        $adminApi.LogoutAdminSession($adminSessionId)
    }
}

function ConnectToGrid()
{
    $global:adminApi = Start-EricomConnection
    $global:adminSessionId = EricomConnectConnector
}


Function Import-EricomLib
{
	$XAPPath = "C:\Program Files\Ericom Software\Ericom Connect Configuration Tool\"
	
	function Get-ScriptDirectory
	{
		$Invocation = (Get-Variable MyInvocation -Scope 1).Value
		Split-Path $Invocation.MyCommand.Path
	}
	
	$MegaConnectRuntimeApiDll = Join-Path ($XAPPath)  "MegaConnectRuntimeXapApi.dll"
	$CloudConnectUtilitiesDll = Join-Path ($XAPPath)  "CloudConnectUtilities.dll"
	
	
	add-type -Path (
	$MegaConnectRuntimeApiDll,
	$CloudConnectUtilitiesDll
	)
                                                                                                                    `
	$Assem = (
	$MegaConnectRuntimeApiDll,
	$CloudConnectUtilitiesDll
	)
	
	return $Assem
}

Function GetLicenseInfo($LabelToFind)
{

    ConnectToGrid
    EricomConnectConnector

	$Status = $adminApi.GetStatusIndicators($adminSessionId)
  
    foreach ($element in $Status) {
    Write-Output $element.Label;
    Write-Output $element.Value[0];
    Write-Output $element.Value[1];
    
    if ($element.Label.Contains($LabelToFind) )
       {
            Write-Output $element.Value;
            return $element.Value;
        }
    }
}

function GetDaysTillExpaire {

    $res = GetLicenseInfo ("LicenseExpiration")
    $TS = New-TimeSpan -Start (Get-Date) -End $res[0]
    return $TS.Days
}

function GetNumberOfLicense {

    $Num = GetLicenseInfo ("LicenseStatus")
   
    return $TS.Days
}
GetNumberOfLicense
GetDaysTillExpaire






