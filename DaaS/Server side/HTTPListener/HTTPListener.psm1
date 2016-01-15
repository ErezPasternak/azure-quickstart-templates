# Copyright (c) 2014 Microsoft Corp.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

$_Configuration = @{
	Domain = "test.local"
}

Function ConvertTo-HashTable {
    <#
    .Synopsis
        Convert an object to a HashTable
    .Description
        Convert an object to a HashTable excluding certain types.  For example, ListDictionaryInternal doesn't support serialization therefore
        can't be converted to JSON.
    .Parameter InputObject
        Object to convert
    .Parameter ExcludeTypeName
        Array of types to skip adding to resulting HashTable.  Default is to skip ListDictionaryInternal and Object arrays.
    .Parameter MaxDepth
        Maximum depth of embedded objects to convert.  Default is 4.
    .Example
        $bios = get-ciminstance win32_bios
        $bios | ConvertTo-HashTable
    #>
    
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Object]$InputObject,
        [string[]]$ExcludeTypeName = @("ListDictionaryInternal","Object[]"),
        [ValidateRange(1,10)][Int]$MaxDepth = 4
    )

    Process {

        Write-Verbose "Converting to hashtable $($InputObject.GetType())"
        #$propNames = Get-Member -MemberType Properties -InputObject $InputObject | Select-Object -ExpandProperty Name
        $propNames = $InputObject.psobject.Properties | Select-Object -ExpandProperty Name
        $hash = @{}
        $propNames | % {
            if ($InputObject.$_ -ne $null) {
                if ($InputObject.$_ -is [string] -or (Get-Member -MemberType Properties -InputObject ($InputObject.$_) ).Count -eq 0) {
                    $hash.Add($_,$InputObject.$_)
                } else {
                    if ($InputObject.$_.GetType().Name -in $ExcludeTypeName) {
                        Write-Verbose "Skipped $_"
                    } elseif ($MaxDepth -gt 1) {
                        $hash.Add($_,(ConvertTo-HashTable -InputObject $InputObject.$_ -MaxDepth ($MaxDepth - 1)))
                    }
                }
            }
        }
        $hash
    }
}

Function SendMailTo {
   Param (
    [Parameter()][String]$To = "sebastian.constantinescu@ericom.com"
   )
    
	$date=(Get-Date).TOString();
	
    [String]$SMTPServer = "ericom-com.mail.protection.outlook.com"
    [String]$Port = 25
    [String]$From = "daas@ericom.com"
    [String]$Subject = "Test"
    [String]$Message = "This is an automatic Email created at $date"
    
    $securePassword = ConvertTo-SecureString -String "1qaz@Wsx#" -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential ("daas@ericom.com", $securePassword)
    $date = (Get-Date).ToString();

    Write-Verbose $credential.UserName
	
	Send-MailMessage -Body "$Message" -BodyAsHtml -Subject "$Subject" -SmtpServer $SmtpServer -Port $Port -Credential $credential -From $credential.UserName -To $To -ErrorAction Continue
    #Send-MailMessage -SmtpServer 'ericom-com.mail.protection.outlook.com' -Port 25 -credential $mycreds -UseSsl -From daas@ericom.com -To sebastian.constantinescu@ericom.com -Subject 'Some Subject' -Body 'Automatic Email' -BodyAsHtml
	#Write-Verbose "Send-MailMessage -SmtpServer $SMTPServer -Port $Port -credential $mycreds -UseSsl -From $From -To $To -Subject $Subject -Body $Message -BodyAsHtml"
    #$Invoke-Expression $Command   
}

Function Create-User {
	param(
		[String]$Username = "new.user",
		[String]$Password = "123!#abcd",
		[String]$Email = "generic.user@ericom.com"
	)
    FindAndCreateUserInGroup -Username $Username -Password $Password -Email $Email 
}

Function FindAndCreateUserInGroup {
	param(
		[String]$Username,
		[String]$Password,
		[String]$Email
	)
	
	$securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force	
	$usrTemplate = Get-ADUser "generic.user1"

    $when = ((Get-Date).AddDays(-30)).Date

    $users = Get-ADUser -Filter {whenCreated -ge $when -and Name -like "udaas-*"} -Properties whenCreated | Sort-Object whenCreated -Descending
    $userNo = $users.Item(0).Name.Substring(6);
    $userNo = $userNo.ToInt32($Null)+1;

    $mLength= $users.Item(0).Name.Substring(6).Length

    $length = $mLength - $userNo.ToString().Length

    $Name = $userNo.ToString()

    for ($i=1; $i -le $length; $i++){
        $Name = $Name.Insert(0,0)
    }
        
		
	New-ADUser -SamAccountName $Username -Instance $usrTemplate -Name "udaas-$Name" -Enabled $true -Verbose -EmailAddress $Email -AccountPassword $securePassword

}

