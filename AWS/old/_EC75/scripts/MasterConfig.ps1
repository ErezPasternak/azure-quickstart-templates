param(
    [string]$DomainDNSName,
    [string]$DomainNetBiosName,
    [string]$AdminPassword,
    [string]$ADServer1PrivateIp,
    [string]$ADServer2PrivateIp,
    [string]$PrivateSubnet1CIDR,
    [string]$PrivateSubnet2CIDR,
    [string]$DMZ1CIDR,
    [string]$DMZ2CIDR,
    [string]$Region,
    [string]$VpcId,
    [string]$softwareBaseLocation,
    [String]$externalFqdn,
    [String]$emailAddress = "nobody",
    [String]$gridName,
	[String]$LUS,
	[String]$tenant,
    [String]$softwareBaseLocation   
    )

#Get the FQDN of the Load Balancer
$PullServer = Get-ELBLoadBalancer -Region $Region | Where-Object {$_.VpcId -eq $VpcId} | select -ExpandProperty DnsName

#Helper functions
Import-Module $psscriptroot\Get-EC2InstanceGuid.psm1
Import-Module $psscriptroot\IPHelper.psm1

#Node Configuration Settings
$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = '*'
            CertificateFile = 'C:\inetpub\wwwroot\dsc.cer'
            Thumbprint = (Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -eq "CN=$PullServer" })[0].Thumbprint
        },
        @{
            NodeName = 'ESG1'
            Guid = (Get-EC2InstanceGuid -InstanceName ESG1)
            AvailabilityZone = 'AZ1'
        },
        @{
            NodeName = 'ESG2'
            Guid = (Get-EC2InstanceGuid -InstanceName ESG2)
            AvailabilityZone = 'AZ2'
        },
        @{
            NodeName = 'Grid1'
            Guid = (Get-EC2InstanceGuid -InstanceName WEGrid1B1)
            AvailabilityZone = 'AZ1'
        },
        @{
            NodeName = 'WEB2'
            Guid = (Get-EC2InstanceGuid -InstanceName WEB2)
            AvailabilityZone = 'AZ2'
        },
        @{
            NodeName = 'DC1'
            Guid = (Get-EC2InstanceGuid -InstanceName DC1)
        },
        @{
            NodeName = 'DC2'
            Guid = (Get-EC2InstanceGuid -InstanceName DC2)
        }
    )
}

#Credentials used for creating & joining the AD Domain
$Pass = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential -ArgumentList "$DomainNetBiosName\administrator", $Pass
$_adminUser = $adminCreds.UserName
$_adminPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR( (ConvertTo-SecureString ($adminCreds.Password | ConvertFrom-SecureString)) ))
   

