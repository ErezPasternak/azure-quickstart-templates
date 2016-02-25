configuration DomainJoin 
{ 
   param 
    ( 
        [Parameter(Mandatory)]
        [String]$domainName,

        [Parameter(Mandatory)]
        [PSCredential]$adminCreds
    )
    
    Import-DscResource -ModuleName xActiveDirectory, xComputerManagement

    $domainCreds = New-Object System.Management.Automation.PSCredential ("$domainName\$($adminCreds.UserName)", $adminCreds.Password)
   
    $_Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR( (ConvertTo-SecureString ($adminCreds.Password | ConvertFrom-SecureString)) ))
    
    Write-Verbose ($adminCreds.UserName + " " + $_Password)
  
    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        WindowsFeature ADPowershell
        {
            Name = "RSAT-AD-PowerShell"
            Ensure = "Present"
        } 

        xComputer DomainJoin
        {
            Name = $env:COMPUTERNAME
            DomainName = $domainName
            Credential = $domainCreds
            DependsOn = "[WindowsFeature]ADPowershell" 
        }
   }
}

configuration EnableRemoteAdministration
{
	param
	(
		[Parameter(Mandatory)]
		[String]$broker
	)

	Node localhost 
	{
		LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }
		
		Script SetRDA
		{
			TestScript = {
                Test-Path "C:\RDAEnabled\"
            }
            SetScript ={
				New-Item -Path "C:\RDAEnabled" -ItemType Directory -Force -ErrorAction SilentlyContinue
                Enable-PSRemoting -Force
				$broker = "$Using:broker"
				Set-Item wsman:\localhost\Client\TrustedHosts -value $broker
            }
            GetScript = {@{Result = "SetRDA"}}
		}
	}
}

configuration EnableRemoteDesktopForDomainUsers
{
	Node localhost 
	{
		LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }
		
		Script SetRDS
		{
			TestScript = {
                Test-Path "C:\RDSEnabled\"
            }
            SetScript ={
				New-Item -Path "C:\RDSEnabled" -ItemType Directory -Force -ErrorAction SilentlyContinue
				$baseADGroupRDP = "Domain Users"
                Invoke-Command { param([String]$RDPGroup) net localgroup "Remote Desktop Users" "$RDPGroup" /ADD } -computername "localhost" -ArgumentList "$baseADGroupRDP"
            }
            GetScript = {@{Result = "SetRDS"}}
		}
	}
}

configuration EnableRunningScripts
{
	Node localhost 
	{
		LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }
		
		Script SetExecutionPolicy
		{
			TestScript = {
                Test-Path "C:\ExecutionPolicy\"
            }
            SetScript ={
				New-Item -Path "C:\ExecutionPolicy" -ItemType Directory -Force -ErrorAction SilentlyContinue
				try {
					Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$false -ErrorAction SilentlyContinue
				} catch { }
            }
            GetScript = {@{Result = "SetExecutionPolicy"}}
		}
	}
}

