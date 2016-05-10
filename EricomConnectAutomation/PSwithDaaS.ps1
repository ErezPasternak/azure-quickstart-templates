param (
	[switch]$PrepareSystem = $true
)

Write-Output "AutoStart: $AutoStart"
#Requires -RunAsAdministrator

# loads the BitsTransfer Module
Import-Module BitsTransfer
Write-Host "BitsTransfer Module is loaded"

# Settings Section

#download 
$EC_download_url = "https://www.ericom.com/demos/EricomConnectPOC.exe"
$EC_local_path = "C:\Windows\Temp\EricomConnectPOC.exe"
$LocalPathSetup  = "EricomConnectPOC.exe"
$LocalPathVersion = "FULL_Release_EC752_20160502_7.5.2.8832"
$LocalPathBase = "\\ericom.local\data\FinalBuilder\Deliverables\Release\FULL_Release_EC752" 
$LocalPath = $LocalPathBase + "\" + $LocalPathVersion + "\" + $LocalPathSetup

$domainName = "test.local"

#grid
$AdminUser = "admin@test.local"
$AdminPassword = "admin"
$GridName = $env:computername
$HostOrIp = [System.Net.Dns]::GetHostByName((hostname)).HostName
$SaUser = ""
$SaPassword = ""
$DatabaseServer = $env:computername+"\ERICOMCONNECTDB"
$DatabaseName = $env:computername
$ConnectConfigurationToolPath = "\Ericom Software\Ericom Connect Configuration Tool\EricomConnectConfigurationTool.exe"
$UseWinCredentials = "true"
$LookUpHosts = [System.Net.Dns]::GetHostByName((hostname)).HostName

#e-mail
$To = "erez.pasternak@ericom.com"
$From = "daas@ericom.com"
$SMTPServer = "ericom-com.mail.protection.outlook.com"
$SMTPSUser = "daas@ericom.com"
$SMTPassword = "1qaz@Wsx#"
$SMTPPort = 25
$emailTemplate = "WebServer\DaaS\emails\ready.html"
$externalFqdn = [System.Net.Dns]::GetHostByName((hostname)).HostName

# internal 
$global:adminApi = $null
$global:adminSessionId = $null
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


function Download-EricomConnect()
{
	New-Item -Path "C:\Download-EricomConnect" -ItemType Directory -Force -ErrorAction SilentlyContinue
	Write-Output "Download-EricomConnect  -- Start"
	
	#if we have an installer near the ps1 file we will use it and not download
	$myInstaller = Join-Path $pwd "EricomConnectPOC.exe"
	
	if (Test-Path $myInstaller)
	{
		Copy-Item $myInstaller -Destination $EC_local_path
	}
	if (!(Test-Path $EC_local_path))
	{
		Write-Output "Downloading $EC_download_url"
		# (New-Object System.Net.WebClient).DownloadFile($EC_download_url, "C:\Windows\Temp\EricomConnectPOC.exe")
		Start-BitsTransfer -Source $EC_download_url -Destination $EC_local_path
	}
	Write-Output "Download-EricomConnect  -- End"
}

function Copy-EricomConnect()
{
	New-Item -Path "C:\Copy-EricomConnect" -ItemType Directory -Force -ErrorAction SilentlyContinue
	Write-Output "Copy-EricomConnect  -- Start"
	
	#if we have an installer near the ps1 file we will use it and not download
	$myInstaller = Join-Path $pwd "EricomConnectPOC.exe"
	
	if (Test-Path $myInstaller)
	{
		Copy-Item $myInstaller -Destination $EC_local_path
	}
	if (!(Test-Path $EC_local_path))
	{
		Write-Output "Copying $LocalPath"
        Start-BitsTransfer -Source $LocalPath -Destination $EC_local_path
	}
	Write-Output "Copy-EricomConnect  -- End"
}


function Install-SingleMachine([string]$sourceFile)
{
	New-Item -Path "C:\Install-SingleMachine" -ItemType Directory -Force -ErrorAction SilentlyContinue
	Write-Output "Ericom Connect POC installation has been started."
	$exitCode = (Start-Process -Filepath $sourceFile -NoNewWindow -ArgumentList "/silent LAUNCH_CONFIG_TOOL=False" -Wait -Passthru).ExitCode
	if ($exitCode -eq 0)
	{
		Write-Output "Ericom Connect Grid Server has been succesfuly installed."
	}
	else
	{
		Write-Output "Ericom Connect Grid Server could not be installed. Exit Code: "  $exitCode
	}
	Write-Output "Ericom Connect POC installation has been endded."
}


