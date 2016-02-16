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

[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")  | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices.AccountManagement") | Out-Null


Function GetSSOUrl
{
    param(
        [string]$externalFqdn = "localhost"
    )
    $url = "https://$externalFqdn/EricomXml/AirSSO/AccessSSO.htm"
    return $url    
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
        [ValidateRange(1,10)][Int]$MaxDepth = 10
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
    [Parameter()][String]$To = "sebastian.constantinescu@ericom.com",
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
    
    $BCC = @( "daasmwc.huawei@gmail.com" , "david.oprea@ericom.com", "erez.pasternak@ericom.com" )
    try {
	    Send-MailMessage -Body "$Message" -BodyAsHtml -Subject "$Subject" -SmtpServer $SmtpServer -Port $Port -Credential $credential -From $credential.UserName -To $To -Bcc $BCC -ErrorAction SilentlyContinue | Out-Null
    } catch { }
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
        $To = "daasmwc.huawei@gmail.com"
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

Function Get-MimeType { 
  <# 
    .NOTES 
        Author: greg zakharov 
  #> 
  param( 
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)] 
    [ValidateScript({Test-Path $_})] 
    [String]$File 
  ) 
   
  $res = 'text/plain' 
   
  try { 
    $rk = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey( 
      ($ext = ([IO.FileInfo](($File = cvpa $File))).Extension.ToLower()) 
    ) 
  } 
  finally { 
    if ($rk -ne $null) { 
      if (![String]::IsNullOrEmpty(($cur = $rk.GetValue('Content Type')))) { 
        $res = $cur 
      } 
      $rk.Close() 
    } #if 
  } 
   
  Write-Host $File`: -f Yellow -no 
  $res 
}

Function Create-User {
	param(
		[String]$Username = "new.user",
		[String]$Password = "123!#abcd",
		[String]$Email = "generic.user@ericom.com",
        [String]$BaseADGroupRDP = "DaaS-RDP"
	)
    return (FindAndCreateUserInGroup -Username $Username -Password $Password -Email $Email -BaseADGroupRDP $BaseADGroupRDP)
}

Function Auth-User {
    param(
    	[String]$Username = "new.user",
		[String]$Password = "123!#abcd"
    )

    return (Test-ADCredentials -Username $Username -Password $Password)
}

Function Test-ADCredentials {
    param(
        $Username = 'user1',
        $Password = 'P@ssw0rd'
    )
    $Domain = (Get-ADDomainController).Domain

    Add-Type -AssemblyName System.DirectoryServices.AccountManagement
    $ct = [System.DirectoryServices.AccountManagement.ContextType]::Domain
    $pc = New-Object System.DirectoryServices.AccountManagement.PrincipalContext $ct, $Domain
    $isValid = ($pc.ValidateCredentials($Username, $Password) | Out-String).ToString().Trim() -eq "True"
    $response = $null
    if ($isValid -eq $true) {
        $email = ((Get-AdUser $Username -Properties EmailAddress | Select EmailAddress).EmailAddress | Out-String).Trim()

        $response = @{
            status = "OK"
            success = "true"
            email = "$email"
            message = "Authentication OK"
        }
    } else {
        $response = @{
            status = "ERROR"
            message = "Authentication failed!"
        }
    }
    return $response
}

Function List-AllApps{
    param(
      [string]$adminUser       = "admin@test.local",
      [string]$adminPassword   = "admin",
      $adminApi
    )


    $adminApi = Start-EricomConnection
    $adminSessionId = ($adminApi.CreateAdminsession($adminUser, $adminPassword,"rooturl","en-us"))


    $RemoteHostList = $adminApi.RemoteHostStatusSearch($adminSessionId.AdminSessionId, "Running", "", "100", "100", "0", "", "true", "true", "true")
    [Array]$OutArray = @()

    [System.Collections.Generic.List[Object]]$serverAppList = New-Object System.Collections.Generic.List[Object];

    #FlattenFilesForDirectory(string remoteHostId, List<HostApplication> applications, string remoteAgentId, BrowsingFolder browsingFolder)
    function FlattenFilesForDirectory ($browsingFolder)
    {
	    foreach ($browsingItem in $browsingFolder.Files.Values)
	    {
            #$script:OutArray =  [Array]$OutArray + $browsingItem
            $serverAppList.Add($browsingItem)
	    }

	    foreach ($directory in $browsingFolder.SubFolders.Values)
	    {
		    FlattenFilesForDirectory($directory);
	    } 
    }

    foreach ($RH in $RemoteHostList)
    {
    
       $RHData = New-Object Ericom.MegaConnect.Runtime.XapApi.BrowsingApplication
       $RHData.Path = $RH.SystemInfo.ComputerName
       $script:OutArray =  [Array]$OutArray + $RHData
        ""
        ""
        $RH.SystemInfo.ComputerName
        "____________"
        ""
        $browsingFolder = $adminApi.SendCustomRequest(	$adminSessionId.AdminSessionId, 
												        $RH.RemoteAgentId,
											           [Ericom.MegaConnect.Runtime.XapApi.StandaloneServerRequestType]::HostAgentApplications,
											           "null",
											           "false",
											           "999999999")
       #$browsingFolder
       FlattenFilesForDirectory ($browsingFolder)
    }
    foreach ($app in $serverAppList){
        Write-Output $app
    }
}

Function Create-RemoteHostsGroup {
       param(
      [string]$adminUser       = "admin@test.local",
      [string]$adminPassword   = "admin",
      [string]$groupName = "newGroup"
      )

    $groupName = $groupName
    $adminApi = Start-EricomConnection
    $adminSessionId = $adminApi.CreateAdminsession($adminUser, $adminPassword,"rooturl","en-us");
    [Ericom.MegaConnect.Runtime.XapApi.RemoteHostMembershipComputation]$rhmc = 0;
    $rGroup = $adminApi.CreateRemoteHostGroup($adminSessionId.AdminSessionId, $groupName, $rhmc);
    [System.Collections.Generic.List[String]]$remoteHostsList = New-Object System.Collections.Generic.List[String];

    [Ericom.MegaConnect.Runtime.XapApi.RemoteHostSearchConstraints]$rhsc = New-Object Ericom.MegaConnect.Runtime.XapApi.RemoteHostSearchConstraints;
    $rhsc.HostnamePattern = "win-*"; #TODO: Update HERE!
    $rhl = $adminApi.GetRemoteHostList($adminSessionId.AdminSessionId, $rhsc)
    foreach($h in $rhl)
    {
	    $remoteHostList.Add($h.RemoteHostId)
    }
    $rGroup.RemoteHostIds = $remoteHostsList;
    $adminApi.AddRemoteHostGroup($adminSessionId.AdminSessionId, $rGroup)

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

Function Publish-App {
    param(
        [Parameter()][string]$adminUser,
        [Parameter()][string]$adminPassword,
        [Parameter()][string]$applicationName,
        [Parameter()][string]$aliasName,
        [Parameter()][bool]$desktopShortcut =  $true
    )

    $adminApi = Start-EricomConnection
    $adminSessionId = $adminApi.CreateAdminsession($adminUser, $adminPassword,"rooturl","en-us")
    $goon = $true;
    $response = $null;

    $RemoteHostList = $adminApi.RemoteHostStatusSearch($adminSessionId.AdminSessionId, "Running", "", "100", "100", "0", "", "true", "true", "true")

    function FlattenFilesForDirectory
    {
        param(
            $browsingFolder,
            $rremoteAgentId,
            $rremoteHostId,
            $goon
        )

        if ($goon -ne $true) { return $false; }

	    foreach ($browsingItem in $browsingFolder.Files.Values)
	    {
            if($goon -eq $true -and ($browsingItem.Label -eq $applicationName) )
            {
                $appName = $applicationName
                if($aliasName.Length -gt 0) {
                    $appName = $aliasName
                }
                $resourceDefinition = $adminApi.CreateResourceDefinition($adminSessionId.AdminSessionId, $applicationName)

                $val1 = $resourceDefinition.ConnectionProperties.GetLocalPropertyValue("remoteapplicationmode")
                $val1.LocalValue = $true
                $val1.ComputeBy = "Literal"

                $val2 = $resourceDefinition.ConnectionProperties.GetLocalPropertyValue("alternate_S_shell")
                $val2.LocalValue = "" +  $browsingItem.Path + $browsingItem.Name + ""
                $val2.ComputeBy = "Literal"
                $val2.LocalValue

                $val3 = $resourceDefinition.DisplayProperties.GetLocalPropertyValue("IconLength")
                $val3.LocalValue = $browsingItem.ApplicationString.Length
                $val3.ComputeBy = "Literal"

                $valS = $resourceDefinition.DisplayProperties.GetLocalPropertyValue("ShortcutDesktop")
                $valS.LocalValue = $desktopShortcut
                $valS.ComputeBy = "Literal"

                $val4 = $resourceDefinition.DisplayProperties.GetLocalPropertyValue("IconString")
                $val4.LocalValue = $browsingItem.ApplicationString
                $val4.ComputeBy = "Literal"

                $val5 = $resourceDefinition.DisplayProperties.GetLocalPropertyValue("DisplayName")
                $val5.LocalValue = $appName
                $val5.ComputeBy = "Literal"

                try 
                {
                    $adminApi.AddResourceDefinition($adminSessionId.AdminSessionId, $resourceDefinition, "true") | Out-Null
                } 
                catch [Exception] 
                {
                }
                $goon = $false;
                return $false;
            }
        }

        if ($goon -eq $true) {
	        foreach ($directory in $browsingFolder.SubFolders.Values)
	        {
                if ($goon -eq $true) {
		            $goon = FlattenFilesForDirectory -browsingFolder $directory -rremoteAgentId $rremoteAgentId -rremoteHostId $rremoteHostId -goon $goon
                }
	        }
        }
        return ($goon -eq $true)
    }


    foreach ($RH in $RemoteHostList)
    {
        $browsingFolder = $adminApi.SendCustomRequest(	$adminSessionId.AdminSessionId, 
												        $RH.RemoteAgentId,
											           [Ericom.MegaConnect.Runtime.XapApi.StandaloneServerRequestType]::HostAgentApplications,
											           "null",
											           "false",
											           "999999999")

       if($goon -eq $true) {
            $goon = FlattenFilesForDirectory -browsingFolder $browsingFolder -rremoteAgentId $RH.RemoteAgentId -rremoteHostId $RH.RemoteHostId -goon $goon
       }
       if($goon -ne $true)
       {
            return
       }
    }
}

Function Publish-Desktop {
    param(
        [Parameter()][string]$adminUser,
        [Parameter()][string]$adminPassword,
        [Parameter()][string]$aliasName,
        [Parameter()][bool]$desktopShortcut =  $true
    )

    $applicationName = "Desktop"

    $adminApi = Start-EricomConnection
    $adminSessionId = $adminApi.CreateAdminsession($adminUser, $adminPassword,"rooturl","en-us")
    
    $response = $null;

    $appName = $applicationName
    if($aliasName.Length -gt 0) {
        $appName = $aliasName
    }
    $resourceDefinition = $adminApi.CreateResourceDefinition($adminSessionId.AdminSessionId, $applicationName)

    $iconfile = "$env:windir\system32\mstsc.exe"

    $val1 = $resourceDefinition.ConnectionProperties.GetLocalPropertyValue("remoteapplicationmode")
    $val1.LocalValue = $false
    $val1.ComputeBy = "Literal"

    try {
        $iconstring = [System.Drawing.Icon]::ExtractAssociatedIcon($iconfile).ToString();
        $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconfile);
        $iconstream = New-Object System.IO.MemoryStream;
        $icon.ToBitmap().Save($iconstream, [System.Drawing.Imaging.ImageFormat]::Png)
        $iconbytes = $iconstream.ToArray();
        $iconbase64 = [convert]::ToBase64String($iconbytes)
        $iconstream.Flush();
        $iconstream.Dispose();
        

        $val3 = $resourceDefinition.DisplayProperties.GetLocalPropertyValue("IconLength")
        $val3.LocalValue = $iconbase64.Length
        $val3.ComputeBy = "Literal"

        $val4 = $resourceDefinition.DisplayProperties.GetLocalPropertyValue("IconString")
        $val4.LocalValue = $iconbase64
        $val4.ComputeBy = "Literal"
    } catch {
        Write-Warning $_.Exception.Message
    }

    $valS = $resourceDefinition.DisplayProperties.GetLocalPropertyValue("ShortcutDesktop")
    $valS.LocalValue = $desktopShortcut
    $valS.ComputeBy = "Literal"

    $val5 = $resourceDefinition.DisplayProperties.GetLocalPropertyValue("DisplayName")
    $val5.LocalValue = $appName
    $val5.ComputeBy = "Literal"

    $response = @{}
    try 
    {
        $adminApi.AddResourceDefinition($adminSessionId.AdminSessionId, $resourceDefinition, "true")

        $response = @{
            status = "OK"
            success = "true"
            id = $resourceDefinition.ResourceDefinitionId
            message = "The resource has been successfuly published."
        }
    } 
    catch [Exception] 
    {
        $response = @{
            status = "ERROR"
            message = $_.Exception.Message
        }
    }
    return $response
}

Function Create-ADGroupBinding
{
    param(
        [Parameter()][string]$adminUser,
        [Parameter()][string]$adminPassword,
        [Parameter()][String]$resourceGroup,
        [Parameter()][string]$adGroup
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
        [Ericom.MegaConnect.Runtime.XapApi.BindingGroupType]$adGroupBindingType = 2
        $adName = (Get-ADDomainController).Domain
        $rGroup.AddBindingGroup("$adGroup", $adGroupBindingType, $adName, ("id_" + $adGroup));
        $adminApi.UpdateResourceGroup($adminSessionId, $rGroup)
    }
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
        $rGroup.AddBindingGroup("$adUser", $adGroupBindingType, $adName, ("id_" + $adUser));
        $adminApi.UpdateResourceGroup($adminSessionId, $rGroup);
    }
}

Function FindAndCreateUserInGroup {
	param(
		[String]$Username,
		[String]$Password,
		[String]$Email,
        [String]$BaseADGroupRDP
	)
    
    $response = $null

    $securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force	
    $domainName = (Get-ADDomainController).Domain
    $hasError = $false;
    try {
	    New-ADUser -PasswordNeverExpires $true -SamAccountName $Username -Name "$Username" -Enabled $true -Verbose -EmailAddress $Email -AccountPassword $securePassword -UserPrincipalName ("$Username" + "@" + "$domainName") -ErrorAction Continue
        Add-ADGroupMember -Identity (Get-ADGroup $BaseADGroupRDP) -Members $Username
    } catch  {
        $hasError = $true;
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
    }
    if ($hasError -eq $false) {
        # OK
        $response = @{
            success = "true"
            status = "OK"
            message = "Your account has been created."
        }
    } else {
        # problems
        $response = @{
            status = "ERROR"
            message = "$ErrorMessage"
        }
    }

    return $response
}

Function PopulateAd {
   New-ADGroup -Name "Task Workers" -SamAccountName TaskWorkers -GroupCategory Security -GroupScope Global -DisplayName "Task Workers" -Description "Members of this group are Task Workers"  
   #New-ADOrganizationalUnit -Name TaskWorkers -Path "DC=test,  DC=local" -ErrorAction Continue 
   #New-ADOrganizationalUnit -Name KnowledgeWorkers -Path "DC=test,  DC=local" -ErrorAction Continue 
   New-ADGroup -Name "Knowledge Workers" -SamAccountName KnowledgeWorkers -GroupCategory Security -GroupScope Global -DisplayName "Knowledge Workers" -Description "Members of this group are Knowledge Workers"  
   #New-ADOrganizationalUnit -Name MobileWorkers -Path "DC=test,  DC=local" -ErrorAction Continue
   New-ADGroup -Name "Mobile Workers" -SamAccountName MobileWorkers -GroupCategory Security -GroupScope Global -DisplayName "Mobile Workers" -Description "Members of this group are Mobile Workers"  
   New-AdUSER -SamAccountName "generic.user1" -Name "udaas-000001" 
   New-AdUSER -SamAccountName "generic.user2" -Name "udaas-000002" 
}

Function PopulateConnect{
    param(
      [string]$adminUser       = "admin@test.local",
      [string]$adminPassword   = "admin",
      $adminApi
    )

    $adminUser    = "admin@test.local"
    $adminPassword = "admin"

    $adminApi = Start-EricomConnection
    $adminSessionId = ($adminApi.CreateAdminsession($adminUser, $adminPassword,"rooturl","en-us")).AdminSessionId

    $resources = $adminApi.ResourceGroupSearch($adminSessionId, $null, $null, $null)

    foreach ($resource in $resources){
        if ( $resource.DisplayName -eq "TaskWorkers") {
        $taskW = 1;
        }
        if ( $resource.DisplayName -eq "KnowledgeWorkers") {
        $knowledgeW = 1;
        }
        if ( $resource.DisplayName -eq "MobileWorkers") {
        $mobileW = 1;
        }

    }

    if ($taskW -ne 1) {
        $rGroup = $adminApi.CreateResourceGroup($adminSessionId, "TaskWorkers")
        $adminApi.AddResourceGroup($adminSessionId, $rGroup)
    }
    if ($knowledgeW -ne 1) {
        $rGroup = $adminApi.CreateResourceGroup($adminSessionId, "KnowledgeWorkers")
        $adminApi.AddResourceGroup($adminSessionId, $rGroup)
    }
    if ($mobileW -ne 1){
        $rGroup = $adminApi.CreateResourceGroup($adminSessionId, "MobileWorkers")
        $adminApi.AddResourceGroup($adminSessionId, $rGroup)
    }
}

Function Assign-User {
    param(
        [String]$Username,
        [String]$Password,
        [String]$Template,
        [String]$Email,
        [String]$EmailPath,
        [String]$externalFqdn
    )


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

        $response = @{
            status = "OK"
            success = "true"
            message = "User has been successfuly added to the selected group"
            url = ((GetSSOUrl -externalFqdn $externalFqdn) + "?username=$Username&password=$Password&group=Desktop2012&appName=VirtualDesktop&autostart=true")
        }
    } else {
        $response = @{
            status = "ERROR"
            message = "$message"
        }
    }
    return $response
}

Function Custom-Desk {
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
        Create-ResourceGroup -adminUser $adminUsername -adminPassword $adminPassword -groupName $groupName

        # publish apps per group
        $appslist = $apps.Split(",");
        foreach($app in $appslist) {
            Create-ResourceDefinitionBinding -adminUser $adminUsername -adminPassword $adminPassword -resourceGroup $groupName -applicationName ($app.Trim())
        }

        $groupNameDesktop = "DaaS-" + $Username + "Desktop"
        Create-ResourceGroup -adminUser $adminUsername -adminPassword $adminPassword -groupName $groupNameDesktop
        Create-ResourceDefinitionBinding -adminUser $adminUsername -adminPassword $adminPassword -resourceGroup $groupNameDesktop -applicationName "Desktop" -aliasName "VirtualDesktop"

        # create user binding
        Create-ADUserBinding -adminUser $adminUsername -adminPassword $adminPassword -resourceGroup $groupName -adUser $Username
        Create-ADUserBinding -adminUser $adminUsername -adminPassword $adminPassword -resourceGroup $groupNameDesktop -adUser $Username

        # create system binding
        $desktopHost = "Desktop2012"
        $appHost = "App2012"
        Create-SystemBinding -adminUser $adminUsername -adminPassword $adminPassword -resourceGroup $groupName -remoteHostGroup $appHost
        Create-SystemBinding -adminUser $adminUsername -adminPassword $adminPassword -resourceGroup $groupNameDesktop -remoteHostGroup $desktopHost

    } catch {
        $isSuccess = $false;
        $message = $_.Exception.Message
        Write-Warning $message
    }

    $response = $null;
    if ($isSuccess -eq $true) {
        $emailFile = Join-Path $EmailPath -ChildPath "ready.html"
        SendReadyEmail -To $Email -Username $Username -Password $Password -EmailPath "$emailFile" -externalFqdn "$externalFqdn"

        $response = @{
            status = "OK"
            success = "true"
            message = "User has been successfuly added to the selected group"
            url = ((GetSSOUrl -externalFqdn $externalFqdn) + "?username=$Username&password=$Password&group=Desktop2012&appName=VirtualDesktop&autostart=true")
        }
    } else {
        $response = @{
            status = "ERROR"
            message = "$message"
        }
    }
    return $response
}

Function Get-AppList {
    param(
      [string]$adminUser       = "admin@test.local",
      [string]$adminPassword   = "admin",
      [string]$groupList       = ""
    )

    $adminApi = Start-EricomConnection
    $adminSessionId = $adminApi.CreateAdminsession($adminUser, $adminPassword,"rooturl","en-us")
    if($groupList.Length -gt 0) { $groups = $groupList.Split(",") } else { $groups = New-Object System.Collections.ArrayList }
    [System.Collections.ArrayList]$jsonList = New-Object System.Collections.ArrayList

    if ($groups.Count -eq 0) {
        $AppList = $adminApi.ResourceDefinitionSearch($adminSessionId.AdminSessionId,$null,$null)
        foreach ($app in $AppList)
        {
             $RHData = New-Object Ericom.MegaConnect.Runtime.XapApi.ResourceDefinition
             $RHData = $app;

             $Displayname = $RHData.DisplayName;
             $icon = $RHData.DisplayProperties.GetLocalPropertyValue("IconString")
             $resourceId = $RHData.ResourceDefinitionId
             $path = $RHData.Path;
             $remoteAgentId = $RHData.RemoteAgentId

             $resource = @{
                title = $DisplayName
                icon = ("data:image/png;base64," + $icon)
                resourceId = $resourceId
             }
             $jsonList.Add($resource) | Out-Default
        }
        return $jsonList
    } else {
        # grab the apps per resource group specified.
        $resources = $adminApi.ResourceGroupSearch($adminSessionId.AdminSessionId, $null, $null, $null)
        $groupDictionary = New-Object "System.Collections.Generic.Dictionary[[System.String],[System.Object]]"
        foreach ($resource in $resources){
            foreach($item in $groups) {
                if($resource.DisplayName -eq $item) {
                    [System.Collections.ArrayList]$apps = New-Object System.Collections.ArrayList
                    if ($resource.ResourceDefinitionIds.Count -gt 0) {
                        foreach($rdid in $resource.ResourceDefinitionIds) {
                            $item = $adminApi.GetResourceDefinition($adminSessionId.AdminSessionId, $rdid.ToString().Trim());
                            $appDictionary = New-Object "System.Collections.Generic.Dictionary[[System.String],[System.Object]]"
                            try {
                                $appDictionary.Add("title", $item.DisplayName.ToString());
                                $appDictionary.Add("icon", ("data:image/png;base64," + $item.DisplayProperties.GetLocalPropertyValue("IconString").LocalValue.ToString()));
                                $appDictionary.Add("resourceId", $rdid.ToString());
                                $appDictionary.Add("groupName", $resource.DisplayName.ToString());
                                $apps.Add($appDictionary) | Out-Default
                            } catch {
                                
                            }
                        }
                    }                    
                    $groupDictionary.Add($resource.DisplayName, $apps) | Out-Default
                }
            }
        }
        return $groupDictionary
    }
}

Function Get-ServerAppList {
    param(
      [string]$adminUser       = "admin@test.local",
      [string]$adminPassword   = "admin",
      $adminApi
    )

    $adminUser    = "admin@test.local"
    $adminPassword = "admin"

    $adminApi = Start-EricomConnection
    $adminSessionId = $adminApi.CreateAdminsession($adminUser, $adminPassword, "rooturl", "en-us")
    $AppList = $adminApi.GetApplicationsForServer($adminSessionId.AdminSessionId, "99bcf7ca-950c-40ad-bc20-91fa83c0d07c")



    foreach ($app in $AppList)
    {
         $RHData = New-Object Ericom.MegaConnect.Runtime.XapApi.ResourceDefinition;
         $RHData = $app;

         $Displayname = $RHData.DisplayName;
         $icon = $RHData.DisplayProperties.GetLocalPropertyValue("IconString")
         $resourceId = $RHData.ResourceDefinitionId
    
         Write-Output $Displayname
         Write-Output $icon
         Write-Output $resourceId
    
    }
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

        [Parameter(Mandatory)]
        [String]$AdminUser = "",
        
        [Parameter(Mandatory)]
        [String]$AdminPass = "",

        [Parameter()]
        [String]$WebsitePath,

        [Parameter()]
        [String]$BaseADGroupRDP,
        
        [Parameter()]
        [String]$externalFqdn,

        [Parameter()]
        [String]$daasFolderUrl = "DaaS",

        [Parameter()]
        [System.Net.AuthenticationSchemes] $Auth = [System.Net.AuthenticationSchemes]::Anonymous
        )

    Process {
        [System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')  | Out-Null

        $emailPath = Join-Path -Path $WebsitePath -ChildPath ("emails")

        #PopulateAD
        #PopulateConnect
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

                if ($request.Url -ne "") {
                    $identity = $context.User.Identity
                    Write-Verbose "Received request $(get-date) from $($identity.Name):"
                    $request | fl * | Out-String | Write-Verbose

                    $checkExistingPath = "";

                    #Write-Warning $request.Url.AbsolutePath
                    #Write-Warning $request.Url.AbsoluteUri
                    #Write-Warning $request.Url.Host
                    #Write-Warning $request.Url.Port
                    #Write-Warning $request.Url.LocalPath
                    #Write-Warning $request.Url.PathAndQuery
                    #Write-Warning $request.Url.Query
                    $nameValuePair = $null
                    if($request.HttpMethod -eq "POST") {
                        $body = $context.Request.InputStream
                        $encoding = $context.Request.ContentEncoding
                        [System.IO.StreamReader]$streamReader = New-Object System.IO.StreamReader($body, $encoding);
                        $postdata = $streamReader.ReadToEnd();
                        $nameValuePair = ($postdata | Out-String | ConvertFrom-Json);
                    }

                    $isApi = $false

                    if ($request.Url.Query.StartsWith("?command") -or $nameValuePair.Command -ne $null) {
                        $isApi = $true
                    }
                        
                    if ($isApi -eq $false) {
                        Write-Warning "Non-command Request"
                        $commandOutput = "SYNTAX: command=<string> format=[JSON|TEXT|XML|NONE|CLIXML]"
                        $Format = "BINARY"
                        $reqFile = $request.Url.LocalPath.ToString();

                        $currentPath =  $WebsitePath;
                        if ($reqFile.Length -gt 1 -and $reqFile.StartsWith("/$daasFolderUrl")) {
                            $reqFile = $reqFile.Substring(($daasFolderUrl.Length +1))
                        }
                        $checkExistingPath = Join-Path -Path $currentPath -ChildPath ("$reqFile")
                    } else {
                        Write-Warning "Command Request"
                        if ($request.HttpMethod -eq "POST") {
                            [string]$command = $nameValuePair.command;
                        } else {
                            [string]$command = $request.QueryString.Item("command")
                        }

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
                                if ($request.HttpMethod -eq "POST") {
                                    [string]$username = $nameValuePair.username;
                                    [string]$password = $nameValuePair.password;
                                    [string]$email = $nameValuePair.email;
                                } else {
                                    [string]$username = $request.QueryString.Item("username");
                                    [string]$password = $request.QueryString.Item("password");
                                    [string]$email = $request.QueryString.Item("email");
                                }
                                $command = "Create-User -Username `"$username`" -Email `"$email`" -Password `"$password`" -BaseADGroupRDP `"$BaseADGroupRDP`""
                            }
                            "Auth-User"{
								# Create an AD User using a powershell function
                                Write-Verbose "Received command to create user"
                                if ($request.HttpMethod -eq "POST") {
                                    [string]$username = $nameValuePair.username;
                                    [string]$password = $nameValuePair.password;
                                } else {
                                    [string]$username = $request.QueryString.Item("username");
                                    [string]$password = $request.QueryString.Item("password");
                                }
                                $command = "Auth-User -Username `"$username`" -Password `"$password`""
                            }
                            "Assign-User"{
                                Write-Verbose "Received command to assign user to organizational unit"
                                if ($request.HttpMethod -eq "POST") {
                                    [string]$email = $nameValuePair.email;
                                    [string]$username = $nameValuePair.username;
                                    [string]$password = $nameValuePair.password;
                                    [string]$config = $nameValuePair.config;
                                } else {
                                    [string]$email = $request.QueryString.Item("email");
                                    [string]$username = $request.QueryString.Item("username");
                                    [string]$password = $request.QueryString.Item("password");
                                    [string]$config = $request.QueryString.Item("config");
                                }

                                $command = "Assign-User -Username `"$username`" -Password `"$password`" -Template `"$config`" -EmailPath `"$emailPath`" -Email `"$email`" -externalFqdn `"$externalFqdn`""
                            }
                            "Get-AppList"{
                                #return list of apps and icons
                                if ($request.HttpMethod -eq "POST") {
                                    $groupList = $nameValuePair.groups;
                                } else {
                                    $groupList = $request.QueryString.Item("groups");
                                }
                                Write-Verbose "Received command to retrieve application list from Ericom Connect"
                                $command = "Get-AppList -adminUser $EC_AdminUser -adminPassword $EC_AdminPass -groupList `"$groupList`""
                            }
                            "Custom-Desk"{
                                Write-Verbose "Received command to create a new user inside organizational unit with its own apps"
                                if ($request.HttpMethod -eq "POST") {
                                    [string]$email = $nameValuePair.email;
                                    [string]$username = $nameValuePair.username;
                                    [string]$password = $nameValuePair.password;
                                    [string]$hw = $nameValuePair.hardware;
                                    [string]$os = $nameValuePair.os;
                                    [string]$applications = $nameValuePair.applications;
                                    [string]$services = $nameValuePair.services;
                                    
                                } else {
                                    [string]$email = $request.QueryString.Item("email");
                                    [string]$username = $request.QueryString.Item("username");
                                    [string]$password = $request.QueryString.Item("password");
                                    [string]$hw = $request.QueryString.Item("hardware");
                                    [string]$os = $request.QueryString.Item("os");
                                    [string]$applications = $request.QueryString.Item("applications");
                                    [string]$services = $request.QueryString.Item("services");
                                }

                                $command = "Custom-Desk -Username `"$username`" -Password `"$password`" -Template `"$config`" -EmailPath `"$emailPath`" -Email `"$email`" -externalFqdn `"$externalFqdn`" -hw `"$hw`" -os `"$os`" -apps `"$applications`" -services `"$services`" "
                            }
                            "Get-AllAppList" {
                                Write-Verbose "Received command to retrieve application list from all hosts"
                                $command = "Get-AllAppList"
                            }
                            "Create-RemoteHostsGroup"{
                                Write-Verbose "Received command to create Remote Hosts Group"
                                $command = "Create-RemoteHostsGroup"
                            }
                            "List-AllApps"{
                                Write-Verbose "Received command to list all apps"
                                $command = "List-AllApps"
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

                        try {
                            $script = $ExecutionContext.InvokeCommand.NewScriptBlock($command)                        
                            $commandOutput = & $script
                        } catch {
                            $commandOutput = $_ | ConvertTo-HashTable
                            $statusCode = 500
                        }
                    }

                    $commandOutput = switch ($Format) {
                        BINARY  {  }
                        TEXT    { $commandOutput | Out-String ; break } 
                        JSON    { $commandOutput | ConvertTo-JSON -Compress; break }
                        XML     { $commandOutput | ConvertTo-XML -As String; break }
                        CLIXML  { [System.Management.Automation.PSSerializer]::Serialize($commandOutput) ; break }
                        default { "Invalid output format selected, valid choices are TEXT, JSON, XML, and CLIXML"; $statusCode = 501; break }
                    }
                }

                #Write-Verbose "Response:"
                if (!$commandOutput) {
                    $commandOutput = [string]::Empty
                }
                #Write-Verbose $commandOutput

                $response = $context.Response
                $response.StatusCode = $statusCode
                $output = $response.OutputStream
                if ($Format -ne "BINARY") {
                    $buffer = [System.Text.Encoding]::UTF8.GetBytes($commandOutput)
                    $response.ContentLength64 = $buffer.Length
                    $output.Write($buffer, 0, ($buffer.Length))
                } else {
                    Write-Warning $checkExistingPath
                    try {
                        if(Test-Path $checkExistingPath) {
                            $contentType = Get-MimeType($checkExistingPath);
                            $response.ContentType = $contentType;
                            $commandOutput = New-Object System.IO.BinaryReader([System.IO.File]::Open($checkExistingPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite))
                            $response.ContentLength64 = $commandOutput.BaseStream.Length;
                            $buffer = $commandOutput.ReadBytes($commandOutput.BaseStream.Length)
                            $output.Write($buffer, 0, ($buffer.Length))
                        } else {
                            $commandOutput = "SYNTAX: command=<string> format=[JSON|TEXT|XML|NONE|CLIXML]"
                            if($request.Url.LocalPath -eq "/") {
                                $response.RedirectLocation = "/$daasFolderUrl/index.html"
                            }
                        }
                    } catch {
                        $commandOutput = "SYNTAX: command=<string> format=[JSON|TEXT|XML|NONE|CLIXML]"
                        if($request.Url.LocalPath -eq "/") {
                            $response.StatusCode = 301
                            $response.RedirectLocation = ($request.Url.AbsoluteUri + "$daasFolderUrl/index.html")
                            Write-Error ($request.Url.AbsoluteUri + "index.html")
                        }
                    }

                }
                $output.Flush()
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