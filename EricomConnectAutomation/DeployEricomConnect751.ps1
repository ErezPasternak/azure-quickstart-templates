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
$DatabaseName = "ERICOMCONNECTDB"
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
$externalFqdn = $env:COMPUTERNAME


# Download EricomConnect
<#
	.SYNOPSIS
		A brief description of the Download-EricomConnect function.
	
	.DESCRIPTION
		A detailed description of the Download-EricomConnect function.
	
	.EXAMPLE
		PS C:\> Download-EricomConnect
	
	.NOTES
		Additional information about the function.
#>
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



<#
	.SYNOPSIS
		A brief description of the Install-SingleMachine function.
	
	.DESCRIPTION
		A detailed description of the Install-SingleMachine function.
	
	.PARAMETER sourceFile
		A description of the sourceFile parameter.
	
	.EXAMPLE
		PS C:\> Install-SingleMachine -sourceFile 'Value1'
	
	.NOTES
		Additional information about the function.
#>
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

<#
	.SYNOPSIS
		A brief description of the Config-CreateGrid function.
	
	.DESCRIPTION
		A detailed description of the Config-CreateGrid function.
	
	.PARAMETER config
		A description of the config parameter.
	
	.EXAMPLE
		PS C:\> Config-CreateGrid -config $value1
	
	.NOTES
		Additional information about the function.
#>
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
		$args = " NewGrid /AdminUser $_adminUser /AdminPassword $_adminPass /GridName $_gridName /HostOrIp $_hostOrIp /DatabaseServer $_databaseServer /DatabaseName $_databaseName /UseWinCredForDBAut"
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
	}
	Write-Output "Ericom Connect Grid configuration has been ended."
}

<#
	.SYNOPSIS
		A brief description of the Install-Apps function.
	
	.DESCRIPTION
		A detailed description of the Install-Apps function.
	
	.EXAMPLE
		PS C:\> Install-Apps
	
	.NOTES
		Additional information about the function.
#>
function Install-Apps
{
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
	
	Write-Output "Apps installation has been ended."
}

<#
	.SYNOPSIS
		A brief description of the Setup-Bginfo function.
	
	.DESCRIPTION
		A detailed description of the Setup-Bginfo function.
	
	.PARAMETER LocalPath
		A description of the LocalPath parameter.
	
	.EXAMPLE
		PS C:\> Setup-Bginfo -LocalPath 'Value1'
	
	.NOTES
		Additional information about the function.
#>
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
	$Message = '<h1>Congratulations! Your Ericom Connect Environment is now Ready!</h1><p>Dear ' + $ToName + ',<br><br>Thank you for deploying <a href="http://www.ericom.com/connect-enterprise.asp">Ericom Connect</a>.<br><br>Your deployment is now complete and you can start using the system.<br><br>To launch Ericom Portal Client please click <a href="https://' + $externalFqdn + '/EricomAutomation/DaaS/index.html#/register">here.</a><br><br>To log-in to Ericom Connect management console please click <a href="https://' + $externalFqdn + '/Admin">here.</a><br><br>Below are your Admin credentials. Please make sure you save them for future use:<br><br>Username: ' + $AdminUser + ' <br>Password: ' + $AdminPassword + '<br><br><br>Regards,<br><a href="http://www.ericom.com">Ericom</a> Automation Team'
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
<#
	.SYNOPSIS
		A brief description of the Expand-ZIPFile function.
	
	.DESCRIPTION
		A detailed description of the Expand-ZIPFile function.
	
	.PARAMETER file
		A description of the file parameter.
	
	.PARAMETER destination
		A description of the destination parameter.
	
	.EXAMPLE
		PS C:\> Expand-ZIPFile -file $value1 -destination $value2
	
	.NOTES
		Additional information about the function.
#>
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

<#
	.SYNOPSIS
		A brief description of the Install-WindowsFeatures function.
	
	.DESCRIPTION
		A detailed description of the Install-WindowsFeatures function.
	
	.EXAMPLE
		PS C:\> Install-WindowsFeatures
	
	.NOTES
		Additional information about the function.
#>
function Install-WindowsFeatures
{
	New-Item -Path "C:\Install-WindowsFeatures" -ItemType Directory -Force -ErrorAction SilentlyContinue
	
	Install-WindowsFeature Net-Framework-Core
	Install-WindowsFeature RDS-RD-Server
	Install-WindowsFeature Web-Server
	Install-WindowsFeature RSAT-AD-PowerShell
	Install-WindowsFeature NET-Framework-45-Features
}

<#
	.SYNOPSIS
		A brief description of the ConfigureFirewall function.
	
	.DESCRIPTION
		A detailed description of the ConfigureFirewall function.
	
	.EXAMPLE
		PS C:\> ConfigureFirewall
	
	.NOTES
		Additional information about the function.
#>
function ConfigureFirewall
{
	Import-Module NetSecurity
	Set-NetFirewallProfile -Profile Domain -Enabled False
}
#David - can we fix it for single machine install - just to add the Domain users to the local RemoteDesktopUsers ?
<#
	.SYNOPSIS
		A brief description of the AddUsersToRemoteDesktopGroup function.
	
	.DESCRIPTION
		A detailed description of the AddUsersToRemoteDesktopGroup function.
	
	.EXAMPLE
		PS C:\> AddUsersToRemoteDesktopGroup
	
	.NOTES
		Additional information about the function.