function Config-CreateGrid($config = $Settings)
{
	New-Item -Path "C:\Config-CreateGrid" -ItemType Directory -Force -ErrorAction SilentlyContinue
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
	
	if ($UseWinCredentials -eq $true)
	{
		Write-Output "Configuration mode: with windows credentials"
		$args = " NewGrid /AdminUser $_adminUser /AdminPassword $_adminPass /GridName $_gridName /HostOrIp $_hostOrIp /DatabaseServer $_databaseServer /DatabaseName $_databaseName /UseWinCredForDBAut /disconnect "
	}
	else
	{
		Write-Output "Configuration mode: without windows credentials"
		$args = " NewGrid /AdminUser $_adminUser /AdminPassword $_adminPass /GridName $_gridName /SaDatabaseUser $_saUser /SaDatabasePassword $_saPass /DatabaseServer $_databaseServer /disconnect /noUseWinCredForDBAut"
	}
	

	$baseFileName = [System.IO.Path]::GetFileName($configPath);
	$folder = Split-Path $configPath;
	cd $folder;
	Write-Output "List of ARGS"
	Write-Output "$args"
	Write-Output "base filename"
	Write-Output "$baseFileName"
  
	
    $exitCode = (Start-Process -Filepath "$baseFileName" -ArgumentList "$args" -Wait -Passthru).ExitCode
	if ($exitCode -eq 0)
	{
		Write-Output "Ericom Connect Grid Server has been succesfuly configured."
	}
	else
	{
		Write-Output "Ericom Connect Grid Server could not be configured. Exit Code: "  $exitCode
        exit
	}
  
    $global:adminApi = Start-EricomConnection
    $global:adminSessionId = EricomConnectConnector
	Write-Output "Ericom Connect Grid configuration has been ended."
    
}


function Expand-ZIPFile($file, $destination)
{
	$shell = new-object -com shell.application
	$zip = $shell.NameSpace($file)
	New-Item -ItemType Directory -Path $destination -Force -ErrorAction SilentlyContinue
	
	foreach ($item in $zip.items())
	{
		$shell.Namespace($destination).copyhere($item, 16 + 1024)
	}
}

function ConfigureFirewall
{
	Import-Module NetSecurity
	Set-NetFirewallProfile -Profile Domain -Enabled False
}
#David - can we fix it for single machine install - just to add the Domain users to the local RemoteDesktopUsers ?

function AddUsersToRemoteDesktopGroup
{
	$baseADGroupRDP = "Domain Users"
	Invoke-Command { param ([String]$RDPGroup) net localgroup "Remote Desktop Users" "$RDPGroup" /ADD } -computername "localhost" -ArgumentList "$baseADGroupRDP"
	
}

