# Botstrap | Please DO NOT MODIFY this file.
# Being under development, please copy this file and use your own copy.

# However, you may change the values from configuration area.
# The admin credentials are required (Active Directory Admin account)
# The configuration block is being used as provisioning data source for both AD and Connect 

#### START OF CONFIGURATION AREA
param(
    [Parameter(Mandatory)][String]$adminUsername = "admin@test.local",
    [Parameter(Mandatory)][String]$adminPassword = "admin",
    [Parameter(Mandatory)][String]$baseADGroupRDP = "DaaS-RDP",
    [Parameter(Mandatory)][String]$remoteHostPattern = "rdsh*"
)

Write-Host "AdminUsername: $adminUsername" -ForegroundColor Green
Write-Host "AdminPassword: $adminPassword" -ForegroundColor Green
Write-Host "BaseRDPGroup: $baseADGroupRDP" -ForegroundColor Green
Write-Host "RemoteHostPattern: $remoteHostPattern" -ForegroundColor Green

Install-windowsfeature -name AD-Domain-Services -IncludeManagementTools
Import-Module ActiveDirectory

$configuration = @{
    ActiveDirectory = @{
        Users = @{
            User1 = @{
                Name = "TestUser0010"
                Password = "P@55w0rd"
            }
            User2 = @{
                Name = "TestUser0011"
                Password = "P@55w0rd"
            }
            User3 = @{
                Name = "TestUser0012"
                Password = "P@55w0rd"
            }
            User4 = @{
                Name = "TestUser0013"
                Password = "P@55w0rd"
            }
        }
        Groups = @{
            TaskWorkers = { "TestUser0010" }
            KnowledgeWorkers = { "TestUser0011" }
            MobileWorkers = { "TestUser0012" }
            CustomApps = { "TestUser0013" }
        }
    }
    RemoteHostsGroups = @{
        "2012Desktop" = "rdshD-*"
        "2008Desktop" = "rdshD8-*"
        "2012App" = "rdshA-*"
        "Linux" = "lnx-*"
    }
    ResourceGroups = @{
        SimpleGroup = @{
            Apps = { "Calculator", "Notepad" }
            RemoteHostGroup = "2012server"
            AdUser = "TestUser0010"
        }
        TaskWorkers = @{
            Apps = { "Calculator", "Notepad" }
            RemoteHostGroup = "2012App"
            AdGroup = "TaskWorkers"
        }
        TaskWorkersDesktop = @{
            Apps = { "Desktop" }
            RemoteHostGroup = "2012Desktop"
            AdGroup = "TaskWorkers"
        }
        KnowledgeWorkers = @{
            Apps = { "Calculator", "Notepad", "WordPad" }
            RemoteHostGroup = "2012App"
            AdGroup = "KnowledgeWorkers"
        }
        KnowledgeWorkersDesktop = @{
            Apps = { "Desktop" }
            RemoteHostGroup = "2012Desktop"
            AdGroup = "KnowledgeWorkers"
        }
        MobileWorkers = @{
            Apps = { "Calculator", "Notepad", "WordPad", "Paint", "Command Prompt" }
            RemoteHostGroup = "2012App"
            AdGroup = "MobileWorkers"
        }
        MobileWorkersDesktop = @{
            Apps = { "Desktop" }
            RemoteHostGroup = "2012Desktop"
            AdGroup = "MobileWorkers"
        }
        Office = @{
            Apps = { "Calculator", "WordPad" }
            RemoteHostGroup = "2012App"
            AdGroup = "CustomApps"
        }
        Internet = @{
            Apps = { "Internet Explorer", "Notepad", "WordPad" }
            RemoteHostGroup = "2012App"
            AdGroup = "CustomApps"
        }
        Multimedia = @{
            Apps = { "Internet Explorer", "Notepad", "WordPad", "Paint", "Command Prompt" }
            RemoteHostGroup = "2012App"
            AdGroup = "CustomApps"
        }
    }

}
#### END OF CONFIGURATION AREA