configuration RunBootstrap
{
	param
	(
		[Parameter(Mandatory)]
		[String]$adminUsername,
		
		[Parameter(Mandatory)]
		[String]$adminPassword,
		
		[Parameter(Mandatory)]
		[String]$baseADGroupRDP  = "DaaS-RDP",
		
		[Parameter(Mandatory)]
		[String]$remoteHostPattern,
		
		[Parameter(Mandatory)]
		[String]$bootstrapURL
	)
	
	Node localhost 
	{
		LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }
		
		Script RunBootstrapScript
		{
			TestScript = {
                Test-Path "C:\RunBootstrapScript\"
            }
            SetScript ={
				New-Item -Path "C:\RunBootstrapScript" -ItemType Directory -Force -ErrorAction SilentlyContinue
				$bootstrapURL = "$Using:bootstrapURL"
				$bootstrapDestination = "C:\RunBootstrapScript\Bootstrap.ps1"
				# 1. Download bootstrap file
				Invoke-WebRequest $bootstrapURL -OutFile $bootstrapDestination
				Unblock-File $bootstrapDestination
				# 2. Run the bootstrap file
				$adminUser = "$Using:adminUsername"
				$adminPass = "$Using:adminPassword"
				$ADGroup = "$Using:baseADGroupRDP"
				$rdshpattern = "$Using:remoteHostPattern"
				Invoke-Expression "C:\RunBootstrapScript\.\Bootstrap.ps1 -adminUsername `"$adminUser`" -adminPassword `"$adminPass`" -baseADGroupRDP `"$ADGroup`" -remoteHostPattern `"$rdshpattern`""
				
            }
            GetScript = {@{Result = "RunBootstrapScript"}}
		}
	}
	
}



configuration DesktopHost
{
   param 
    ( 
        [Parameter(Mandatory)]
        [String]$domainName,

        [Parameter(Mandatory)]
        [PSCredential]$adminCreds,
		
	    [Parameter(Mandatory)]
        [String]$gridName,
		
	    [Parameter(Mandatory)]
        [String]$LUS,
		
	    [Parameter(Mandatory)]
        [String]$tenant,
        
        [Parameter(Mandatory)]
        [String]$softwareBaseLocation
        
    ) 

    $_adminUser = $adminCreds.UserName
    $domainCreds = New-Object System.Management.Automation.PSCredential ("$domainName\$_adminUser", $adminCreds.Password)
    $_adminPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR( (ConvertTo-SecureString ($adminCreds.Password | ConvertFrom-SecureString)) ))

    $accessPadShortCut = "-accesspad /server=" + $LUS + ":8011"

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = "ApplyOnly"
        }

		EnableRemoteAdministration EnableRemoteAdministration
		{
			broker = $LUS
		}
		
		EnableRemoteDesktopForDomainUsers EnableRemoteDesktopForDomainUsers
		{
		}
        
		Script DownloadAccessPadMSI
        {
            TestScript = {
                Test-Path "C:\EricomAccessPadClient64.msi"
            }
            SetScript ={
                $_softwareBaseLocation = "$Using:softwareBaseLocation"
                $source = ($_softwareBaseLocation + "EricomAccessPadClient64.msi") 
                $dest = "C:\EricomAccessPadClient64.msi"
                Invoke-WebRequest $source -OutFile $dest
            }
            GetScript = {@{Result = "DownloadAccessPadMSI"}}
      
        }
		
        Package InstallAccessAccessPadMSI
        {
            Ensure = "Present" 
            Path  = "C:\EricomAccessPadClient64.msi"
            Name = "Ericom AccessPad Client"
            ProductId = "E5B16AFC-4452-4990-B94A-4380E1A84A5E"
            Arguments = "ESSO=1 SHORTCUT_PARAMS=`"$accessPadShortCut`""
            LogPath = "C:\log-eap.txt"
            DependsOn = "[Script]DownloadAccessPadMSI"
        }
        
        Script AddAccessPadOnStartUp
        {
            Credential = $adminCreds
            TestScript = {
                $job = Get-ScheduledJob -Name AccessPad -ErrorAction SilentlyContinue
                return ($job -ne "" -and $job.Enabled -eq $true)
            }
            SetScript ={
                $_lookUpHosts = "$Using:LUS";
                $trigger = New-JobTrigger -AtLogOn -User * -RandomDelay 00:00:02 -ErrorAction SilentlyContinue
                $filePath = "C:\Program Files\Ericom Software\Ericom AccessPad Client\Blaze.exe"
                $argForAP = "-accesspad /server=$_lookUpHosts:8011"
                Register-ScheduledJob -Trigger $trigger -Name "AccessPad" -ErrorAction SilentlyContinue -ScriptBlock  {
                    Write-Verbose "$args[0] $args[1]"
                    $exitCode = (Start-Process -Filepath $args[0] -ArgumentList $args[1] -Wait -Passthru).ExitCode
                } -ArgumentList $filePath, $argForAP
            }
            GetScript = {@{Result = "AddAccessPadOnStartUp"}}      
        }
    }
}