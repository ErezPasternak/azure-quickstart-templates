<#
.Synopsis
Monitor Ericom Connect enviroment 

.NOTES   
Name: MonitorEC
Author: Erez Pasternak
Version: 1.0
DateCreated: 2016-06-23
DateUpdated: 
#>
param (
	[switch]$PrepareSystem = $true
)

# Connect Variables
$ESGaddress = "https://localhost/ping"
$EUWSaddress = "http://localhost:8033/ericomxml/ping"
$Connectserver = "localhost"
$NetworkAdmin = "admin@test.local"
$NetworkPassword = "admin"

# E-mail Settings
$To = "erez.pasternak@ericom.com"
$externalFqdn = [System.Net.Dns]::GetHostByName((hostname)).HostName

$ConnectCLIPath = "\Ericom Software\Ericom Connect Configuration Tool\ConnectCLI.exe"

$emailTemplate = "WebServer\DaaS\emails\ready.html"
$From = "daas@ericom.com"
$SMTPServer = "ericom-com.mail.protection.outlook.com"
$SMTPSUser = "daas@ericom.com"
$SMTPassword = "aIOEQTK4hTMH0GvIpD4Eh"

$SMTPPort = 25
# Internal Code - DO NOT CHANGE  
$global:adminApi = $null
$global:adminSessionId = $null
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


if (!([System.Diagnostics.EventLog]::SourceExists("Ericom Connect Monitoring")))
{
	New-EventLog -LogName Application -Source "Ericom Connect Monitoring" 
}

function Write-EventLogEricom
{
	[CmdletBinding()]
	[OutputType([int])]
	Param (
		[Parameter(Mandatory = $true)]
		[string]$Message,
        [Parameter()]
        [string]$EventID
	)
	$LogName = "Application"
	$SourceName = "Ericom Connect Monitoring"
	Write-EventLog -LogName $LogName -source $SourceName -EventId $EventID -message "$Message" -EntryType Information
}

function Write-EventLogEricomError
{
	[CmdletBinding()]
	[OutputType([int])]
	Param (
		[Parameter(Mandatory = $true)]
		[string]$Message,
        [Parameter()]
        [string]$EventID
	)
	$LogName = "Application"
	$SourceName = "Ericom Connect Monitoring"
	
	Write-EventLog -LogName $LogName -source $SourceName -EventId $EventID -message "$Message" -EntryType Error
}
function Start-EricomConnection
{
	$Assem = Import-EricomLib
	
	$regularUser = New-Object Ericom.CloudConnect.Utilities.SpaceCredentials("regularUser")
	$_adminApi = [Ericom.MegaConnect.Runtime.XapApi.AdministrationProcessingUnitClassFactory]::GetInstance($regularUser)
	
	return $_adminApi
}

