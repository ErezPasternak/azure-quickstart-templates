#6.PowerShell script that will give a blaze file for a connection for a user (lunch analysis)

#for every script that you want to run, make sure that you run the command.
#     Set-ExecutionPolicy Unrestricted -scope Process
#so you can run the scripts files



#must be the first running line.
param(
      [string]$adminUser       = $(throw "-adminUser is required.")
    , [string]$adminPassword   = $(throw "-adminPassword is required.")
    , [string]$user            = $(throw "-user is required.")
    , [string]$app             = $(throw "-app is required.")
)

<#
#you need to put your data her.			
$adminPassword = ".Admin1!"
$adminUser     = "ccadmin"
$user          = "user-0000000"
$app           = "paint#1"
#>


#Run CloudConnect.ps1 that will load the needed dlls
E:\PM\Dev\CloudConnect\Code\CloudConnect\MegaConnectIntegrationTest\ComponentIntegrationTests\bin\x64\Debug\CloudConnect.ps1

#LogIn
$regularUser = New-Object Ericom.CloudConnect.Utilities.SpaceCredentials("regularUser")
$adminApi = [Ericom.MegaConnect.Runtime.XapApi.AdministrationProcessingUnitClassFactory]::GetInstance($regularUser)
$adminSessionId = $adminApi.CreateAdminsession($adminUser, $adminPassword,"rooturl","en-us")


$SessionCreationInfo = New-Object Ericom.MegaConnect.Runtime.XapApi.SessionCreationInfo
$SessionCreationInfo.ClientIp = "127.0.0.1"
$SessionCreationInfo.PortalInfo = New-Object Ericom.MegaConnect.Runtime.XapApi.PortalClientInfo
$SessionCreationInfo.PortalInfo.PortalType = "Testing"


#get the list of connection per user.
$constraints             = New-Object Ericom.MegaConnect.Runtime.XapApi.UserListSearchConstraints
$constraints.RowLimit    = "1000"
$constraints.UserPattern = "0"
try
{
    $userList = $adminApi.GetUserList($adminSessionId.AdminSessionId, $constraints)
} 
catch [Exception] 
{
    "GetUserList faild:"
    $_.Exception.Message
    $_.Exception.LogEntry.DescriptorName
    $_.Exception.LogEntry.M1
    $_.Exception.LogEntry.M2
    $_.Exception.LogEntry.M3
    ""
    ""
}



#get the user id
#$endUserId 
foreach ($UL in $userList){
    if($UL.Name -eq $user)
    {
        $endUserId = $UL.EndUserId
    }
}

#get the connections for the user.
$cfg                        = $adminApi.GetEndUserConfig($adminSessionId.AdminSessionId, $endUserId)
$ActiveDirectoryInformation = $adminApi.GetAuthenticationInfo($adminSessionId.AdminSessionId, $cfg.UserPrincipalName, "true")


$SessionCreationInfo                       = New-Object Ericom.MegaConnect.Runtime.XapApi.SessionCreationInfo
$SessionCreationInfo.ClientIp              = "127.0.0.1"
$SessionCreationInfo.PortalInfo            = New-Object Ericom.MegaConnect.Runtime.XapApi.PortalClientInfo
$SessionCreationInfo.PortalInfo.PortalType = "Testing"

$ResourceTree = $adminApi.EndUserResourceTree($adminSessionId.AdminSessionId, $ActiveDirectoryInformation, $SessionCreationInfo)

foreach ($RT in $ResourceTree)
{
    foreach ($item in $RT.Items)
    {
        if($item.ResourceDefinitionId -eq $app)
        {
             try 
            {
               $establishConnectionInfo = $adminApi.LaunchAnalysis( $adminSessionId.AdminSessionId, $user, $SessionCreationInfo, $app, $item.ResourceGroupId, $item.BindingGroupId)
            } 
            catch [Exception] 
            {
                "try to do launce analysis faild: "
                $_.Exception.Message
                $_.Exception.LogEntry.DescriptorName
                $_.Exception.LogEntry.M1
                $_.Exception.LogEntry.M2
                $_.Exception.LogEntry.M3
                ""
                ""
            }
            "LaunchAnalysis: connection: " + $item.ResourceDefinitionId
            "-----------------------------------------------------------"
            $establishConnectionInfo.ConnectionString					
            ""
            ""
            #$establishConnectionInfo
        }
    }
}
