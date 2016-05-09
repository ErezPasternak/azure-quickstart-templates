

#Requires -RunAsAdministrator

# Settings Section

$domainName = "test.local"

#grid
$AdminUser = "admin@test.local"
$AdminPassword = "admin"
$GridName = "EricomGrid"
$HostOrIp = $env:COMPUTERNAME
$SaUser = ""
$SaPassword = ""
$DatabaseServer = $env:computername
$DatabaseName = "ERICOMCONNECTDB"
$ConnectConfigurationToolPath = "\Ericom Software\Ericom Connect Configuration Tool\EricomConnectConfigurationTool.exe"
$UseWinCredentials = "true"
$LookUpHosts = $env:computername

#export
$ResourceList
$UsersList
$UserGroupsList	


Function Start-EricomConnection
{
	$Assem = Import-EricomLib
	
	$regularUser = New-Object Ericom.CloudConnect.Utilities.SpaceCredentials("regularUser")
	$adminApi = [Ericom.MegaConnect.Runtime.XapApi.AdministrationProcessingUnitClassFactory]::GetInstance($regularUser)
	
	return $adminApi
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

function CreateUser
{
	param (
		[Parameter()]
		[String]$userName,
		[Parameter()]
		[String]$password,
		[Parameter()]
		[String]$domainName = $domainName
	)
	
	$baseADGroupRDP = "Domain Users"
	
	$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
	$AdminSecurePassword = ConvertTo-SecureString -String $AdminPassword -AsPlainText -Force
	$AdminCredentials = New-Object System.Management.Automation.PSCredential ($AdminUser, $AdminSecurePassword);
	
	try
	{
		Write-Host "Creating new AD user <<$username>>" -ForegroundColor Green
		New-ADUser -Server $domainName -PasswordNeverExpires $true -SamAccountName $userName -Name "$userName" -Credential $AdminCredentials -Enabled $true -Verbose -AccountPassword $securePassword
	}
	catch
	{
		Write-Warning "Could not create AD User: $userName"
		Write-Error $_.Exception.Message
	}
	try
	{
		#  Add-ADGroupMember -Server $domainName -Identity (Get-ADGroup $baseADGroupRDP -Server $domainName -Credential $AdminCredentials ) -Members $userName -Credential $AdminCredentials
	}
	catch
	{
		Write-Warning "Could not add $userName to `"$baseADGroupRDP`" AD group"
		Write-Error $_.Exception.Message
	}
}



function GetListOfHostGroups
{
	$adminApi = Start-EricomConnection
	$adminSessionId = $adminApi.CreateAdminsession($AdminUser, $AdminPassword, "rooturl", "en-us");
	[Ericom.MegaConnect.Runtime.XapApi.RemoteHostMembershipComputation]$rhmc = 0;
	$rGroup = $adminApi.CreateRemoteHostGroup($adminSessionId.AdminSessionId, $groupName, $rhmc);
	[System.Collections.Generic.List[String]]$remoteHostsList = New-Object System.Collections.Generic.List[String];
	
	[Ericom.MegaConnect.Runtime.XapApi.RemoteHostSearchConstraints]$rhsc = New-Object Ericom.MegaConnect.Runtime.XapApi.RemoteHostSearchConstraints;
	$rhsc.HostnamePattern = $pattern; #TODO: Update HERE!
	$rhl = $adminApi.GetRemoteHostList($adminSessionId.AdminSessionId, $rhsc)
	foreach ($h in $rhl)
	{
		$remoteHostsList.Add($h.RemoteHostId)
	}
	$rGroup.RemoteHostIds = $remoteHostsList;
	$adminApi.AddRemoteHostGroup($adminSessionId.AdminSessionId, $rGroup) | Out-Null
}
function Export-RemoteHostsGroup
{
}

function Get-RemoteHostsGroup
{
	param (
		
		[Parameter()]
		[string]$groupName,
		[Parameter()]
		[string]$pattern
	)
	
	$adminApi = Start-EricomConnection
	$adminSessionId = $adminApi.CreateAdminsession($AdminUser, $AdminPassword, "rooturl", "en-us");
	[Ericom.MegaConnect.Runtime.XapApi.RemoteHostMembershipComputation]$rhmc = 0;
	#$rGroup = $adminApi.CreateRemoteHostGroup($adminSessionId.AdminSessionId, $groupName, $rhmc);
	#[System.Collections.Generic.List[String]]$remoteHostsList = New-Object System.Collections.Generic.List[String];
	
	#[Ericom.MegaConnect.Runtime.XapApi.RemoteHostSearchConstraints]$rhsc = New-Object Ericom.MegaConnect.Runtime.XapApi.RemoteHostSearchConstraints;
	#$rhsc.HostnamePattern = $pattern; #TODO: Update HERE!
	#$rhl = $adminApi.GetRemoteHostList($adminSessionId.AdminSessionId, $rhsc)
	#foreach ($h in $rhl)
	#{
	#	$remoteHostsList.Add($h.RemoteHostId)
	#}
	#$rGroup.RemoteHostIds = $remoteHostsList;
	#$adminApi.AddRemoteHostGroup($adminSessionId.AdminSessionId, $rGroup) | Out-Null
	
	Export-RemoteHostsGroup
	
}

function GetListOfResourceGroups {
	$adminApi = Start-EricomConnection
	$adminSessionId = $adminApi.CreateAdminsession($AdminUser, $AdminPassword, "rooturl", "en-us");

	# get list
	# for each group	
		# Get-ResourceGroup -ResourceGroupName name
}
function Export-ResourceGroup
{
	
}
function Get-ResourceGroup
{
	param (	
		[Parameter()]
		[string]$ResourceGroupName
	)
	
	$adminApi = Start-EricomConnection
	$adminSessionId = $adminApi.CreateAdminsession($AdminUser, $AdminPassword, "rooturl", "en-us");
	
	$rGroup = $adminApi.GetRemoteHostGroup($adminSessionId.AdminSessionId, $groupName, $rhmc);
	#[System.Collections.Generic.List[String]]$remoteHostsList = New-Object System.Collections.Generic.List[String];
	# Add  ResourceList to global ResouseList
	
	# Add Users to global list
	
	# Get User Group to global list
	
	# Get Systems list
	
	
	#[Ericom.MegaConnect.Runtime.XapApi.RemoteHostSearchConstraints]$rhsc = New-Object Ericom.MegaConnect.Runtime.XapApi.RemoteHostSearchConstraints;
	#$rhsc.HostnamePattern = $pattern; #TODO: Update HERE!
	#$rhl = $adminApi.GetRemoteHostList($adminSessionId.AdminSessionId, $rhsc)
	#foreach ($h in $rhl)
	#{
	#	$remoteHostsList.Add($h.RemoteHostId)
	#}
	#$rGroup.RemoteHostIds = $remoteHostsList;
	#$adminApi.AddRemoteHostGroup($adminSessionId.AdminSessionId, $rGroup) | Out-Null
	Export-ResourceGroup
	
}

Function Export-Resource
{
	
}

function Get-Resource
{
	# Get data
	 Export-Resource
}

function GetListOfResources
{
	# for rech resource in $ResouseList
	Get-Resource
	
}
function Export-User
{
	
}

function Get-User
{
	# get data
	Export-User
}

function GetListOfUsers
{
	# for each user in $UsersList
	Get-User
}

function Export-UserGroup
{
	
}

function Get-UserGroup
{
	# get data
	Export-UserGroup
}
function GetListOfUserGroups
{
	# for each user group in UserGroupsList
	Get-UserGroup
}
function PopulateWithUsers
{
	CreateUser -userName user1 -password P@55w0rd
	CreateUser -userName user2 -password P@55w0rd
	CreateUser -userName user3 -password P@55w0rd
	
	CreateUserGroup -GroupName Group1 -BaseGroup "Domain Users"
	AddUserToUserGroup -GroupName Group1 -User user1
}


function PopulateWithAppsAndDesktops
{
	Create-App -DisplayName chrome -AppName chrome
	Create-Desktop -DisplayName MyDesktop
}

function PublishAppsAndDesktops
{
	PublishAppU -Name App1 -AppName chrome -HostGroupName Allservers -User user1
	PublishAppUG -Name App1 -AppName Firefox -HostGroupName Allservers -UserGroup Group1
	PublishDesktopU -Name DesktopGroup -DesktopName MyDesktop -HostGroupName Allservers -User user1
	PublishDesktopUG -Name DesktopGroup1 -DesktopName MyDesktop -HostGroupName Allservers -UserGroup Group1
}

Function PublishApplication
{
	param (
		[Parameter()]
		[string]$adminUser,
		[Parameter()]
		[string]$adminPassword,
		[Parameter()]
		[String]$applicationName
	)
	
	$adminApi = Start-EricomConnection
	$adminSessionId = $adminApi.CreateAdminsession($adminUser, $adminPassword, "rooturl", "en-us")
	
	$response = $null;
	
	$RemoteHostList = $adminApi.RemoteHostStatusSearch($adminSessionId.AdminSessionId, "Running", "", "100", "100", "0", "", "true", "true", "true")
	
	function FlattenFilesForDirectory ($browsingFolder, $rremoteAgentId, $rremoteHostId)
	{
		foreach ($browsingItem in $browsingFolder.Files.Values)
		{
			if (($browsingItem.Label -eq $applicationName))
			{
				$resourceDefinition = $adminApi.CreateResourceDefinition($adminSessionId.AdminSessionId, $applicationName)
				
				$val1 = $resourceDefinition.ConnectionProperties.GetLocalPropertyValue("remoteapplicationmode")
				$val1.LocalValue = $true
				$val1.ComputeBy = "Literal"
				
				$val2 = $resourceDefinition.ConnectionProperties.GetLocalPropertyValue("alternate_S_shell")
				$val2.LocalValue = "'" + $browsingItem.Path + $browsingItem.Name + "'"
				$val2.ComputeBy = "Literal"
				$val2.LocalValue
				
				$val3 = $resourceDefinition.DisplayProperties.GetLocalPropertyValue("IconLength")
				$val3.LocalValue = $browsingItem.ApplicationString.Length
				$val3.ComputeBy = "Literal"
				
				$val4 = $resourceDefinition.DisplayProperties.GetLocalPropertyValue("IconString")
				$val4.LocalValue = $browsingItem.ApplicationString
				$val4.ComputeBy = "Literal"
				
				$val5 = $resourceDefinition.DisplayProperties.GetLocalPropertyValue("DisplayName")
				$val5.LocalValue = $applicationName
				$val5.ComputeBy = "Literal"
				
				$response = @{ }
				try
				{
					$adminApi.AddResourceDefinition($adminSessionId.AdminSessionId, $resourceDefinition, "true")
					
					$response = @{
						status = "OK"
						success = "true"
						id = $resourceDefinition.ResourceDefinitionId
						message = "The resource has been successfuly published."
					}
				}
				catch [Exception]
				{
					$response = @{
						status = "ERROR"
						message = $_.Exception.Message
					}
				}
				return $response
			}
		}
		
		foreach ($directory in $browsingFolder.SubFolders.Values)
		{
			FlattenFilesForDirectory($directory);
		}
	}
	
	
	foreach ($RH in $RemoteHostList)
	{
		""
		""
		$RH.SystemInfo.ComputerName
		"____________"
		""
		$browsingFolder = $adminApi.SendCustomRequestStandaloneServer($adminSessionId.AdminSessionId,
		$RH.RemoteAgentId,
		[Ericom.MegaConnect.Runtime.XapApi.StandaloneServerRequestType]::HostAgentApplications,
		"null",
		"false",
		"999999999")
		#$browsingFolder
		FlattenFilesForDirectory ($browsingFolder, $RH.RemoteAgentId, $RH.RemoteHostId)
		if ($goon -eq $false)
		{
			return
		}
	}
}


# Main Code 

#Get list of Host Groups
GetListOfHostGroups

GetListOfResourceGroups

GetListOfResources

GetListOfUsers

GetListOfUserGroups