function EricomConnectConnector()
{
    if ($global:adminSessionId -eq $null)
    {
        return ($adminApi.CreateAdminsession($AdminUser, $AdminPassword, "rooturl", "en-us")).AdminSessionId
    } else {
        return $global:adminSessionId;
    }
}
function EricomConnectDisconnector()
{
    if ($global:adminSessionId -ne $null)
    {
        $adminApi.LogoutAdminSession($global:adminSessionId)
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
	
	add-type -Path ( $MegaConnectRuntimeApiDll, $CloudConnectUtilitiesDll)
    $Assem = ( $MegaConnectRuntimeApiDll, $CloudConnectUtilitiesDll)
	
	return $Assem
}
function GetFormattedData()
{
    ConnectToGrid

	$Status = $adminApi.GetStatusIndicators($global:adminSessionId);

    $data = New-Object System.Collections.Hashtable;
    foreach($element in $Status) {
        $label = $element.Label.Replace("AdminUiMessageDescriptors.", "");
        [System.Collections.ArrayList]$value = $element.Value;
        if ($value.Count -gt 1) {
            $value.RemoveAt(0);
        }
        $entry = @{
            Value = $value;
            Condition = $element.Condition;
        }
        $data.Add($label, $entry);
    }
    return $data;
}
Function GetDataByLabel($LabelToFind)
{
    $data = GetFormattedData
    return $data.Item($LabelToFind).Value;
}

function TestDaysTillExpire ( $AlertDaysBefore ){ 
    $res = GetDataByLabel("LicenseExpiration")
    $TS = New-TimeSpan -Start (Get-Date) -End $res[0]
    $Days = $TS.Days.ToString()
    $Message = ("Ericom Connect License will expire in $Days Days.`n")
    Write-EventLogEricom -Message $Message -EventID 2
    if ($Days -lt $AlertDaysBefore)
    {
        Write-EventLogEricomError -Message $Message -EventID 12    
        SendEricomMail -Text $Message -TestName "Licesning Expiraton Alert" ;
    }
        #send mail 
    return $TS.Days
}

function TestNumberOfLicense ( $AlertLowLicenseLimit ) {
    $Num = GetDataByLabel("LicenseStatus")
    # Key 0 -> Used Licenses, 1 -> Number of Licenses, 2 -> used percentage
   
    $Using = $Num[0]
    $Total = $Num[1]
    $Message = ("Ericom Connect License is using $Using licenses out of $Total.`n")
    
    $Free = $Total - $Using 
    if ($Free -lt $AlertLowLicenseLimit)
    {
        Write-EventLogEricomError -Message $Message -EventID 13
        SendEricomMail -Text $Message -TestName "Licesning Limit Alert" ;
    }

    Write-EventLogEricom -Message $Message -EventID 3
    return $Num[1];
}
function TestLogMessageQueue ( $AlertSizeMessageLog ) {
    $Num = GetDataByLabel("LogMessageQueue")
    $Message = ("Ericom Connect Database Queue size is $Num.`n")
    
    if ($Num -gt $AlertSizeMessageLog)
    {
        Write-EventLogEricomError -Message $Message -EventID 14
        SendEricomMail -Text $Message -TestName "Log Queue limit" ;
    }

    Write-EventLogEricom -Message $Message -EventID 4

    return $Num[0];
}

function Ignore-SelfSignedCerts
{
	add-type -ErrorAction SilentlyContinue -TypeDefinition  @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(
                ServicePoint srvPoint, X509Certificate certificate,
                WebRequest request, int certificateProblem) {
                return true;
            }
}
"@
	[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
} #function


Function PingURL ($url)
{
	Ignore-SelfSignedCerts
	$result = Invoke-WebRequest -Uri $url -Method GET -ErrorAction SilentlyContinue -ErrorVariable ErrorText
	
	[pscustomobject]@{
		ErrorText = $ErrorText
		StatusCode = $result.StatusCode
	}
	
}

Function Execute-Command ($commandPath, $commandArguments)
{
	$pinfo = New-Object System.Diagnostics.ProcessStartInfo
	$pinfo.FileName = $commandPath
	$pinfo.RedirectStandardError = $true
	$pinfo.RedirectStandardOutput = $true
	$pinfo.UseShellExecute = $false
	$pinfo.Arguments = $commandArguments
	$p = New-Object System.Diagnostics.Process
	$p.StartInfo = $pinfo
	$p.Start() | Out-Null
	$stdout = $p.StandardOutput.ReadToEnd()
	$stderr = $p.StandardError.ReadToEnd()
	$p.WaitForExit()
	Write-Host "stdout: $stdout"
	#Write-Host "stderr: $stderr"
	[pscustomobject]@{
		Output = $stdout
		ExitCode = $p.ExitCode
	}
}


function TestGrid {
	$configPath = Join-Path $env:ProgramFiles -ChildPath $ConnectCLIPath.Trim()
	$arguments = " GridInfo /waitForSec 10";
	Write-Verbose "$arguments"
	  $TestGrid = Execute-Command -commandPath $configPath -commandArguments "$arguments"
	
	# for remtote machine
	#$AdminSecurePassword = ConvertTo-SecureString -String $NetworkPassword -AsPlainText -Force
	#$AdminCredentials = New-Object System.Management.Automation.PSCredential ($NetworkAdmin, $AdminSecurePassword);
    #$TestGrid = Invoke-Command -ComputerName $Connectserver -Credential $AdminCredentials -ScriptBlock ${function:Execute-Command} -ArgumentList $configPath, $arguments 
	
	$exitCodeCli = $TestGrid.ExitCode;
	$TestValue = $TestGrid.Output;
	
	if ($exitCodeCli -eq 0)
	{
		if (($TestValue -like '*Fail*') -or ($TestValue -like '*No grid machines found*'))
		{
			Write-EventLogEricomError -Message ("Ericom Grid is not intact. Response to Gridinfo command was:`n" + $TestValue) -EventID 15
			SendErrorMail -ErrorText $TestValue -TestName Grid 
		}
		else
		{
			Write-EventLogEricom -Message "Ericom Connect Grid is intact.`n" -EventID 5
			
		}
		
		$PingResult = PingURL -url $EUWSaddress
		if ($PingResult.StatusCode -eq 200)
		{
			Write-EventLogEricom -Message "Ericom Connect EUWS is ok.`n" -EventID 6
		}
		else
		{
			Write-EventLogEricomError -Message ("Ericom Connect EUWS is not responding. Result of ping was:`n" + $PingResult.ErrorText) -EventID 16
			SendErrorMail -ErrorText $PingResult.ErrorText -TestName EUWS;
		}
		
		$PingResult = PingURL -url $ESGaddress
		if ($PingResult.StatusCode -eq 200)
		{
			Write-EventLogEricom -Message ("Ericom ESG is ok`n" + $PingResult) -EventID 7
			
		}
		else
		{
			Write-EventLogEricomError -Message ("Ericom Connect ESG is is not responding. Result of ping was:`n" + $PingResult.ErrorText) -EventID 17
			SendErrorMail -ErrorText $PingResult.ErrorText -TestName ESG;
		}
		
	}
	else
	{
           SendErrorMail -ErrorText $exitCodeCli -TestName RunCLiCommand;
		Write-Verbose ("Failed to run GridTest Exit Code: " + $exitCodeCli)
		
	}
	
	#few more tests
	# alert if message log size is bigger then 100
	TestLogMessageQueue -AlertSizeMessageLog 100
	# alert if only 10 license are free
    TestNumberOfLicense -AlertLowLicenseLimit 10
        # alert if license will expaire in less then 10 days
    TestDaysTillExpire -AlertDaysBefore 10
	
}

function SendEricomMail ()
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$Text,
		[Parameter(Mandatory = $true)]
		[string]$TestName
	)
	
	$Subject = "Ericom Connect " + $TestName + " On " + (hostname)
	$Message = '<h1>Ericom Connect ' + $TestName + ' was raised at '+ (Get-Date) +'.</h1><p>Dear Customer ,<br><br> Ericom ' + $TestName + ' on ' + [System.Net.Dns]::GetHostByName((hostname)).HostName + ' have happend with this info: <br><br><i>"' + $Text + '"</i> <br><br> Regards,<br><a href="http://www.ericom.com">Ericom</a> Automation Team'
	
	New-Item -Path "C:\SendEricomMail" -ItemType Directory -Force -ErrorAction SilentlyContinue
	#Write-EventLogEricom -Message ("Ericom Connect Sent an Mail`nInfo: " + $Text + "`nTest: " + $TestName)
	
	$securePassword = ConvertTo-SecureString -String $SMTPassword -AsPlainText -Force
	$credential = New-Object System.Management.Automation.PSCredential ("daas@ericom.com", $securePassword)
	$date = (Get-Date).ToString();
	$ToName = $To.Split("@")[0].Replace(".", " ");
	if ($To -ne "nobody")
	{
		try
		{
			Send-MailMessage -Body "$Message" -BodyAsHtml -Subject "$Subject" -SmtpServer $SmtpServer -Port $SMTPPort -Credential $credential -From $credential.UserName -To $To -bcc "erez.pasternak@ericom.com", "DaaS@ericom.com" -ErrorAction SilentlyContinue
		}
		catch
		{
			$_.Exception.Message | Out-File "C:\SendEricomMail.txt"
		}
	}
}

