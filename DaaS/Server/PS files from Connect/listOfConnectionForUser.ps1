#5. PowerShell script that will send a list of connection for a user (lunch analysis)
#_AdminPu.EndUserResourceTree(adminSessionId, res.DATA.ActiveDirectoryInformation, info)


#for every script that you want to run, make sure that you run the command.
#     Set-ExecutionPolicy Unrestricted -scope Process
#so you can run the scripts files

#must be the first running line.
param(
    [string]$adminUser       = $(throw "-adminUser is required."),
    [string]$adminPassword   = $(throw "-adminPassword is required."),
    [string]$user            = $(throw "-user is required.")
)

#Run CloudConnect.ps1 that will load the needed dlls
E:\PM\Dev\CloudConnect\Code\CloudConnect\MegaConnectIntegrationTest\ComponentIntegrationTests\bin\x64\Debug\CloudConnect.ps1

#LogIn
$regularUser = New-Object Ericom.CloudConnect.Utilities.SpaceCredentials("regularUser")
$adminApi = [Ericom.MegaConnect.Runtime.XapApi.AdministrationProcessingUnitClassFactory]::GetInstance($regularUser)
$adminSessionId = $adminApi.CreateAdminsession($adminUser, $adminPassword,"rooturl","en-us")

#plese set the username.
#$username = "user-0000000"
$username = $user


$constraints = New-Object Ericom.MegaConnect.Runtime.XapApi.UserListSearchConstraints
$constraints.RowLimit = "1000"
$constraints.UserPattern = "0"

$userList = $adminApi.GetUserList($adminSessionId.AdminSessionId, $constraints)

$endUserId 
foreach ($UL in $userList){
    if($UL.Name -eq $user)
    {
        $endUserId = $UL.EndUserId
    }
}

$cfg                        = $adminApi.GetEndUserConfig($adminSessionId.AdminSessionId, $endUserId)
try
{
    $ActiveDirectoryInformation = $adminApi.GetAuthenticationInfo($adminSessionId.AdminSessionId, $cfg.UserPrincipalName, $true)
} 
catch [Exception] 
{
    $_.Exception.Message
    $_.Exception.LogEntry.DescriptorName
    $_.Exception.LogEntry.M1
    $_.Exception.LogEntry.M2
    $_.Exception.LogEntry.M3
}


$SessionCreationInfo                       = New-Object Ericom.MegaConnect.Runtime.XapApi.SessionCreationInfo
$SessionCreationInfo.ClientIp              = "127.0.0.1"
$SessionCreationInfo.PortalInfo            = New-Object Ericom.MegaConnect.Runtime.XapApi.PortalClientInfo
$SessionCreationInfo.PortalInfo.PortalType = "Testing"

$ResourceTree = $adminApi.EndUserResourceTree($adminSessionId.AdminSessionId, $ActiveDirectoryInformation, $SessionCreationInfo)

foreach ($RT in $ResourceTree){
    $RT.FolderName + ":"
    "---------------------"
    foreach ($item in $RT.Items){
        $item
        }
     ""
}