Function PopulateAd {
   New-ADOrganizationalUnit -Name TaskWorkers -Path "DC=test,  DC=local" -ErrorAction Continue 
   New-ADOrganizationalUnit -Name KnowledgeWorkers -Path "DC=test,  DC=local" -ErrorAction Continue 
   New-ADOrganizationalUnit -Name MobileWorkers -Path "DC=test,  DC=local" -ErrorAction Continue
   New-AdUSER -SamAccountName "generic.user1" -Name "udaas-000001" 
   New-AdUSER -SamAccountName "generic.user2" -Name "udaas-000002" 
}

Function Assign-User {
    param(
    [String]$Username,
    [String]$Template
    )

    $user = Get-ADUser $Username
    $dName = Get-ADDomain | Select-Object DistinguishedName
    $dName = $dName.DistinguishedName.ToString()

    switch($Template){
        "1" {
            Move-ADObject $user -TargetPath "OU=TaskWorkers,$dName"
        }
        "2" {
            Move-ADObject $user -TargetPath "OU=KnowledgeWorkers,$dName"
        }
        "3" {
            Move-ADObject $user -TargetPath "OU=MobileWorkers,$dName"
        }
        default {
        }
    }

}

Function Get-AppList {
    param(
      [string]$adminUser       = "admin@test.local",
      [string]$adminPassword   = "admin",
      [string]$outFile         = "NoOutFile"
    )


$adminUser    = "admin@test.local"
$adminPassword = "admin"

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

function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

$SaveToFile #
$NoOutFileStr = "NoOutFile"
if($outFile -eq $NoOutFileStr)
{
    $script:SaveToFile = $false
    $script:outFilePath
}
else
{
    $script:SaveToFile = $true
    $script:outFilePath = Join-Path (Get-ScriptDirectory) $outFile
    #clear the file.
    #out-file -filepath $outFilePath
}
$outFilePath      = "C:\Users\admin\Desktop\out.txt"
#$outFilePath = "E:\PM\Dev\CloudConnect\Code\CloudConnect\PsScripts\out.txt"


#LogIn
$regularUser = New-Object Ericom.CloudConnect.Utilities.SpaceCredentials("regularUser")
$adminApi = [Ericom.MegaConnect.Runtime.XapApi.AdministrationProcessingUnitClassFactory]::GetInstance($regularUser)
$adminSessionId = $adminApi.CreateAdminsession($adminUser, $adminPassword,"rooturl","en-us")
$AppList = $adminApi.ResourceDefinitionSearch($adminSessionId.AdminSessionId,$null,$null)

foreach ($app in $AppList)
{
     $RHData = New-Object Ericom.MegaConnect.Runtime.XapApi.ResourceDefinition;
     $RHData = $app;

     $Displayname = $RHData.DisplayName;
     $icon = $RHData.DisplayProperties.GetLocalPropertyValue("IconString")
    
     Write-Output $Displayname
     #Write-Output $icon
}

}