function SendErrorMail ()
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$ErrorText,
		[Parameter(Mandatory = $true)]
		[string]$TestName
	)
	
	$Subject = "Ericom Connect " + $TestName + " is not Responding On " + (hostname)
	$Message = '<h1>Ericom Connect ' + $TestName + ' is not responding at '+ (Get-Date) +'.</h1><p>Dear Customer ,<br><br> Ericom ' + $TestName + ' on ' + [System.Net.Dns]::GetHostByName((hostname)).HostName + ' have failed with this error: <br><br><i>"' + $ErrorText + '"</i> <br><br> Regards,<br><a href="http://www.ericom.com">Ericom</a> Automation Team'
	
	New-Item -Path "C:\SendProblemMail" -ItemType Directory -Force -ErrorAction SilentlyContinue
	#Write-EventLogEricomError -Message ("Ericom Connect Sent an Error Mail`nError: " + $ErrorText + "`nFailure at test: " + $TestName)
	
	$securePassword = ConvertTo-SecureString -String $SMTPassword -AsPlainText -Force
	$credential = New-Object System.Management.Automation.PSCredential ("daas@ericom.com", $securePassword)
	$date = (Get-Date).ToString();
	$ToName = $To.Split("@")[0].Replace(".", " ");
	if ($To -ne "nobody")
	{
		try
		{
			Send-MailMessage -Body "$Message" -BodyAsHtml -Subject "$Subject" -SmtpServer $SmtpServer -Port $SMTPPort -Credential $credential -From $credential.UserName -To $To -bcc "erez.pasternak@ericom.com", "DaaS@ericom.com" -ErrorAction SilentlyContinue
		}
		catch
		{
			$_.Exception.Message | Out-File "C:\SendErrorMail.txt"
		}
	}
}