Function Run-Configuration {
    param(
        [Parameter(Mandatory)][String]$adminUsername,
        [Parameter(Mandatory)][String]$adminPassword,
        [Parameter(Mandatory)][String]$baseADGroupRDP,
        [Parameter(Mandatory)][String]$remoteHostPattern
    )

    # Create our Base RDP Group
    New-ADGroup -Name "$baseADGroupRDP" -SamAccountName $baseADGroupRDP -GroupCategory Security -GroupScope Universal -DisplayName "$baseADGroupRDP"
    # Add Base RDP Group to local "Remote Desktop Users" for each Remote Session Host
    Get-ADComputer -Filter "SamAccountName -like '$remoteHostPattern'" | Foreach-Object { $ComputerName = $_.Name; Invoke-Command { param([String]$RDPGroup) net localgroup "Remote Desktop Users" "$RDPGroup" /ADD } -computername $ComputerName -ArgumentList "$baseADGroupRDP"  }

    if ($configuration -ne $null -and $configuration.Count -gt 0){
        # Active Directory
        if ($configuration.Contains("ActiveDirectory")) {
            if($configuration.ActiveDirectory.Count -gt 0) {
                #users
                if($configuration.ActiveDirectory.Contains("Users")) {
                    foreach($key in $configuration.ActiveDirectory.Users.Keys) { 
                        $userName = $configuration.ActiveDirectory.Users[$key].Name
                        $password = $configuration.ActiveDirectory.Users[$key].Password
                        $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force	

                        New-ADUser -PasswordNeverExpires $true -SamAccountName $userName -Name "$userName" -Enabled $true -Verbose -AccountPassword $securePassword
                        Add-ADGroupMember -Identity (Get-ADGroup $baseADGroupRDP) -Members $userName
                    }                   
                }
                #groups
                if($configuration.ActiveDirectory.Contains("Groups")) {
                   foreach($key in $configuration.ActiveDirectory.Groups.Keys) {
                        New-ADGroup -Name "$key" -SamAccountName $key -GroupCategory Security -GroupScope Universal -DisplayName "$key"
                        $users = $configuration.ActiveDirectory.Groups[$key]
                        if ($users.Count -gt 0) {
                            foreach( $item in $configuration.ActiveDirectory.Groups[$key]) {
                                $adGroupList = $item.ToString().Replace('"',"").Split(",")
                                foreach($adGroup in $adGroupList) {
                                    Add-ADGroupMember -Identity (Get-ADGroup "$key") -Members ($adGroup.Trim())
                                }
                            }
                        }
                   }
                }
            }
        }
        # Remote Hosts Group
        if ($configuration.Contains("RemoteHostsGroups") -and $configuration.RemoteHostsGroups.Count -gt 0) {
            # foreach
            foreach($key in $configuration.RemoteHostsGroups.Keys) {
                $groupName = $key
                $pattern = $configuration.RemoteHostsGroups[$key]
                Create-RemoteHostsGroup -adminUser $adminUsername -adminPassword $adminPassword -groupName $groupName -pattern $pattern
            }
        }
        # Resource Groups
        if ($configuration.Contains("ResourceGroups")) {
           foreach($key in $configuration.ResourceGroups.Keys) {
                # create resource group
                $groupName = $key;
                Create-ResourceGroup -adminUser $adminUsername -adminPassword $adminPassword -groupName $groupName
                $apps = $configuration.ResourceGroups[$key].Apps
                $applicationList = $apps.ToString().Replace('"',"").Split(",")
                    foreach($app in $applicationList) {
                        Create-ResourceDefinitionBinding -adminUser $adminUsername -adminPassword $adminPassword -resourceGroup $groupName -applicationName ($app.Trim())
                    }
                $hosts = $configuration.ResourceGroups[$key].RemoteHostGroup
                    Create-SystemBinding -adminUser $adminUsername -adminPassword $adminPassword -resourceGroup $groupName -remoteHostGroup $hosts

                if ($configuration.ResourceGroups[$key].ContainsKey("AdUser")){
                    $adUser = $configuration.ResourceGroups[$key].AdUser
                    Create-ADUserBinding -adminUser $adminUsername -adminPassword $adminPassword -resourceGroup $groupName -adUser $adUser
                }
                else {
                    $adGroup = $configuration.ResourceGroups[$key].AdGroup
                    Create-ADGroupBinding -adminUser $adminUsername -adminPassword $adminPassword -resourceGroup $groupName -adGroup $adGroup

                }
              
           }
                
        }
    }
}