#>
function AddUsersToRemoteDesktopGroup
{
	$baseADGroupRDP = "Domain Users"
	Invoke-Command { param ([String]$RDPGroup) net localgroup "Remote Desktop Users" "$RDPGroup" /ADD } -computername "localhost" -ArgumentList "$baseADGroupRDP"
	
}
<#
	.SYNOPSIS
		A brief description of the CheckDomainRole function.
	
	.DESCRIPTION
		A detailed description of the CheckDomainRole function.
	
	.EXAMPLE
		PS C:\> CheckDomainRole
	
	.NOTES
		Additional information about the function.
#>
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
	}
	return $response;
}
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
function PublishAppU
{
	param (
		[Parameter()]
		[String]$DisplayName,
		[Parameter()]
		[String]$AppName,
		[Parameter()]
		[String]$HostGroupName,
		[Parameter()]
		[String]$User
	)
	#TBD
	
}
function PublishAppUG
{
	param (
		[Parameter()]
		[String]$DisplayName,
		[Parameter()]
		[String]$AppName,
		[Parameter()]
		[String]$HostGroupName,
		[Parameter()]
		[String]$UserGroup
	)
	#TBD
	
}
function PublishDesktopU
{
	param (
		[Parameter()]
		[String]$DisplayName,
		[Parameter()]
		[String]$HostGroupName,
		[Parameter()]
		[String]$User
	)
	#TBD
	
}
<#
	.SYNOPSIS
		A brief description of the PublishDesktopUG function.
	
	.DESCRIPTION
		A detailed description of the PublishDesktopUG function.
	
	.PARAMETER DisplayName
		A description of the DisplayName parameter.
	
	.PARAMETER HostGroupName
		A description of the HostGroupName parameter.
	
	.PARAMETER UserGroup
		A description of the UserGroup parameter.
	
	.EXAMPLE
		PS C:\> PublishDesktopUG -DisplayName 'Value1' -HostGroupName 'Value2'
	
	.NOTES
		Additional information about the function.
#>
function PublishDesktopUG
{
	param (
		[Parameter()]
		[String]$DisplayName,
		[Parameter()]
		[String]$HostGroupName,
		[Parameter()]
		[String]$UserGroup
	)
	#TBD
	
}
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

function PopulateWithUsers
{
	CreateUser -userName user1 -password P@55w0rd
	CreateUser -userName user2 -password P@55w0rd
	CreateUser -userName user3 -password P@55w0rd
	
	CreateUserGroup -GroupName Group1 -BaseGroup "Domain Users"
	AddUserToUserGroup -GroupName Group1 -User user1
}

function PopulateWithRemoteHostGroups
{
	Create-RemoteHostsGroup -groupName Allservers -pattern "*"
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

function PostInstall
{
	# Create users and groups in AD
	PopulateWithUsers
	PopulateWithRemoteHostGroups
	
	# Install varius applications on the machine
	Install-Apps
	
	# publish apps and desktops and Ericon Connect
	PopulateWithAppsAndDesktops
	
	# Now we actuly publish 
	PublishAppsAndDesktops
	
	# Setup background bitmap and user date using BGinfo
	Setup-Bginfo -LocalPath C:\BgInfo
	
	#Send Admin mail
	SendAdminMail
	
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

function PublishAppU
{
	param (
		[string]$DisplayName,
		[string]$AppName,
		[string]$HostGroupName,
		[string]$User
	)
	PublishApplication -adminUser $adminUser -adminPassword $adminPassword -applicationName $AppName
}
function PublishAppUG
{
	param (
		[string]$DisplayName,
		[string]$AppName,
		[string]$HostGroupName,
		[string]$UserGroup
	)
	PublishApplication -adminUser $adminUser -adminPassword $adminPassword -applicationName $AppName
}
function PublishDesktopU
{
	param (
		[string]$DisplayName,
		[string]$HostGroupName,
		[string]$User
	)
	PublishApplication -adminUser $adminUser -adminPassword $adminPassword -applicationName $AppName
}
function PublishDesktopUG
{
	param (
		[string]$DisplayName,
		[string]$HostGroupName,
		[string]$UserGroup
	)
	PublishApplication -adminUser $adminUser -adminPassword $adminPassword -applicationName $AppName
}

# Main Code 

# Prerequisite check that this machine is part of a domain
CheckDomainRole

#send inital mail 
SendStartMail

# Install the needed Windows Features 
Install-WindowsFeatures

# Download Ericom Offical Installer from the Ericom Web site  
 Download-EricomConnect

# Copy Ericom Connect install from local network share
# Copy-EricomConnect

# Install EC in a single machine mode including SQL express   
Install-SingleMachine -sourceFile C:\Windows\Temp\EricomConnectPOC.exe

#we can stop here with a system ready and connected installed and not cofigured 
if ($PrepareSystem -eq $true)
{
	# Configure Ericom Connect Grid
	Config-CreateGrid -config $Settings
	
	# Run PostInstall Creating users,apps,desktops and publish them
	PostInstall
}
#Write-Output $PSScriptRoot 