function SendSuccessMail ()
{
	param (
		[string]$Error
	)
	$Subject = "Ericom Connect Grid is UP " + (hostname)
	$Message = '<h1>Ericom Connect Grid is up !</h1><p>Dear Customer ,<br><br> Ericom Grid on ' + [System.Net.Dns]::GetHostByName((hostname)).HostName + ' is running with this status: <br><br><i>"' + $Error + '"</i> <br><br> Regards,<br><a href="http://www.ericom.com">Ericom</a> Automation Team'
	
	New-Item -Path "C:\SendSuccessMail" -ItemType Directory -Force -ErrorAction SilentlyContinue
	
	$AdminSecurePassword = ConvertTo-SecureString -String $AdminPassword -AsPlainText -Force
	$AdminCredentials = New-Object System.Management.Automation.PSCredential ($AdminUser, $AdminSecurePassword);
	
	$securePassword = ConvertTo-SecureString -String $SMTPassword -AsPlainText -Force
	$credential = New-Object System.Management.Automation.PSCredential ("daas@ericom.com", $securePassword)
	$date = (Get-Date).ToString();
	$ToName = $To.Split("@")[0].Replace(".", " ");
	if ($To -ne "nobody")
	{
		try
		{
			Send-MailMessage -Body "$Message" -BodyAsHtml -Subject "$Subject" -SmtpServer $SmtpServer -Port $SMTPPort -Credential $credential -From $credential.UserName -To $To -bcc "erez.pasternak@ericom.com", "DaaS@ericom.com" -ErrorAction SilentlyContinue
		}
		catch
		{
			$_.Exception.Message | Out-File "C:\SendSuccessMail.txt"
		}
	}
}

Function Start-Monitoring
{
	While ($true)
	{
		# Do things lots
		TestGrid
		
		# Add a pause so the loop doesn't run super fast and use lots of CPU        
		Start-Sleep -s 60
	}
}

#use this if you want a loop without a windows task
#Start-Monitoring
#CreateGridLogs -logsPath c:\
TestGrid