function CheckDomainRole
{
	# Get-ComputerRole.ps1
	$ComputerName = "localhost"
	
	$role = @{
		0 = "Stand alone workstation";
		1 = "Member workstation";
		2 = "Stand alone server";
		3 = "Member server";
		4 = "Back-up domain controller";
		5 = "Primary domain controller"
	}
	[int32]$myRole = (Get-WmiObject -Class win32_ComputerSystem -ComputerName $ComputerName).DomainRole
	Write-Host "$ComputerName is a $($role[$myRole]), role type $myrole"
	$response = $true;
	if ($myRole -eq 0 -or $myRole -eq 2)
	{
		Write-Warning "The machine should be in a domain!";
		$response = $false;
        Exit 
	}
	return $response;
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
        $current = Get-ADUser -Server $domainName -Credential $AdminCredentials -Filter {sAMAccountName -eq $userName}
        
        If ($current -eq $null)
        {
		    New-ADUser -Server $domainName -PasswordNeverExpires $true -SamAccountName $userName -Name "$userName" -Credential $AdminCredentials -Enabled $true -Verbose -AccountPassword $securePassword
        }
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
# addes an application into Ericom Connect
Function AddApplication
{
	param (

        [string]$DisplayName,
		[Parameter()]
        [string]$applicationName,
		[Parameter()]
		[bool]$DesktopShortcut = $true,
        [Parameter()]
		[bool]$ForceUniqeApps = $true,
        [Parameter()]
		[bool]$StartMenuShortcut = $true
	)
	
    EricomConnectConnector
	$foundApp = CheckIfAppOrDesktopAreInConnect -applicationName $applicationName
    if ($ForceUniqeApps -eq $true -And $foundApp -ne $null)
        {
            return 
        }

	$response = $null;
	
	$RemoteHostList = $adminApi.RemoteHostStatusSearch($adminSessionId, "Running", "", "100", "100", "0", "", "true", "true")
	
	function FlattenFilesForDirectory ($browsingFolder, $rremoteAgentId, $rremoteHostId)
	{
		foreach ($browsingItem in $browsingFolder.Files.Values)
		{
			if (($browsingItem.Label -eq $applicationName))
			{
				$resourceDefinition = $adminApi.CreateResourceDefinition($adminSessionId, $applicationName)
				
				$val1 = $resourceDefinition.ConnectionProperties.GetLocalPropertyValue("remoteapplicationmode")
				$val1.LocalValue = $true
				$val1.ComputeBy = "Literal"
				
				$val2 = $resourceDefinition.ConnectionProperties.GetLocalPropertyValue("alternate_S_shell")
				$val2.LocalValue = '"' + $browsingItem.Path + $browsingItem.Name + '"'
				$val2.ComputeBy = "Literal"
				$val2.LocalValue
				
				$val3 = $resourceDefinition.DisplayProperties.GetLocalPropertyValue("IconLength")
				$val3.LocalValue = $browsingItem.ApplicationString.Length
				$val3.ComputeBy = "Literal"

                $valS = $resourceDefinition.DisplayProperties.GetLocalPropertyValue("ShortcutDesktop")
				$valS.LocalValue = $DesktopShortcut
				$valS.ComputeBy = "Literal"
				
				$val4 = $resourceDefinition.DisplayProperties.GetLocalPropertyValue("IconString")
				$val4.LocalValue = $browsingItem.ApplicationString
				$val4.ComputeBy = "Literal"
				
				$val5 = $resourceDefinition.DisplayProperties.GetLocalPropertyValue("DisplayName")
				$val5.LocalValue = $applicationName
				$val5.ComputeBy = "Literal"
				
                $val6 = $resourceDefinition.DisplayProperties.GetLocalPropertyValue("ShortcutMenuAccessPad")
				$val6.LocalValue = $StartMenuShortcut
			    $val6.ComputeBy = "Literal"

				$response = @{ }
				try
				{
					$adminApi.AddResourceDefinition($adminSessionId, $resourceDefinition, "true")
					
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
		$browsingFolder = $adminApi.SendCustomRequestStandaloneServer($adminSessionId,
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
# addes a desktop to Ericom Connect
function AddDesktop
{
	param (
		[string]$aliasName,
		[Parameter()]
		[bool]$desktopShortcut = $false,
        [Parameter()]
		[bool]$ForceUniqeApps = $true
	)
	
	$applicationName = "Desktop"
	
    EricomConnectConnector
	$response = $null;
	
	$appName = $applicationName
	if ($aliasName.Length -gt 0)
	{
		$appName = $aliasName
	}
    
    $foundApp = CheckIfAppOrDesktopAreInConnect -applicationName $appName
    if ($ForceUniqeApps -eq $true -And $foundApp -ne $null)
    {
       return 
    }

	$resourceDefinition = $adminApi.CreateResourceDefinition($adminSessionId, $applicationName)
	
	$iconfile = "$env:windir\system32\mstsc.exe"
	
	$val1 = $resourceDefinition.ConnectionProperties.GetLocalPropertyValue("remoteapplicationmode")
	$val1.LocalValue = $false
	$val1.ComputeBy = "Literal"
	
	try
	{
		$iconstring = [System.Drawing.Icon]::ExtractAssociatedIcon($iconfile).ToString();
		$icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconfile);
		$iconstream = New-Object System.IO.MemoryStream;
		$icon.ToBitmap().Save($iconstream, [System.Drawing.Imaging.ImageFormat]::Png)
		$iconbytes = $iconstream.ToArray();
		$iconbase64 = [convert]::ToBase64String($iconbytes)
		$iconstream.Flush();
		$iconstream.Dispose();
		
		
		$val3 = $resourceDefinition.DisplayProperties.GetLocalPropertyValue("IconLength")
		$val3.LocalValue = $iconbase64.Length
		$val3.ComputeBy = "Literal"
		
		$val4 = $resourceDefinition.DisplayProperties.GetLocalPropertyValue("IconString")
		$val4.LocalValue = $iconbase64
		$val4.ComputeBy = "Literal"
	}
	catch
	{
		if ($UseWriteHost -eq $true)
		{
			Write-Warning $_.Exception.Message
		}
	}
	
	$valS = $resourceDefinition.DisplayProperties.GetLocalPropertyValue("ShortcutDesktop")
	$valS.LocalValue = $desktopShortcut
	$valS.ComputeBy = "Literal"
	
	$val5 = $resourceDefinition.DisplayProperties.GetLocalPropertyValue("DisplayName")
	$val5.LocalValue = $appName
	$val5.ComputeBy = "Literal"
	
	$response = @{ }
	try
	{
		$adminApi.AddResourceDefinition($adminSessionId, $resourceDefinition, "true") | Out-Null
		
		
	}
	catch [Exception]
	{
		
	}
	return $response
}
function CheckIfAppOrDesktopAreInConnect
{
	param (
		[string]$applicationName
	)
#	$applicationName = $applicationName.Trim();

    EricomConnectConnector
	
	$AppList = $adminApi.ResourceDefinitionSearch($adminSessionId, $null, $null)
	$foundApp = $null
	foreach ($app in $AppList)
	{
		if ($app.DisplayName -eq $applicationName)

		{
			$foundApp = $app.ResourceDefinitionId;
            break;
		}
	}
	return $foundApp

}

#erez TBD
function CreateUserGroup
{
	param (
		[Parameter()]
		[String]$GroupName,
		[Parameter()]
		[String]$BaseGroup
		
	)
	#TBD
	
}
#erez TBD
function AddUserToUserGroup
{
	param (
		[Parameter()]
		[String]$GroupName,
		[Parameter()]
		[String]$User
	)
}

function Create-RemoteHostsGroup
{
	param (
		
		[Parameter()]
		[string]$groupName,
		[Parameter()]
		[string]$pattern
	)
	
    EricomConnectConnector
    $rhmc = [Ericom.MegaConnect.Runtime.XapApi.RemoteHostMembershipComputation]::Explicit
	$rhg = $adminApi.RemoteHostGroupSearch($adminSessionId, $rhmc, 100, $groupName)
	if ($rhg.Count -eq 0)
	{
       [Ericom.MegaConnect.Runtime.XapApi.RemoteHostMembershipComputation]$rhmc = 0;
	   $rGroup = $adminApi.CreateRemoteHostGroup($adminSessionId, $groupName, $rhmc); 
    
	    [System.Collections.Generic.List[String]]$remoteHostsList = New-Object System.Collections.Generic.List[String];
	
	    [Ericom.MegaConnect.Runtime.XapApi.RemoteHostSearchConstraints]$rhsc = New-Object Ericom.MegaConnect.Runtime.XapApi.RemoteHostSearchConstraints;
	    $rhsc.HostnamePattern = $pattern; #TODO: Update HERE!
	    $rhl = $adminApi.GetRemoteHostList($adminSessionId, $rhsc)
	    foreach ($h in $rhl)
	    {
		    $remoteHostsList.Add($h.RemoteHostId)
	    }
	    $rGroup.RemoteHostIds = $remoteHostsList;
	    $adminApi.AddRemoteHostGroup($adminSessionId, $rGroup) | Out-Null
	}
}

function Create-ResourceGroup
{
	param (	
		[String]$groupName
	)
	
    EricomConnectConnector
	
	$resources = $adminApi.ResourceGroupSearch($adminSessionId, $null, $null, $null)
	
	# check if resource group already exists
	$isPresent = $false;
	foreach ($resource in $resources)
	{
		if ($resource.DisplayName -eq $groupName)
		{
			$isPresent = $true;
		}
	}
	
	# create resource group
	if ($isPresent -eq $false)
	{
		$rGroup = $adminApi.CreateResourceGroup($adminSessionId, $groupName)
		$adminApi.AddResourceGroup($adminSessionId, $rGroup) | Out-Null
	}
}
function AddAppToResourceGroup
{
	param (
		[String]$resourceGroup,
        [string]$applicationName
	)
	
    EricomConnectConnector
	
	$resources = $adminApi.ResourceGroupSearch($adminSessionId, $null, $null, $null)
	$rGroup = $null;
	# check if resource group already exists
	$isPresent = $false;
	foreach ($resource in $resources)
	{
		if ($resource.DisplayName -eq $resourceGroup)
		{
			$isPresent = $true;
			$rGroup = $resource;
		}
	}
	
	# resource group found, now check for app
	if ($isPresent)
	{
		$foundApp = CheckIfAppOrDesktopAreInConnect -applicationName $applicationName 
		# try publish it
		
		if ($foundApp -ne $null)
		{
			$rlist = $rGroup.ResourceDefinitionIds
			$rlist.Add($foundApp);
			$rGroup.ResourceDefinitionIds = $rlist
			try
			{
				$output = $adminApi.UpdateResourceGroup($adminSessionId, $rGroup) | Out-Null
			}
			catch
			{
				# Write-EventLogEricom -ErrorMessage ("Could not Update Resource Group adminSessionID `"$adminSessionId`" Group: $rGroup`n " + $app.Trim() + "`n" + $_.Exception.Message)
			}
		}
	}
}
function AddHostGroupToResourceGroup
{
	param (
		[String]$resourceGroup,
		[Parameter()]
		[string]$remoteHostGroup
	)
    EricomConnectConnector
	
	$resources = $adminApi.ResourceGroupSearch($adminSessionId, $null, $null, $null)
	$rGroup = $null;
	# check if resource group already exists
	$isPresent = $false;
	foreach ($resource in $resources)
	{
		if ($resource.DisplayName -eq $groupName)
		{
			$isPresent = $true;
			$rGroup = $resource;
		}
	}
	
	# resource group found, now check for remote host group
	if ($isPresent)
	{
		$rhmc = [Ericom.MegaConnect.Runtime.XapApi.RemoteHostMembershipComputation]::Explicit
		$rhg = $adminApi.RemoteHostGroupSearch($adminSessionId, $rhmc, 100, $remoteHostGroup)
		if ($rhg.Count -gt 0)
		{
			
			[System.Collections.Generic.List[String]]$remoteHostsGroupList = New-Object System.Collections.Generic.List[String];
			foreach ($g in $rhg)
			{
				$remoteHostsGroupList.Add($g.RemoteHostGroupId)
			}
			$rGroup.RemoteHostGroupIds = $remoteHostsGroupList
			$adminApi.UpdateResourceGroup($adminSessionId, $rGroup) | Out-Null
		}
	}
}
function AddUserGroupToResourceGroup
{
	param (
		[String]$resourceGroup,
		[Parameter()]
		[string]$adGroup
	)
	$groupName = $resourceGroup;
	
    EricomConnectConnector	
	$resources = $adminApi.ResourceGroupSearch($adminSessionId, $null, $null, $null)
	# check if resource group already exists
	$rGroup = $null;
	$isPresent = $false;
	foreach ($resource in $resources)
	{
		if ($resource.DisplayName -eq $groupName)
		{
			$isPresent = $true;
			$rGroup = $resource;
		}
	}
	
	if ($isPresent -eq $true)
	{
		[Ericom.MegaConnect.Runtime.XapApi.BindingGroupType]$adGroupBindingType = 2
		$adName = $domainName
		$rGroup.AddBindingGroup("$adGroup", $adGroupBindingType, $adName, $adGroup);
		$adminApi.UpdateResourceGroup($adminSessionId, $rGroup) | Out-Null
	}
}
function AddUserToResourceGroup
{
	param (
		[String]$resourceGroup,
		[Parameter()]
		[string]$adUser
	)
	$groupName = $resourceGroup;
	
    EricomConnectConnector	
	$resources = $adminApi.ResourceGroupSearch($adminSessionId, $null, $null, $null)
	# check if resource group already exists
	$rGroup = $null;
	$isPresent = $false;
	foreach ($resource in $resources)
	{
		if ($resource.DisplayName -eq $groupName)
		{
			$isPresent = $true;
			$rGroup = $resource;
		}
	}
	
	if ($isPresent -eq $true)
	{
		[Ericom.MegaConnect.Runtime.XapApi.BindingGroupType]$adGroupBindingType = 1
		$adName = $domainName
		$adDomainId = $adUser + "@" + $adName;
		$rGroup.AddBindingGroup("$adUser", $adGroupBindingType, $adName, $adDomainId);
		$adminApi.UpdateResourceGroup($adminSessionId, $rGroup) | Out-Null
	}
}
function Publish
{
    param (
		[string]$GroupName,
		[string]$AppName,
		[string]$HostGroupName,
		[string]$User,
        [string]$UserGroup
	)

    Create-ResourceGroup -groupName $GroupName
    AddAppToResourceGroup -resourceGroup $GroupName -applicationName $AppName
    AddHostGroupToResourceGroup -resourceGroup $GroupName -remoteHostGroup $HostGroupName
    if (![string]::IsNullOrWhiteSpace($User))
    {
        AddUserToResourceGroup -resourceGroup $GroupName -adUser $User
    }
    
    if (![string]::IsNullOrWhiteSpace($UserGroup))
    {
        AddUserGroupToResourceGroup -resourceGroup $GroupName -adGroup $UserGroup
    }
}

function Setup-Bginfo ([string]$LocalPath)
{
	New-Item -Path "C:\Setup-Bginfo" -ItemType Directory -Force -ErrorAction SilentlyContinue
	
	$GITBase = "https://raw.githubusercontent.com/ErezPasternak/azure-quickstart-templates/EricomConnect/EricomConnectAutomation/BGinfo/"
	$GITBginfo = $GITBase + "BGInfo.zip"
	$GITBgConfig = $GITBase + "bginfo_config.bgi"
	$LocalBgConfig = Join-Path $LocalPath  "bginfo_config.bgi"
	$GITBgWall = $GITBase + "wall.jpg"
	$localWall = Join-Path $LocalPath "wall.jpg"
	
	Start-BitsTransfer -Source $GITBginfo -Destination "C:\BGInfo.zip"
	Expand-ZIPFile –File "C:\BGInfo.zip" –Destination $LocalPath
	
	Start-BitsTransfer -Source $GITBgConfig -Destination $LocalBgConfig
	Start-BitsTransfer -Source $GITBgWall -Destination $localWall
	
	New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -Name BgInfo -Force -PropertyType String -Value "C:\BgInfo\bginfo.exe C:\BgInfo\bginfo_config.bgi /silent /accepteula /timer:0" | Out-Null
	C:\BgInfo\bginfo.exe C:\BgInfo\bginfo_config.bgi /silent /accepteula /timer:0
}
function Setup-AutomationService ([string]$LocalPath)
{
	New-Item -Path "C:\AutomationService" -ItemType Directory -Force -ErrorAction SilentlyContinue
	
	$HttpBase = "http://tswc.ericom.com:501/erez/751/"
	$DaaSZip = $HttpBase + "DaaSService.zip"
	
	Start-BitsTransfer -Source $DaaSZip -Destination "C:\DaaSService.zip"
	Expand-ZIPFile –File "C:\DaaSService.zip" –Destination "C:\Program Files\Ericom Software\Ericom Automation Service"
	
    $portNumber = 2244; # DaaS WebService port number
    $baseRDPGroup = "DaaS-RDP"           
    $workingDirectory = "C:\Program Files\Ericom Software\Ericom Automation Service\"
    $ServiceName = "AutomationWebService.exe"                  
    $ServicePath = Join-Path $workingDirectory -ChildPath $ServiceName
    $rdshpattern = $HostOrIp
    $fqdn = "PortalSettings/FQDN $externalFqdn";
    $port = "PortalSettings/Port $portNumber";
    $adDomain = "ADSettings/Domain $domainName";
    $adAdmin = "ADSettings/Administrator $AdminUser";
    $adPassword = "ADSettings/Password $AdminPassword";
    $adBaseGroup = "ADSettings/BaseADGroup $baseRDPGroup";
    $rhp = "ADSettings/RemoteHostPattern $rdshpattern";
    $ec_admin = "ConnectSettings/EC_AdminUser $AdminUser"; # EC_Admin User
    $ec_pass = "ConnectSettings/EC_AdminPass $AdminUser"; # EC_Admin Pass
    $RDCB_GridName = "ConnectSettings/EC_GridName $GridName"; # RDCB info - gridname
    $run_boot_strap = "appSettings/LoadBootstrapData False"; # Run bootstrap code
               
    $MAilTemplate = "EmailSettings/EmailTemplatePath $emailTemplate";
    $MAilServer   = "EmailSettings/SMTPServer $SMTPServer";
    $MAilPort = "EmailSettings/SMTPPort $SMTPPort";
    $MAilFrom = "EmailSettings/SMTPFrom $From";
    $MAilUser = "EmailSettings/SMTPUsername $SMTPSUser";
    $MAilPassword = "EmailSettings/SMTPPassword $SMTPassword";
  #  $MAilBCC = "EmailSettings/ListOfBcc $BCCList";
    
    # register the service            
    $argumentsService = "/install";
                
    $exitCodeCli = (Start-Process -Filepath $ServicePath -ArgumentList "$argumentsService" -Wait -Passthru).ExitCode;
    if ($exitCodeCli -eq 0) {
        Write-Verbose "DaaSService: Service has been succesfuly registerd."
    } else {
        Write-Verbose "$ServicePath $argumentsService"
        Write-Verbose ("DaaSService: Service could not be registerd.. Exit Code: " + $exitCode)
    }        
    # configure the service
    $argumentsService = "/changesettings $fqdn $port $adDomain $adAdmin $adPassword $ec_admin $ec_pass $rhp $run_boot_strap $RDCB_GridName $adBaseGroup $MAilTemplate $MAilServer $MAilPort $MAilFrom $MAilUser $MAilPassword";
    Write-Verbose "$ServicePath $argumentsService"           
    $exitCodeCli = (Start-Process -Filepath $ServicePath -ArgumentList "$argumentsService" -Wait -Passthru).ExitCode;
    if ($exitCodeCli -eq 0) {
           Write-Verbose "DaaSService: Service has been succesfuly updated."
    } else {
           
           Write-Verbose ("DaaSService: Service could not be updated.. Exit Code: " + $exitCode)
    }
    # start the service            
    $argumentsService = "/start";
                
    $exitCodeCli = (Start-Process -Filepath $ServicePath -ArgumentList "$argumentsService" -Wait -Passthru).ExitCode;
    if ($exitCodeCli -eq 0) {
        Write-Verbose "DaaSService: Service has been succesfuly started."
    } else {
        Write-Verbose "$ServicePath $argumentsService"
        Write-Verbose ("DaaSService: Service could not be started.. Exit Code: " + $exitCode)
    } 
    #$DaaSUrl = "http://" + $externalFqdn + ":2244/EricomAutomation/DaaS/index.html#/register"
    $DaaSUrl = "http://" + "localhost" + ":2244/EricomAutomation/DaaS/index.html#/register"
    $ws = New-Object -comObject WScript.Shell
    $Dt = $ws.SpecialFolders.item("Desktop")
    $URL = $ws.CreateShortcut($Dt + "\DaaS Portal.url")
    $URL.TargetPath = $DaaSUrl
    $URL.Save()    

}
function SendAdminMail ()
{
	New-Item -Path "C:\SendAdminMail" -ItemType Directory -Force -ErrorAction SilentlyContinue
	
	$Subject = "Ericom Connect Deployment is now Ready"
	
	$securePassword = ConvertTo-SecureString -String $SMTPassword -AsPlainText -Force
	$credential = New-Object System.Management.Automation.PSCredential ("daas@ericom.com", $securePassword)
	$date = (Get-Date).ToString();
	$ToName = $To.Split("@")[0].Replace(".", " ");
	
	Write-Verbose "Ericom Connect Grid Server has been succesfuly configured."
	$Keyword = "CB: Ericom Connect Grid Server has been succesfuly configured."
	$Message = '<h1>Congratulations! Your Ericom Connect Environment is now Ready!</h1><p>Dear ' + $ToName + ',<br><br>Thank you for deploying <a href="http://www.ericom.com/connect-enterprise.asp">Ericom Connect</a>.<br><br>Your deployment is now complete and you can start using the system.<br><br>To launch Ericom Portal Client please click <a href="http://' + $externalFqdn + ':8033/EricomXml/AccessPortal/Start.html#/login">here.</a><br><br>To log-in to Ericom Connect management console please click <a href="https://' + $externalFqdn + ':8033/EricomXml/AccessPortal/Start.html#/login">here.</a><br><br>Below are your Admin credentials. Please make sure you save them for future use:<br><br>Username: ' + $AdminUser + ' <br>Password: ' + $AdminPassword + '<br><br><br>Regards,<br><a href="http://www.ericom.com">Ericom</a> Automation Team'
	if ($To -ne "nobody")
	{
		try
		{
			Send-MailMessage -Body "$Message" -BodyAsHtml -Subject "$Subject" -SmtpServer $SmtpServer -Port $SMTPPort -Credential $credential -From $credential.UserName -To $To -bcc "erez.pasternak@ericom.com", "DaaS@ericom.com" -ErrorAction SilentlyContinue
		}
		catch
		{
			$_.Exception.Message | Out-File "C:\sendmailmessageend.txt"
		}
	}
}

function SendStartMail ()
{
	New-Item -Path "C:\SendStartMail" -ItemType Directory -Force -ErrorAction SilentlyContinue
	
	$Subject = "Ericom Connect Deployment have started"
	
	$securePassword = ConvertTo-SecureString -String $SMTPassword -AsPlainText -Force
	$credential = New-Object System.Management.Automation.PSCredential ("daas@ericom.com", $securePassword)
	$date = (Get-Date).ToString();
	$ToName = $To.Split("@")[0].Replace(".", " ");
	
	Write-Verbose "Ericom Connect Deployment have started."
	$Keyword = "CB: Ericom Connect Deployment have started."
	$Message = '<h1>You have successfully started your Ericom Connect Deployment!</h1><p>Dear ' + $ToName + ',<br><br>Thank you for using <a href="http://www.ericom.com/connect-enterprise.asp">Ericom Connect</a>.<br><br>Your Ericom Connect Deployment is now in process.<br><br>We will send you a confirmation e-mail once the deployment is complete and your system is ready.<br><br>Regards,<br><a href="http://www.ericom.com">Ericom</a> Automation Team'
	
	if ($To -ne "nobody")
	{
		try
		{
			Send-MailMessage -Body "$Message" -BodyAsHtml -Subject "$Subject" -SmtpServer $SmtpServer -Port $SMTPPort -Credential $credential -From $credential.UserName -To $To -bcc "erez.pasternak@ericom.com", "DaaS@ericom.com" -ErrorAction SilentlyContinue
		}
		catch
		{
			$_.Exception.Message | Out-File "C:\sendmailmessageend.txt"
		}
	}
}

function Install-Apps
{
	# list of possilbe apps (4000) can be found here - https://chocolatey.org/packages
	New-Item -Path "C:\Install-Apps" -ItemType Directory -Force -ErrorAction SilentlyContinue
	Write-Output "Apps installation has been started."
	
	iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
	
	Write-Output "Installing fireofx"
	choco install -y firefox
	
	Write-Output "Installing powerpoint.viewer"
	choco install -y powerpoint.viewer
	
	Write-Output "Installing excel.viewer"
	choco install -y excel.viewer
	
	Write-Output "Installing notepadplusplus.install"
	choco install -y notepadplusplus.install
	
	#Write-Output "Installing Libre Office"
	#choco install -y libreoffice
	
	Write-Output "Apps installation has been ended."
}
function Install-WindowsFeatures
{
	# list of Windows Features can be found here - https://blogs.technet.microsoft.com/canitpro/2013/04/23/windows-server-2012-roles-features/
	New-Item -Path "C:\Install-WindowsFeatures" -ItemType Directory -Force -ErrorAction SilentlyContinue
	
	Install-WindowsFeature Net-Framework-Core
	Install-WindowsFeature RDS-RD-Server
	Install-WindowsFeature Web-Server
	Install-WindowsFeature RSAT-AD-PowerShell
	Install-WindowsFeature NET-Framework-45-Features
}

function PopulateWithUsers
{
	CreateUser -userName "user1" -password "P@55w0rd"
	CreateUser -userName "user2" -password "P@55w0rd"
	CreateUser -userName "user3" -password "P@55w0rd"
	
	CreateUserGroup -GroupName "Group1" -BaseGroup "Domain Users"
	AddUserToUserGroup -GroupName "Group1" -User "user1"
}

function PopulateWithRemoteHostGroups
{
	Create-RemoteHostsGroup -groupName "Allservers" -pattern "*"
    Create-RemoteHostsGroup -groupName "MyServer" -pattern "*"
}

function AddAppsAndDesktopsToConnect
{
	AddApplication -DisplayName "Notepad" -applicationName "Notepad" -DesktopShortcut $true
    AddApplication -DisplayName "Firefox" -applicationName "Mozilla Firefox" -DesktopShortcut $true
    AddApplication -DisplayName "Notepad++" -applicationName "Notepad++" -DesktopShortcut $true
    AddApplication -DisplayName "PowerPoint" -applicationName "Microsoft PowerPoint Viewer " -DesktopShortcut $true
    AddApplication -DisplayName "Excel" -applicationName "Microsoft Office Excel Viewer" -DesktopShortcut $true
    AddDesktop -aliasName "MyDesktop" -desktopShortcut $false
    AddDesktop -aliasName "HisDesktop" -desktopShortcut $true
}


function PublishAppsAndDesktops
{
	Publish -GroupName "AppGroup1" -AppName "Notepad" -HostGroupName "Allservers" -User "user1@test.local" -UserGroup "QA"
    Publish -GroupName "AppGroup2" -AppName "Mozilla Firefox" -HostGroupName "Allservers" 
    Publish -GroupName "AppGroup2" -AppName "Notepad" -HostGroupName "Allservers" -User "user1@test.local" 
	Publish -GroupName "DesktopGroup" -AppName "MyDesktop" -HostGroupName "Allserver" -User "user2@test.local"
}
function CreateEricomConnectShortcuts
{
    # open browser for both Admin and Portal
	$AdminUrl = "https://" + $externalFqdn + ":8022/Admin/index.html#/connect"
    $PortalUrl  = "http://" + $externalFqdn + ":8033/EricomXml/AccessPortal/Start.html#/login"
 
    $ws = New-Object -comObject WScript.Shell
    $Dt = $ws.SpecialFolders.item("Desktop")
    $URL = $ws.CreateShortcut($Dt + "\Ericom Connect Admin.url")
    $URL.TargetPath = $AdminUrl
    $URL.Save()

    $URL1 = $ws.CreateShortcut($Dt + "\Ericom Connect AccessPortal.url")
    $URL1.TargetPath = $PortalUrl
    $URL1.Save()

    Start-Process -FilePath $AdminUrl
    Start-Sleep -s 5
    Start-Process -FilePath $PortalUrl
}

function PostInstall
{
    # Create users and groups in AD
    PopulateWithUsers
	
    # Install varius applications on the machine
	Install-Apps
    
    # Create the needed Remote Host groups in Ericom Connect
    PopulateWithRemoteHostGroups
		
	# Adds apps and desktops To Ericon Connect
	AddAppsAndDesktopsToConnect
	
	# Now we actuly publish apps and desktops to users
	PublishAppsAndDesktops
	
	# Setup background bitmap and user date using BGinfo
	Setup-Bginfo -LocalPath C:\BgInfo
	
    # Create Desktop shortcuts for Admin and Portal
    CreateEricomConnectShortcuts

    #Send Admin mail
	SendAdminMail
}













# Main Code 

# Prerequisite check that this machine is part of a domain
# CheckDomainRole

#send inital mail 
#SendStartMail

# Install the needed Windows Features 
# Install-WindowsFeatures

# Download Ericom Offical Installer from the Ericom Web site  
# Download-EricomConnect
 
# Copy Ericom Connect install from local network share
# Copy-EricomConnect

# Install EC in a single machine mode including SQL express   
# Install-SingleMachine -sourceFile C:\Windows\Temp\EricomConnectPOC.exe

#we can stop here with a system ready and connected installed and not cofigured 
if ($PrepareSystem -eq $true)
{
	# Configure Ericom Connect Grid
	#Config-CreateGrid -config $Settings
	
	# Run PostInstall Creating users,apps,desktops and publish them
	# PostInstall
}
Setup-AutomationService