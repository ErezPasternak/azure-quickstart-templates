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


# E-mail Settings
$To = "erez.pasternak@ericom.com"
$externalFqdn = [System.Net.Dns]::GetHostByName((hostname)).HostName


$ConnectCLIPath = "\Ericom Software\Ericom Connect Configuration Tool\ConnectCLI.exe"


$emailTemplate = "WebServer\DaaS\emails\ready.html"
$From = "daas@ericom.com"
$SMTPServer = "ericom-com.mail.protection.outlook.com"
$SMTPSUser = "daas@ericom.com"
$SMTPasswordUser = "admin"
$SMTPPort = 25

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
        Output =  $stdout
        ExitCode = $p.ExitCode  
    }
}

function TestGrid {
    $configPath = Join-Path $env:ProgramFiles -ChildPath $ConnectCLIPath.Trim()
    $arguments = " GridInfo /waitForSec 10";
    Write-Verbose "$arguments"           
    $TestGrid = Execute-Command -commandPath $configPath -commandArguments "$arguments"
    $exitCodeCli = $TestGrid.ExitCode;
    $TestValue = $TestGrid.Output;
    
    if ($exitCodeCli -eq 0) 
    {
           if ($TestValue -like '*Intact*' -and !($TestValue -like '*Fail*'))
           {
                SendSuccessMail($TestValue);
                Write-Verbose "Grid Is alive"
            }
    } 
    else 
    {
           SendErrorMail($exitCodeCli);
           Write-Verbose ("Failed to run GridTest Exit Code: " + $exitCodeCli)

    }

}


function SendErrorMail ()
{
	param (
		[string]$Error
	)
	
	$Subject = "Ericom Connect Grid is Down " + (hostname)	
	$Message = '<h1>Ericom Connect Grid is down !</h1><p>Dear Customer ,<br><br> Ericom Grid on ' + [System.Net.Dns]::GetHostByName((hostname)).HostName +' have failed with this error: <br><br><i>"' + $Error + '"</i> <br><br> Regards,<br><a href="http://www.ericom.com">Ericom</a> Automation Team'

	New-Item -Path "C:\SendProblemMail" -ItemType Directory -Force -ErrorAction SilentlyContinue
    
    $AdminSecurePassword = ConvertTo-SecureString -String $AdminPassword -AsPlainText -Force
	$AdminCredentials = New-Object System.Management.Automation.PSCredential ($AdminUser, $AdminSecurePassword);
    $MailPassword = ((Get-ADUser $SMTPasswordUser -Server $domainName -Credential $AdminCredentials -Properties HomePage | Select HomePage).HomePage | Out-String).Trim()	

	$securePassword = ConvertTo-SecureString -String $MailPassword -AsPlainText -Force
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
	$Message = '<h1>Ericom Connect Grid is up !</h1><p>Dear Customer ,<br><br> Ericom Grid on ' + [System.Net.Dns]::GetHostByName((hostname)).HostName +' is running with this status: <br><br><i>"' + $Error + '"</i> <br><br> Regards,<br><a href="http://www.ericom.com">Ericom</a> Automation Team'

	New-Item -Path "C:\SendSuccessMail" -ItemType Directory -Force -ErrorAction SilentlyContinue
    
    $AdminSecurePassword = ConvertTo-SecureString -String $AdminPassword -AsPlainText -Force
	$AdminCredentials = New-Object System.Management.Automation.PSCredential ($AdminUser, $AdminSecurePassword);
    $MailPassword = ((Get-ADUser $SMTPasswordUser -Server $domainName -Credential $AdminCredentials -Properties HomePage | Select HomePage).HomePage | Out-String).Trim()	

	$securePassword = ConvertTo-SecureString -String $MailPassword -AsPlainText -Force
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
Start-Monitoring


# Main Code

