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
$To = "mendy.newman@ericom.com"
$externalFqdn = [System.Net.Dns]::GetHostByName((hostname)).HostName

$ConnectCLIPath = "\Ericom Software\Ericom Connect Configuration Tool\ConnectCLI.exe"

$emailTemplate = "WebServer\DaaS\emails\ready.html"
$From = "daas@ericom.com"
$SMTPServer = "ericom-com.mail.protection.outlook.com"
$SMTPSUser = "daas@ericom.com"
$SMTPassword = ""
$SMTPPort = 25


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
		[string]$Message
	)
	$LogName = "Application"
	$SourceName = "Ericom Connect Monitoring"
	$EventID = 1
	Write-EventLog -LogName $LogName -source $SourceName -EventId $EventID -message "$Message" -EntryType Information
}

function Write-EventLogEricomError
{
	[CmdletBinding()]
	[OutputType([int])]
	Param (
		[Parameter(Mandatory = $true)]
		[string]$Message
	)
	$LogName = "Application"
	$SourceName = "Ericom Connect Monitoring"
	$EventID = 1
	Write-EventLog -LogName $LogName -source $SourceName -EventId $EventID -message "$Message" -EntryType Error
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
	#  $TestGrid = Execute-Command -commandPath $configPath -commandArguments "$arguments"
	
	# for remtote machine
	$AdminSecurePassword = ConvertTo-SecureString -String $NetworkPassword -AsPlainText -Force
	$AdminCredentials = New-Object System.Management.Automation.PSCredential ($NetworkAdmin, $AdminSecurePassword);
    $TestGrid = Invoke-Command -ComputerName $Connectserver -Credential $AdminCredentials -ScriptBlock ${function:Execute-Command} -ArgumentList $configPath, $arguments 
	
	$exitCodeCli = $TestGrid.ExitCode;
	$TestValue = $TestGrid.Output;
	
	if ($exitCodeCli -eq 0)
	{
		if (($TestValue -like '*Fail*') -or ($TestValue -like '*No grid machines found*'))
		{
			Write-EventLogEricomError -Message ("Ericom Grid is not intact. Response to Gridinfo command was:`n" + $TestValue)
			SendErrorMail -ErrorText $TestValue -TestName Grid;
		}
		else
		{
			Write-EventLogEricom -Message "Ericom Connect Grid is intact.`n"
			
		}
		
		$PingResult = PingURL -url $EUWSaddress
		if ($PingResult.StatusCode -eq 200)
		{
			Write-EventLogEricom -Message "Ericom Connect EUWS is ok.`n"
		}
		else
		{
			Write-EventLogEricomError -Message ("Ericom Connect EUWS is not responding. Result of ping was:`n" + $PingResult.ErrorText)
			SendErrorMail -ErrorText $PingResult.ErrorText -TestName EUWS;
		}
		
		$PingResult = PingURL -url $ESGaddress
		if ($PingResult.StatusCode -eq 200)
		{
			Write-EventLogEricom -Message ("Ericom ESG is ok`n" + $PingResult)
			
		}
		else
		{
			Write-EventLogEricomError -Message ("Ericom Connect ESG is is not responding. Result of ping was:`n" + $PingResult.ErrorText)
			SendErrorMail -ErrorText $PingResult.ErrorText -TestName ESG;
		}
		
	}
	else
	{
           SendErrorMail -ErrorText $exitCodeCli -TestName RunCLiCommand;
		Write-Verbose ("Failed to run GridTest Exit Code: " + $exitCodeCli)
		
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
	
	$Subject = "Ericom Connect " + $TestName + " is not Responding. " + (hostname)
	$Message = '<h1>Ericom Connect ' + $TestName + ' is not responding as of [DATE].</h1><p>Dear Customer ,<br><br> Ericom ' + $TestName + ' on ' + [System.Net.Dns]::GetHostByName((hostname)).HostName + ' have failed with this error: <br><br><i>"' + $ErrorText + '"</i> <br><br> Regards,<br><a href="http://www.ericom.com">Ericom</a> Automation Team'
	
	New-Item -Path "C:\SendProblemMail" -ItemType Directory -Force -ErrorAction SilentlyContinue
	Write-EventLogEricomError -Message ("Ericom Connect Sent an Error Mail`nError: " + $ErrorText + "`nFailure at test: " + $TestName)
	
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
			$_.Exception.Message | Out-File "C:\SendProblemMail.txt"
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

TestGrid