Function Create-RemoteHostsGroup {
    param(
        [Parameter()][string]$adminUser,
        [Parameter()][string]$adminPassword,
        [Parameter()][string]$groupName,
        [Parameter()][string]$pattern
    )

    $groupName = $groupName
    $adminApi = Start-EricomConnection
    $adminSessionId = $adminApi.CreateAdminsession($adminUser, $adminPassword,"rooturl","en-us");
    [Ericom.MegaConnect.Runtime.XapApi.RemoteHostMembershipComputation]$rhmc = 0;
    $rGroup = $adminApi.CreateRemoteHostGroup($adminSessionId.AdminSessionId, $groupName, $rhmc);
    [System.Collections.Generic.List[String]]$remoteHostsList = New-Object System.Collections.Generic.List[String];

    [Ericom.MegaConnect.Runtime.XapApi.RemoteHostSearchConstraints]$rhsc = New-Object Ericom.MegaConnect.Runtime.XapApi.RemoteHostSearchConstraints;
    $rhsc.HostnamePattern = $pattern; #TODO: Update HERE!
    $rhl = $adminApi.GetRemoteHostList($adminSessionId.AdminSessionId, $rhsc)
    foreach($h in $rhl)
    {
	    $remoteHostsList.Add($h.RemoteHostId)
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

Function Create-ADGroupBinding
{
    param(
        [Parameter()][string]$adminUser,
        [Parameter()][string]$adminPassword,
        [Parameter()][String]$resourceGroup,
        [Parameter()][string]$adGroup
    )


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
        $adName = (Get-ADDomain).Forest
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
        $adName = (Get-ADDomain).Forest
        $rGroup.AddBindingGroup("$adUser", $adGroupBindingType, $adName, ("id_" + $adUser));
        $adminApi.UpdateResourceGroup($adminSessionId, $rGroup);
    }
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

        $AppList = $adminApi.ResourceDefinitionSearch($adminSessionId,$null,$null)
        $foundApp = $null
        foreach ($app in $AppList)
        {
            if($app.DisplayName -eq $applicationName) {
                $foundApp = $app.ResourceDefinitionId;
            }    
        }
        # try publish it
        if ($foundApp -eq $null) {
            if ($applicationName -eq "Desktop") {
                $foundApp = (Publish-Desktop -adminUser $adminUser -adminPassword $adminPassword -aliasName $aliasName -desktopShortcut $desktopShortcut).id
            } else {
                $foundApp = (Publish-App -adminUser $adminUser -adminPassword $adminPassword -applicationName $applicationName -aliasName $aliasName -desktopShortcut $desktopShortcut).id
            }
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
    
    $response = $null;

    $RemoteHostList = $adminApi.RemoteHostStatusSearch($adminSessionId.AdminSessionId, "Running", "", "100", "100", "0", "", "true", "true", "true")

    function FlattenFilesForDirectory ($browsingFolder, $rremoteAgentId ,$rremoteHostId)
    {
	    foreach ($browsingItem in $browsingFolder.Files.Values)
	    {
            if(($browsingItem.Label -eq $applicationName))
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
        }

	    foreach ($directory in $browsingFolder.SubFolders.Values)
	    {
		    FlattenFilesForDirectory($directory);
	    }
    }


    foreach ($RH in $RemoteHostList)
    {
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
       FlattenFilesForDirectory ($browsingFolder, $RH.RemoteAgentId ,$RH.RemoteHostId)
       if($goon -eq $false)
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


Run-Configuration -adminUsername $adminUsername -adminPassword $adminPassword -baseADGroupRDP $baseADGroupRDP -remoteHostPattern $remoteHostPattern