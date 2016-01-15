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



configuration Gateway
{
   param 
    ( 
        [Parameter(Mandatory)]
        [String]$domainName,

        [Parameter(Mandatory)]
        [PSCredential]$adminCreds
    ) 


    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = "ApplyOnly"
        }

        DomainJoin DomainJoin
        {
            domainName = $domainName 
            adminCreds = $adminCreds 
        }

        WindowsFeature RDS-Gateway
        {
            Ensure = "Present"
            Name = "RDS-Gateway"
        }

        WindowsFeature RDS-Web-Access
        {
            Ensure = "Present"
            Name = "RDS-Web-Access"
        }
    }
}



configuration SessionHost
{
   param 
    ( 
        [Parameter(Mandatory)]
        [String]$domainName,

        [Parameter(Mandatory)]
        [PSCredential]$adminCreds
    ) 


    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = "ApplyOnly"
        }

        DomainJoin DomainJoin
        {
            domainName = $domainName 
            adminCreds = $adminCreds 
        }

        WindowsFeature RDS-RD-Server
        {
            Ensure = "Present"
            Name = "RDS-RD-Server"
        }
	
	Script DownloadECAndDeploy
        {
            TestScript = {
                Test-Path "C:\EricomConnectPOC.exe"
            }
            SetScript ={
                $source = "https://www.ericom.com/demos/EricomConnectPOC.exe"
                $dest = "C:\EricomConnectPOC.exe"
                Invoke-WebRequest $source -OutFile $dest
				# install
				# Write-Verbose "starting installer" 
                # $cmd = "C:\EricomConnectPOC.exe /silent /LAUNCH_CONFIG_TOOL=False"
                # Write-Verbose "Command to run: $cmd"
                # Invoke-Expression cmd | Write-Verbose
            }
            GetScript = {@{Result = "DownloadECAndDeploy"}}
      
        }
    }

}




configuration RDSDeployment
{
   param 
    ( 
        [Parameter(Mandatory)]
        [String]$domainName,

        [Parameter(Mandatory)]
        [PSCredential]$adminCreds,

        # Connection Broker Node name
        [String]$connectionBroker,
        
        # Web Access Node name
        [String]$webAccessServer,

        # Gateway external FQDN
        [String]$externalFqdn,
        
        # RD Session Host count and naming prefix
        [Int]$numberOfRdshInstances = 1,
        [String]$sessionHostNamingPrefix = "SessionHost-",

        # Collection Name
        [String]$collectionName,

        # Connection Description
        [String]$collectionDescription

    ) 

    Import-DscResource -ModuleName PSDesiredStateConfiguration, xActiveDirectory, xComputerManagement, xRemoteDesktopSessionHost

   
    $localhost = [System.Net.Dns]::GetHostByName((hostname)).HostName

    $username = $adminCreds.UserName -split '\\' | select -last 1
    $domainCreds = New-Object System.Management.Automation.PSCredential ("$domainName\$username", $adminCreds.Password)


    if (-not $connectionBroker)   { $connectionBroker = $localhost }
    if (-not $webAccessServer)    { $webAccessServer  = $localhost }

    if ($sessionHostNamingPrefix)
    { 
        $sessionHosts = @( 0..($numberOfRdshInstances-1) | % { "$sessionHostNamingPrefix$_.$domainname"} )
    }
    else
    {
        $sessionHosts = @( $localhost )
    }

    if (-not $collectionName)         { $collectionName = "Desktop Collection" }
    if (-not $collectionDescription)  { $collectionDescription = "A sample RD Session collection up in cloud." }


    Node localhost
    {

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = "ApplyOnly"
        }

        DomainJoin DomainJoin
        {
            domainName = $domainName 
            adminCreds = $adminCreds 
        }

        WindowsFeature ADDSTools
        {
            Name = "RSAT-ADDS-Tools"
        } 

        WindowsFeature RSAT-RDS-Tools
        {
            Ensure = "Present"
            Name = "RSAT-RDS-Tools"
            IncludeAllSubFeature = $true
        }

        WindowsFeature RDS-Licensing
        {
            Ensure = "Present"
            Name = "RDS-Licensing"
        }

        xRDSessionDeployment Deployment
        {
            DependsOn = "[DomainJoin]DomainJoin"

            ConnectionBroker = $connectionBroker
            WebAccessServer  = $webAccessServer

            SessionHosts     = $sessionHosts

            PsDscRunAsCredential = $domainCreds
        }


        xRDServer AddLicenseServer
        {
            DependsOn = "[xRDSessionDeployment]Deployment"
            
            Role    = 'RDS-Licensing'
            Server  = $connectionBroker

            PsDscRunAsCredential = $domainCreds
        }

        xRDLicenseConfiguration LicenseConfiguration
        {
            DependsOn = "[xRDServer]AddLicenseServer"

            ConnectionBroker = $connectionBroker
            LicenseServers   = @( $connectionBroker )

            LicenseMode = 'PerUser'

            PsDscRunAsCredential = $domainCreds
        }


        xRDServer AddGatewayServer
        {
            DependsOn = "[xRDLicenseConfiguration]LicenseConfiguration"
            
            Role    = 'RDS-Gateway'
            Server  = $webAccessServer

            GatewayExternalFqdn = $externalFqdn

            PsDscRunAsCredential = $domainCreds
        }

        xRDGatewayConfiguration GatewayConfiguration
        {
            DependsOn = "[xRDServer]AddGatewayServer"

            ConnectionBroker = $connectionBroker
            GatewayServer    = $webAccessServer

            ExternalFqdn = $externalFqdn

            GatewayMode = 'Custom'
            LogonMethod = 'AllowUserToSelectDuringConnection'

            UseCachedCredentials = $true
            BypassLocal = $false

            PsDscRunAsCredential = $domainCreds
        } 
        

        xRDSessionCollection Collection
        {
            DependsOn = "[xRDGatewayConfiguration]GatewayConfiguration"

            ConnectionBroker = $connectionBroker

            CollectionName = $collectionName
            CollectionDescription = $collectionDescription
            
            SessionHosts = $sessionHosts

            PsDscRunAsCredential = $domainCreds
        }
 	
	Script DownloadECAndDeploy
        {
            TestScript = {
                Test-Path "C:\EricomConnectPOC.exe"
            }
            SetScript ={
                $source = "https://www.ericom.com/demos/EricomConnectPOC.exe"
                $dest = "C:\EricomConnectPOC.exe"
                Invoke-WebRequest $source -OutFile $dest
				# install
				# Write-Verbose "starting installer" 
                # $cmd = "C:\EricomConnectPOC.exe /silent /LAUNCH_CONFIG_TOOL=False"
                # Write-Verbose "Command to run: $cmd"
                # Invoke-Expression cmd | Write-Verbose
            }
            GetScript = {@{Result = "DownloadECAndDeploy"}}
      
        }

    }
}