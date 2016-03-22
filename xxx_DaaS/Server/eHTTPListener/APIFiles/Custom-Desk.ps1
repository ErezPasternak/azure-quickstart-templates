param(
    [String]$Username,
    [String]$Password,
    [String]$Template,
    [String]$Email,
    [String]$EmailPath,
    [String]$externalFqdn,
    [String]$hw,
    [String]$os,
    [String]$apps,
    [String]$services
)
$adminUsername = $AdminUser;
$adminPassword = $AdminPass;

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

Function Start-EricomConnection { 
    $Assem = Import-EricomLib

    $regularUser = New-Object Ericom.CloudConnect.Utilities.SpaceCredentials("regularUser")
    $adminApi = [Ericom.MegaConnect.Runtime.XapApi.AdministrationProcessingUnitClassFactory]::GetInstance($regularUser)
    return $adminApi
}

Function Import-EricomLib {
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

Function Create-ADUserBinding
{
    param(
        [Parameter()][string]$adminUser,
        [Parameter()][string]$adminPassword,
        [Parameter()][String]$resourceGroup,
        [Parameter()][string]$adUser
    )
    $groupName = $resourceGroup;

    $adminApi = Start-EricomConnection
    $adminSessionId = ($adminApi.CreateAdminsession($adminUser, $adminPassword,"rooturl","en-us")).AdminSessionId

    $resources = $adminApi.ResourceGroupSearch($adminSessionId, $null, $null, $null)
    # check if resource group already exists
    $rGroup = $null;
    $isPresent = $false;
    foreach ($resource in $resources){
        if ( $resource.DisplayName -eq $groupName) {
            $isPresent = $true;
            $rGroup = $resource;
        }
    }

    if ($isPresent -eq $true) {
        [Ericom.MegaConnect.Runtime.XapApi.BindingGroupType]$adGroupBindingType = 1
        $adName = (Get-ADDomainController).Domain
        $adDomainId = $adUser + "@" + $adName;
        $rGroup.AddBindingGroup("$adUser", $adGroupBindingType, $adName, $adDomainId);
        $adminApi.UpdateResourceGroup($adminSessionId, $rGroup);
    }
}

Function Create-ResourceGroup
{
    param(
        [Parameter()][string]$adminUser,
        [Parameter()][string]$adminPassword,
        [Parameter()][String]$groupName
    )


    $adminApi = Start-EricomConnection
    $adminSessionId = ($adminApi.CreateAdminsession($adminUser, $adminPassword,"rooturl","en-us")).AdminSessionId

    $resources = $adminApi.ResourceGroupSearch($adminSessionId, $null, $null, $null)

    # check if resource group already exists
    $isPresent = $false;
    foreach ($resource in $resources){
        if ( $resource.DisplayName -eq $groupName) {
            $isPresent = $true;
        }
    }

    # create resource group
    if ($isPresent -eq $false) {
        $rGroup = $adminApi.CreateResourceGroup($adminSessionId, $groupName)
        $adminApi.AddResourceGroup($adminSessionId, $rGroup)
    }
}

function Get-ResourceDefinitionId
{
    param(
        [Parameter()][string]$adminUser,
        [Parameter()][string]$adminPassword,
        [Parameter()][string]$applicationName,
        [Parameter()][string]$aliasName = ""
    )
    $applicationName = $applicationName.Trim();

    if($applicationName -eq "Desktop") {
        $aliasName = "VirtualDesktop"
    }

    $adminApi = Start-EricomConnection
    $adminSessionId = ($adminApi.CreateAdminsession($adminUser, $adminPassword,"rooturl","en-us")).AdminSessionId

    $AppList = $adminApi.ResourceDefinitionSearch($adminSessionId,$null,$null)
    $foundApp = $null
    foreach ($app in $AppList)
    {
        if($app.DisplayName -eq $applicationName -or $app.DisplayName -eq $aliasName) {
            $foundApp = $app.ResourceDefinitionId;
        }    
    }
    return $foundApp
}

Function Create-ResourceDefinitionBinding
{
    param(
        [Parameter()][string]$adminUser,
        [Parameter()][string]$adminPassword,
        [Parameter()][String]$resourceGroup,
        [Parameter()][string]$applicationName,
        [Parameter()][string]$aliasName = "",
        [Parameter()][bool]$desktopShortcut = $true
    )
    $applicationName = $applicationName.Trim();

    if($applicationName -eq "Desktop") {
        $aliasName = "VirtualDesktop"
        $desktopShortcut = $false
    }
    $groupName = $resourceGroup;

    $adminApi = Start-EricomConnection
    $adminSessionId = ($adminApi.CreateAdminsession($adminUser, $adminPassword,"rooturl","en-us")).AdminSessionId

    $resources = $adminApi.ResourceGroupSearch($adminSessionId, $null, $null, $null)
    $rGroup = $null;
    # check if resource group already exists
    $isPresent = $false;
    foreach ($resource in $resources){
        if ( $resource.DisplayName -eq $groupName) {
            $isPresent = $true;
            $rGroup = $resource;
        }
    }

    # resource group found, now check for app
    if ($isPresent) {
        $foundApp = Get-ResourceDefinitionId -adminUser $adminUser -adminPassword $adminPassword -applicationName $applicationName -aliasName $aliasName
        # try publish it
        if ($foundApp -eq $null) {
            if ($applicationName -eq "Desktop") {
                Publish-Desktop -adminUser $adminUser -adminPassword $adminPassword -aliasName $aliasName -desktopShortcut $desktopShortcut
            } else {
                Publish-App -adminUser $adminUser -adminPassword $adminPassword -applicationName $applicationName -aliasName $aliasName -desktopShortcut $desktopShortcut
            }
            $foundApp = Get-ResourceDefinitionId -adminUser $adminUser -adminPassword $adminPassword -applicationName $applicationName -aliasName $aliasName
        }
        if ($foundApp -ne $null) {
            $adminApi = Start-EricomConnection
            $adminSessionId = ($adminApi.CreateAdminsession($adminUser, $adminPassword,"rooturl","en-us")).AdminSessionId
            $rlist = $rGroup.ResourceDefinitionIds
            $rlist.Add($foundApp);
            $rGroup.ResourceDefinitionIds = $rlist
            try {
                $output = $adminApi.UpdateResourceGroup($adminSessionId, $rGroup)
            } catch {
                Write-Warning $adminSessionId
                Write-Warning $rGroup
                Write-Warning $_.Exception.Message
            }
        }
    }
}

function Create-SystemBinding
{
    param(
        [Parameter()][string]$adminUser,
        [Parameter()][string]$adminPassword,
        [Parameter()][String]$resourceGroup,
        [Parameter()][string]$remoteHostGroup
    )
    $adminApi = Start-EricomConnection
    $adminSessionId = ($adminApi.CreateAdminsession($adminUser, $adminPassword,"rooturl","en-us")).AdminSessionId

    $resources = $adminApi.ResourceGroupSearch($adminSessionId, $null, $null, $null)
    $rGroup = $null;
    # check if resource group already exists
    $isPresent = $false;
    foreach ($resource in $resources){
        if ( $resource.DisplayName -eq $groupName) {
            $isPresent = $true;
            $rGroup = $resource;
        }
    }

    # resource group found, now check for remote host group
    if ($isPresent) {
        $rhmc = [Ericom.MegaConnect.Runtime.XapApi.RemoteHostMembershipComputation]::Explicit
        $rhg = $adminApi.RemoteHostGroupSearch($adminSessionId, $rhmc, 100, $remoteHostGroup)
        if ($rhg.Count -gt 0) {

            [System.Collections.Generic.List[String]]$remoteHostsGroupList = New-Object System.Collections.Generic.List[String];
            foreach($g in $rhg)
            {
	            $remoteHostsGroupList.Add($g.RemoteHostGroupId)
            }
            $rGroup.RemoteHostGroupIds = $remoteHostsGroupList
            $adminApi.UpdateResourceGroup($adminSessionId, $rGroup)
        }
    }
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
    # should we create dedicated AD group? No.
    $createADgroup = $false;
    if ($createADgroup -eq $true) {
        $userADGroup = "DaaS-Group-" + $user;
        New-ADGroup -Name "$userADGroup" -SamAccountName $userADGroup -GroupCategory Security -GroupScope Universal -DisplayName "$userADGroup"
        $group = Get-ADGroup $userADGroup
        Add-ADGroupMember $group -Members $user
    }

    # create resource group
    $groupName = "DaaS-" + $Username
    Create-ResourceGroup -adminUser $adminUsername -adminPassword $adminPassword -groupName $groupName | Out-Null

    # publish apps per group
    $appslist = $apps.Split(",");
    foreach($app in $appslist) {
        Create-ResourceDefinitionBinding -adminUser $adminUsername -adminPassword $adminPassword -resourceGroup $groupName -applicationName ($app.Trim())  | Out-Null
    }

    $groupNameDesktop = "DaaS-" + $Username + "Desktop"
    Create-ResourceGroup -adminUser $adminUsername -adminPassword $adminPassword -groupName $groupNameDesktop  | Out-Null
    Create-ResourceDefinitionBinding -adminUser $adminUsername -adminPassword $adminPassword -resourceGroup $groupNameDesktop -applicationName "Desktop" -aliasName "VirtualDesktop"  | Out-Null

    # create user binding
    Create-ADUserBinding -adminUser $adminUsername -adminPassword $adminPassword -resourceGroup $groupName -adUser $Username  | Out-Null
    Create-ADUserBinding -adminUser $adminUsername -adminPassword $adminPassword -resourceGroup $groupNameDesktop -adUser $Username  | Out-Null

    # create system binding
    $desktopHost = "Win12"
    if ($os.Trim() -eq "Windows 7") {
        $desktopHost = "Win2008"
    }
    $appHost = "apps"
    Create-SystemBinding -adminUser $adminUsername -adminPassword $adminPassword -resourceGroup $groupName -remoteHostGroup $appHost  | Out-Null
    Create-SystemBinding -adminUser $adminUsername -adminPassword $adminPassword -resourceGroup $groupNameDesktop -remoteHostGroup $desktopHost  | Out-Null

} catch {
    $isSuccess = $false;
    $message = $_.Exception.Message
    Write-Warning $message
}

$response = $null;
if ($isSuccess -eq $true) {
    $emailFile = Join-Path $EmailPath -ChildPath "ready.html"
    SendReadyEmail -To $Email -Username $Username -Password $Password -EmailPath "$emailFile" -externalFqdn "$externalFqdn"  | Out-Null
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