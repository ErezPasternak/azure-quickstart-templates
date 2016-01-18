configuration CreateADPDC 
{ 
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    ) 
    
    Import-DscResource -ModuleName xActiveDirectory, xDisk, xNetworking, xPendingReboot, cDisk
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        LocalConfigurationManager            
        {            
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyOnly'            
            RebootNodeIfNeeded = $true            
        } 

        WindowsFeature DNS 
        { 
            Ensure = "Present" 
            Name = "DNS"
        }

        xDnsServerAddress DnsServerAddress 
        { 
            Address        = '127.0.0.1' 
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
            DependsOn = "[WindowsFeature]DNS"
        }

        xWaitforDisk Disk2
        {
             DiskNumber = 2
             RetryIntervalSec =$RetryIntervalSec
             RetryCount = $RetryCount
        }

        cDiskNoRestart ADDataDisk
        {
            DiskNumber = 2
            DriveLetter = "F"
        }

        WindowsFeature ADDSInstall 
        { 
            Ensure = "Present" 
            Name = "AD-Domain-Services"
        }  

        xADDomain FirstDS 
        {
            DomainName = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath = "F:\NTDS"
            LogPath = "F:\NTDS"
            SysvolPath = "F:\SYSVOL"
            DependsOn = "[WindowsFeature]ADDSInstall","[xDnsServerAddress]DnsServerAddress","[cDiskNoRestart]ADDataDisk"
        }

        xWaitForADDomain DscForestWait
        {
            DomainName = $DomainName
            DomainUserCredential = $DomainCreds
            RetryCount = $RetryCount
            RetryIntervalSec = $RetryIntervalSec
            DependsOn = "[xADDomain]FirstDS"
        } 

        xPendingReboot Reboot1
        { 
            Name = "RebootServer"
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

	   Script CreateADUsers
        {
            TestScript = { Test-Path "C:\aduserscreated" }
            SetScript = {
                $domainSuffix = "@" + $Using:DomainName;
                $templateUser = "ericom"
                $user = "demouser"
                $pass = "P@55w0rd"
                
                New-ADUser -name "$user" -Instance (Get-ADUser $templateUser) -AccountPassword (ConvertTo-SecureString "$pass" -AsPlainText -Force) -ChangePasswordAtLogon $False -CannotChangePassword $True -Enabled $True -GivenName "$user" -SamAccountName "$user" -Surname ="$user" -UserPrincipalName ("$user" + "$domainSuffix")
                New-Item -Path "C:\aduserscreated" -ItemType Directory -Force 
                
                Add-ADGroupMember -Identity (Get-ADGroup "Remote Desktop Users") -Members "$user"
            }
            GetScript = {@{Result = "CreateADUsers"}}
        }

        Script FixUPNSuffix
        {
            TestScript = {
                Test-Path "C:\adupnsuffix"
            }
            SetScript ={
                # Fix UPN suffix                
                $domainSuffix = "@" + $Using:DomainName;
                Get-ADUser -Filter * | Where { $_.Enabled -eq $true } | foreach { Set-ADUser $_ -UserPrincipalName "$($_.samaccountname)$domainSuffix" }
                New-Item -Path "C:\adupnsuffix" -ItemType Directory 
                
            }
            GetScript = {@{Result = "FixUPNSuffix"}}      
        }
   }
} 