Function Start-HTTPListener {
    <#
    .Synopsis
        Creates a new HTTP Listener accepting PowerShell command line to execute
    .Description
        Creates a new HTTP Listener enabling a remote client to execute PowerShell command lines using a simple REST API.
        This function requires running from an elevated administrator prompt to open a port.

        Use Ctrl-C to stop the listener.  You'll need to send another web request to allow the listener to stop since
        it will be blocked waiting for a request.
    .Parameter Port
        Port to listen, default is 8888
    .Parameter URL
        URL to listen, default is /
    .Parameter Auth
        Authentication Schemes to use, default is IntegratedWindowsAuthentication
    .Example
        Start-HTTPListener -Port 8080 -Url PowerShell
        Invoke-WebRequest -Uri "http://localhost:8888/PowerShell?command=get-service winmgmt&format=text" -UseDefaultCredentials | Format-List *
    #>
    
    Param (
        [Parameter()]
        [Int] $Port = 8889,

        [Parameter()]
        [String] $Url = "",
        
        [Parameter()]
        [System.Net.AuthenticationSchemes] $Auth = [System.Net.AuthenticationSchemes]::IntegratedWindowsAuthentication
        )

    Process {
     #   $ErrorActionPreference = "Stop"
        PopulateAD

        $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent())
        if ( -not ($currentPrincipal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator ))) {
            Write-Error "This script must be executed from an elevated PowerShell session" 
        }

        if ($Url.Length -gt 0 -and -not $Url.EndsWith('/')) {
            $Url += "/"
        }

        $listener = New-Object System.Net.HttpListener
        $prefix = "http://*:$Port/$Url"
        $listener.Prefixes.Add($prefix)
        $listener.AuthenticationSchemes = $Auth 
        try {
            $listener.Start()
            while ($true) {
                $statusCode = 200
                Write-Warning "Note that thread is blocked waiting for a request.  After using Ctrl-C to stop listening, you need to send a valid HTTP request to stop the listener cleanly."
                Write-Warning "Sending 'exit' command will cause listener to stop immediately"
                Write-Verbose "Listening on $port..."
                $context = $listener.GetContext()
                $request = $context.Request

                if (!$request.IsAuthenticated) {
                    Write-Warning "Rejected request as user was not authenticated"
                    $statusCode = 403
                    $commandOutput = "Unauthorized"
                } else {
                    $identity = $context.User.Identity
                    Write-Verbose "Received request $(get-date) from $($identity.Name):"
                    $request | fl * | Out-String | Write-Verbose
                
                    # only allow requests that are the same identity as the one who started the listener
                    if ($identity.Name -ne $CurrentPrincipal.Identity.Name) {
                        Write-Warning "Rejected request as user doesn't match current security principal of listener"Ne
                        $statusCode = 403
                        $commandOutput = "Unauthorized"
                    } else {
                        if (-not $request.QueryString.HasKeys()) {
                            $commandOutput = "SYNTAX: command=<string> format=[JSON|TEXT|XML|NONE|CLIXML]"
                            $Format = "TEXT"
                            } else {
                             
                            $command = $request.QueryString.Item("command")


                            switch ($command) {
                                "exit" {
                                    Write-Verbose "Received command to exit listener"
                                    return
                                }
                                "Send-Mail" {
                                    Write-Verbose "Received command to send email"
                                    $to = $request.QueryString.Item("to");
                                    $command = "SendMailTo -To $to"
                                }
                                "Create-User"{
									# Create an AD User using a powershell function
                                    Write-Verbose "Received command to create user"
                                    $username = $request.QueryString.Item("username");
                                    $email = $request.QueryString.Item("email");
                                    $command = "Create-User -Username $username -Email $email"
                                }
                                "Assign-User"{
                                #variables: user, adgroup
                                    Write-Verbose "Received command to assign user to organizational unit"
                                    $username = $request.QueryString.Item("username");
                                    $group = $request.QueryString.Item("group");
                                    $command = "Assign-User -Username $username -Template $group"
                                }
                                "Get-AppList"{
                                #return list of apps and icons
                                    Write-Verbose "Received command to retrieve application list from Ericom Connect"
                                    $command = "Get-AppList"
                                }
                                "PublishAppsToUser"{
                                #variables: user, list of apps
                                }
                                default{
                                  
                                }
                                
                            }
							
                            $Format = $request.QueryString.Item("format")
                            if ($Format -eq $Null) {
                                $Format = "JSON"
                            }
                            Write-Verbose "*******************"
                            Write-Verbose "Request = $request"
                            Write-Verbose "Command = $command"
                            Write-Verbose "Format = $Format"
                            
                          #  $Decode = [System.Web.HttpUtility]::UrlDecode($command) 
                          #  Write-Verbose "Request $command changed to $($Decode)"
                          #  Write-Verbose "*******************"

                            try {
                                $script = $ExecutionContext.InvokeCommand.NewScriptBlock($command)                        
                                $commandOutput = & $script
                            } catch {
                                $commandOutput = $_ | ConvertTo-HashTable
                                $statusCode = 500
                            }
                        }
                        $commandOutput = switch ($Format) {
                            TEXT    { $commandOutput | Out-String ; break } 
                            JSON    { $commandOutput | ConvertTo-JSON; break }
                            XML     { $commandOutput | ConvertTo-XML -As String; break }
                            CLIXML  { [System.Management.Automation.PSSerializer]::Serialize($commandOutput) ; break }
                            default { "Invalid output format selected, valid choices are TEXT, JSON, XML, and CLIXML"; $statusCode = 501; break }
                        }
                    }
                }

                Write-Verbose "Response:"
                if (!$commandOutput) {
                    $commandOutput = [string]::Empty
                }
                Write-Verbose $commandOutput

                $response = $context.Response
                $response.StatusCode = $statusCode
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($commandOutput)

                $response.ContentLength64 = $buffer.Length
                $output = $response.OutputStream
                $output.Write($buffer, 0, ($buffer.Length))
                $output.Close()

                #$sw = New-Object IO.StreamWriter $output
                #$sw.Write($buffer, 0, ($buffer.Length-1))
                #$response.Close()
                #$sw.Close()
                #$output.Write($buffer, 0, ($buffer.Length-1))
                #$output.Flush();
                #$output.Close()
            }
        } finally {
           $listener.Stop()
        }
    }
}