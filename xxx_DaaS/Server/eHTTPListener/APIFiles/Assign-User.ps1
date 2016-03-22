param(
    [String]$Username,
    [String]$Password,
    [String]$Template,
    [String]$Email,
    [String]$EmailPath = "C:\DaaS-Portal\Website\emails",
    [String]$externalFqdn
)

Function GetSSOUrl
{
    param(
        [string]$externalFqdn = "localhost"
    )
    $url = "https://$externalFqdn/EricomXml/AirSSO/AccessSSO.htm"
    return $url    
} 

Function SendMailTo {
   Param (
    [Parameter()][String]$To = "david.oprea@ericom.com",
    [Parameter()][String]$Subject = "Test",
    [Parameter()][String]$Message = "This is an automatic Email created at $date"
   )
    
	$date=(Get-Date).TOString();
	
    [String]$SMTPServer = "ericom-com.mail.protection.outlook.com"
    [String]$Port = 25
    [String]$From = "daas@ericom.com"
    
    $securePassword = ConvertTo-SecureString -String "1qaz@Wsx#" -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential ("daas@ericom.com", $securePassword)
    $date = (Get-Date).ToString();
    
    $BCC = @( "david.oprea@ericom.com", "erez.pasternak@ericom.com" )
    try {
	    Send-MailMessage -Body "$Message" -BodyAsHtml -Subject "$Subject" -SmtpServer $SmtpServer -Port $Port -Credential $credential -From $credential.UserName -To $To -Bcc $BCC -ErrorAction SilentlyContinue | Out-Null
    } catch {
        $_.Exception.Message | Out-File "C:\emaildebug.txt"
    }
}

Function SendReadyEmail
{
    param(
        [string]$To,
        [string]$Username,
        [string]$Password,
        [string]$EmailPath,
        [string]$externalFqdn
    )
    
    if ($To -eq "") {
        $To = "Erez.Pasternak@ericom.com"
    }

    $subject = (Get-Content $EmailPath | Select -First 1  | Out-String).Replace("#subject:", "").Trim();

    $content = (Get-Content $EmailPath | Select -Skip 1 | Out-String);
    $message = $content.Replace("#username#", $Username); 
    $message = $message.Replace("#password#", $Password);
    $url = (GetSSOUrl -externalFqdn $externalFqdn) + "?" + "username=$Username&password=$Password&group=Desktop2012&appName=VirtualDesktop&autostart=true"
    $here = "<a href=`"$url`">here</a>";
    $message = $message.Replace("#here#", $here);

    SendMailTo -To $Email -Subject "$subject" -Message $message | Out-Null
}



#$user = Get-ADUser {Name -eq $Username }
$user = Get-ADUser $Username
$dName = (Get-ADDomainController).Domain
$isSuccess = $true
$message = ""
try {
    # remove user from previous groups
    $previousGroups = $null
    $previousGroups = (Get-ADPrincipalGroupMembership $user | Select Name | Where { $_.Name -like "*workers" })
    if($previousGroups -ne $null -and $previousGroups.Name.Count -gt 1) {
        foreach($item in $previousGroups.Name) {
            Remove-ADGroupMember -Identity "$item" -Members "$user" -Confirm:$false
        }
    }
} catch { Write-Warning "Something went wrong when removing the membership"; Write-Warning $_.Exception.Message }
try {        
    switch($Template){
        "1" {
            $group = Get-ADGroup TaskWorkers
            Add-ADGroupMember $group –Members $user
        }
        "2" {
            $group = Get-ADGroup KnowledgeWorkers
            Add-ADGroupMember $group –Members $user
        }
        "3" {
            $group = Get-ADGroup MobileWorkers
            Add-ADGroupMember $group –Members $user
        }
        default {
        }
    }
} catch {
    $isSuccess = $false;
    $message = $_.Exception.Message
    Write-Warning $message
}

$response = $null;
if ($isSuccess -eq $true) {
    $emailFile = Join-Path $EmailPath -ChildPath "ready.html"
    SendReadyEmail -To $Email -Username $Username -Password $Password -EmailPath "$emailFile" -externalFqdn "$externalFqdn"
    
    $homepage = ((GetSSOUrl -externalFqdn $externalFqdn) + "?username=$Username&password=$Password&group=Desktop2012&appName=VirtualDesktop&autostart=true")
    try {
        Set-ADUser -Identity $Username -HomePage $homepage -ErrorAction SilentlyContinue
    } catch { }

    $response = @{
        status = "OK"
        success = "true"
        message = "User has been successfuly added to the selected group"
        url = $homepage 
    }
} else {
    $response = @{
        status = "ERROR"
        message = "$message"
    }
}
return $response