#Master Configuration for all nodes in deployment
Configuration ServerBase {
    Import-DscResource -ModuleName xNetworking, xActiveDirectory, xComputerManagement

    Node $AllNodes.Where{$_.AvailabilityZone -eq 'AZ1'}.NodeName {
        xDnsServerAddress DnsServerAddress { 
            Address        = $ADServer1PrivateIp, $ADServer2PrivateIp
            InterfaceAlias = 'Ethernet' 
            AddressFamily  = 'IPv4' 
        }                         
    }

    Node $AllNodes.Where{$_.AvailabilityZone -eq 'AZ2'}.NodeName {
        xDnsServerAddress DnsServerAddress { 
            Address        = $ADServer2PrivateIp, $ADServer1PrivateIp
            InterfaceAlias = 'Ethernet' 
            AddressFamily  = 'IPv4' 
        }                         
    }

    Node DC1 {
        cIPAddress DCIPAddress {
            InterfaceAlias = 'Ethernet'
            IPAddress = $ADServer1PrivateIp
            DefaultGateway = (Get-AWSDefaultGateway -IPAddress $ADServer1PrivateIp)
            SubnetMask = (Get-AWSSubnetMask -SubnetCIDR $PrivateSubnet1CIDR)         
        }

        xDnsServerAddress DnsServerAddress { 
            Address        = $ADServer1PrivateIp
            InterfaceAlias = 'Ethernet' 
            AddressFamily  = 'IPv4' 
            DependsOn = '[cIPAddress]DCIPAddress'
        } 

        WindowsFeature ADDSInstall {
            Ensure = 'Present'
            Name = 'AD-Domain-Services'
            DependsOn = '[cIPAddress]DCIPAddress'
        }

        WindowsFeature ADDSToolsInstall {
            Ensure = 'Present'
            Name = 'RSAT-ADDS-Tools'
        }

        xADDomain ActiveDirectory {
            DomainName = $DomainDNSName
            DomainAdministratorCredential = $Credential
            SafemodeAdministratorPassword = $Credential
            DependsOn = '[WindowsFeature]ADDSInstall'
        }

        cADSubnet AZ1Subnet1 {
            Name = $PrivateSubnet1CIDR
            Site = 'Default-First-Site-Name'
            Credential = $Credential
            DependsOn = '[xADDomain]ActiveDirectory'
        }

        cADSubnet AZ1Subnet2 {
            Name = $DMZ1CIDR
            Site = 'Default-First-Site-Name'
            Credential = $Credential
            DependsOn = '[xADDomain]ActiveDirectory'
        }

        cADSite AZ2Site {
            Name = 'AZ2'
            DependsOn = '[WindowsFeature]ADDSInstall'
            Credential = $Credential
        }

        cADSubnet AZ2Subnet1 {
            Name = $PrivateSubnet2CIDR
            Site = 'AZ2'
            Credential = $Credential
            DependsOn = '[cADSite]AZ2Site'
        }

        cADSubnet AZ2Subnet2 {
            Name = $DMZ2CIDR
            Site = 'AZ2'
            Credential = $Credential
            DependsOn = '[cADSite]AZ2Site'
        }

        cADSiteLinkUpdate SiteLinkUpdate {
            Name = 'DEFAULTIPSITELINK'
            SitesIncluded = 'AZ2'
            Credential = $Credential
            DependsOn = '[cADSubnet]AZ2Subnet1'
        }
    }

    Node DC2 {
        cIPAddress DC2IPAddress {
            InterfaceAlias = 'Ethernet'
            IPAddress = $ADServer2PrivateIp
            DefaultGateway = (Get-AWSDefaultGateway -IPAddress $ADServer2PrivateIp)
            SubnetMask = (Get-AWSSubnetMask -SubnetCIDR $PrivateSubnet2CIDR)         
        }

        xDnsServerAddress DnsServerAddress { 
            Address        = $ADServer1PrivateIp
            InterfaceAlias = 'Ethernet' 
            AddressFamily  = 'IPv4' 
            DependsOn = '[cIPAddress]DC2IPAddress'
        }

        WindowsFeature ADDSInstall {
            Ensure = 'Present'
            Name = 'AD-Domain-Services'
            DependsOn = '[cIPAddress]DC2IPAddress'
        }

        WindowsFeature ADDSToolsInstall {
            Ensure = 'Present'
            Name = 'RSAT-ADDS-Tools'
        }

        xADDomainController ActiveDirectory {
            DomainName = $DomainDNSName
            DomainAdministratorCredential = $Credential
            SafemodeAdministratorPassword = $Credential
            DependsOn = '[WindowsFeature]ADDSInstall'
        }
    }

    Node ESG1 {
        
        xComputer JoinDomain {
            Name = 'ESG1'
            DomainName = $DomainDNSName
            Credential = $Credential
            DependsOn = "[xDnsServerAddress]DnsServerAddress"
        }
     
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = "ApplyOnly"
        }

        Script DownloadGridMSI
        {
            TestScript = {
                Test-Path "C:\EricomConnectDataGrid_x64_WT.msi"
            }
            SetScript ={
                $_softwareBaseLocation = "$Using:softwareBaseLocation"
                $source = ($_softwareBaseLocation + "EricomConnectDataGrid_x64_WT.msi")
                $dest = "C:\EricomConnectDataGrid_x64_WT.msi"
                Invoke-WebRequest $source -OutFile $dest
            }
            GetScript = {@{Result = "DownloadGridMSI"}}
      
        }
		
        Package InstallGridMSI
        {
            Ensure = "Present" 
            Path  = "C:\EricomConnectDataGrid_x64_WT.msi"
            Name = "Ericom Connect Data Grid"
            ProductId = "E6923378-7F98-470D-A831-F0C4B214AA1B"
            Arguments = ""
            LogPath = "C:\log-ecdg.txt"
            DependsOn = "[Script]DownloadGridMSI"
        }

	    Script DownloadSecureGatewayMSI
        {
            TestScript = {
                Test-Path "C:\EricomConnectSecureGateway.msi"
            }
            SetScript ={
                $_softwareBaseLocation = "$using:softwareBaseLocation"
                $source = ($_softwareBaseLocation + "EricomConnectSecureGateway.msi")
                $dest = "C:\EricomConnectSecureGateway.msi"
                Invoke-WebRequest $source -OutFile $dest
            }
            GetScript = {@{Result = "DownloadSecureGatewayMSI"}}
        }
		
        Package InstallSecureGatewayMSI
        {
            Ensure = "Present" 
            Path  = "C:\EricomConnectSecureGateway.msi"
            Name = "Ericom Connect Secure Gateway"
            ProductId = "5A0AAAFD-60CF-4145-B4BE-1AC68F7A7D35"
            Arguments = ""
            LogPath = "C:\log-ecsg.txt"
            DependsOn = "[Script]DownloadSecureGatewayMSI"
        }
                
        Package vcRedist 
        { 

            Path = ($softwareBaseLocation+"vcredist_x64.exe" )
            ProductId = "{DA5E371C-6333-3D8A-93A4-6FD5B20BCC6E}" 
            Name = "Microsoft Visual C++ 2010 x64 Redistributable - 10.0.30319" 
            Arguments = "/install /passive /norestart"
 
        } 

        Script DisableFirewallDomainProfile
        {
            TestScript = {
                return ((Get-NetFirewallProfile -Profile Domain).Enabled -eq $false)
            }
            SetScript = {
                Set-NetFirewallProfile -Profile Domain -Enabled False
            }
            GetScript = {@{Result = "DisableFirewallDomainProfile"}}
        }
        
        Script JoinGridESG
        {
            TestScript = {
                $isESGRunning = $false;
                $allServices = Get-Service | Where { $_.DisplayName.StartsWith("Ericom")}
                foreach($service in $seallServicesrvices)
                {
                    if ($service.Name -contains "EricomConnectSecureGateway") {
                        if ($service.Status -eq "Running") {
                            Write-Verbose "ESG service is running"
                            $isESGRunning = $true;
                        } elseif ($service.Status -eq "Stopped") {
                            Write-Verbose "ESG service is stopped"
                            $isESGRunning = $false;
                        } else {
                            $statusESG = $service.Status
                            Write-Verbose "ESG status: $statusESG"
                        }
                    }
                }
                return ($isESGRunning -eq $true);
            }
            SetScript ={
                $domainSuffix = "@" + $Using:DomainDNSName;
                # Call Configuration Tool
                Write-Verbose "Configuration step"
                $workingDirectory = "$env:ProgramFiles\Ericom Software\Ericom Connect Configuration Tool"
                $configFile = "EricomConnectConfigurationTool.exe"
                $connectCli = "ConnectCli.exe"                  

                $_adminUser = "$Using:_adminUser" + "$domainSuffix"
                $_adminPass = "$Using:_adminPassword"
                $_gridName = "$Using:gridName"
                $_gridServicePassword = "$Using:_adminPassword"
                $_lookUpHosts = "$Using:LUS"

                $configPath = Join-Path $workingDirectory -ChildPath $configFile
                $cliPath = Join-Path $workingDirectory -ChildPath $connectCli
                
                $arguments = " ConnectToExistingGrid /AdminUser `"$_adminUser`" /AdminPassword `"$_adminPass`" /disconnect /GridName `"$_gridName`" /GridServicePassword `"$_gridServicePassword`"  /LookUpHosts `"$_lookUpHosts`""              

                $baseFileName = [System.IO.Path]::GetFileName($configPath);
                $folder = Split-Path $configPath;
                cd $folder;
                Write-Verbose "$configPath $arguments"
                $exitCode = (Start-Process -Filepath $configPath -ArgumentList "$arguments" -Wait -Passthru).ExitCode
                if ($exitCode -eq 0) {
                    Write-Verbose "Ericom Connect Secure Gateway has been succesfuly configured."
                } else {
                    Write-Verbose ("Ericom Connect Secure Gateway could not be configured. Exit Code: " + $exitCode)
                }
                
                # publish admin page via ESG
                $argumentsCli = "EsgConfig /adminUser `"$_adminUser`" /adminPassword `"$_adminPass`" common ExternalWebServer`$UrlServicePointsFilter=`"<UrlServicePointsFilter> <UrlFilter> <UrlPathRegExp>^/Admin</UrlPathRegExp> <UrlServicePoints>https://`"$_lookUpHosts`":8022/</UrlServicePoints></UrlFilter> </UrlServicePointsFilter>`"";
                
                $exitCodeCli = (Start-Process -Filepath $cliPath -ArgumentList "$argumentsCli" -Wait -Passthru).ExitCode;
                if ($exitCodeCli -eq 0) {
                    Write-Verbose "ESG: Admin page has been succesfuly published."
                } else {
                    Write-Verbose "$cliPath $argumentsCli"
                    Write-Verbose ("ESG: Admin page could not be published.. Exit Code: " + $exitCode)
                }                 
            }
            GetScript = {@{Result = "JoinGridESG"}}      
        }
        
        Script SendEndEmail
        {
            TestScript = {
                Test-Path "C:\SendEndEmailExecuted\"
            }
            SetScript = {
                New-Item -Path "C:\SendEndEmailExecuted" -ItemType Directory -Force -ErrorAction SilentlyContinue
                $domainSuffix = "@" + $Using:DomainDNSName;
                # send system is ready mail - might need a better place for it
                $To = "nobody"
                $Subject = "Ericom Connect Deployment on Azure is now Ready"
                $Message = ""
                $Keyword = ""
                $From = "daas@ericom.com"
                $date=(Get-Date).TOString();
                $SMTPServer = "ericom-com.mail.protection.outlook.com"
                $Port = 25
                $_externalFqdn = $Using:externalFqdn
                
                if ($Using:emailAddress -ne "") {
                    $To = $Using:emailAddress
                }
                    
                $securePassword = ConvertTo-SecureString -String "1qaz@Wsx#" -AsPlainText -Force
                $credential = New-Object System.Management.Automation.PSCredential ("daas@ericom.com", $securePassword)
                $date = (Get-Date).ToString();	
                $ToName = $To.Split("@")[0].Replace(".", " ");

                Write-Verbose "Ericom Connect Grid Server has been succesfuly configured."
                $Keyword = "CB: Ericom Connect Grid Server has been succesfuly configured."
                $Message = '<h1>Congratulations! Your Ericom DaaS Environment on Microsoft Azure is now Ready!</h1><p>Dear ' + $ToName + ',<br><br>Thank you for deploying <a href="http://www.ericom.com/connect-enterprise.asp">Ericom Connect</a> via Microsoft Azure.<br><br>Your deployment is now complete and you can start using the system.<br><br>To launch Ericom DaaS Client please click <a href="https://' + $_externalFqdn + '"/EricomXml/AccessPortal/Start.html#/login>here. </a><br><br>To log-in to Ericom Connect management console please click <a href="https://' + $_externalFqdn + '/Admin">here. </a><br><br><Below are your credentials. Please make sure you save them for future use:<br><br>Username: demouser' + $domainSuffix + ' <br>Password: P@55w0rd   <br><br><br>Regards,<br><a href="http://www.ericom.com">Ericom</a> Automation Team'
                if ($To -ne "nobody") {
                    try {
                        Send-MailMessage -Body "$Message" -BodyAsHtml -Subject "$Subject" -SmtpServer $SmtpServer -Port $Port -Credential $credential -From $credential.UserName -To $To -bcc "erez.pasternak@ericom.com","DaaS@ericom.com","David.Oprea@ericom.com" -ErrorAction SilentlyContinue
                    } catch {
                        $_.Exception.Message | Out-File "C:\sendmailmessageend.txt"
                    }
                }                               
                #done sending mail
            }
            GetScript = {@{Result = "SendEndEmail"}}
        } 
    }

    Node ESG2 {
        WindowsFeature RDGateway {
            Name = 'RDS-Gateway'
            Ensure = 'Present'
        }

        WindowsFeature RDGatewayTools {
            Name = 'RSAT-RDS-Gateway'
            Ensure = 'Present'
        }

        xComputer JoinDomain {
            Name = 'ESG2'
            DomainName = $DomainDNSName
            Credential = $Credential
            DependsOn = "[xDnsServerAddress]DnsServerAddress"
        }
    }

    Node Grid1 {
        xComputer JoinDomain {
            Name = 'Grid1'
            DomainName = $DomainDNSName
            Credential = $Credential
            DependsOn = "[xDnsServerAddress]DnsServerAddress"
        }

        WindowsFeature IIS {
            Ensure = 'Present'
            Name = 'Web-Server'
        }

        WindowsFeature AspNet45 {
            Ensure = 'Present'
            Name = 'Web-Asp-Net45'
        }

        WindowsFeature IISConsole {
            Ensure = 'Present'
            Name = 'Web-Mgmt-Console'            
        }

        File default {
            DestinationPath = "c:\inetpub\wwwroot\index.html"
            Contents = "<h1>Hello World</h1>"
            DependsOn = "[WindowsFeature]IIS"
        }
    }

    Node WEB2 {
        xComputer JoinDomain {
            Name = 'WEB2'
            DomainName = $DomainDNSName
            Credential = $Credential
            DependsOn = "[xDnsServerAddress]DnsServerAddress"
        }

        WindowsFeature IIS {
            Ensure = 'Present'
            Name = 'Web-Server'
        }

        WindowsFeature AspNet45 {
            Ensure = 'Present'
            Name = 'Web-Asp-Net45'
        }

        WindowsFeature IISConsole {
            Ensure = 'Present'
            Name = 'Web-Mgmt-Console'            
        }

        File default {
            DestinationPath = "c:\inetpub\wwwroot\index.aspx"
            Contents = "<h1>Hello World</h1>"
            DependsOn = "[WindowsFeature]IIS"
        }
    }
}

#Compile and rename the MOF files
$mofFiles = ServerBase -ConfigurationData $ConfigurationData

foreach($mofFile in $mofFiles) {
   $guid = ($ConfigurationData.AllNodes | Where-Object {$_.NodeName -eq $mofFile.BaseName}).Guid
   $dest = "$env:ProgramFiles\WindowsPowerShell\DscService\Configuration\$($guid).mof"
   Move-Item -Path $mofFile.FullName -Destination $dest
   New-DSCCheckSum $dest
}