param(
    [string]$adminUser       = "admin@test.local",
    [string]$adminPassword   = "admin",
    [string]$groupList       = ""
)

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
