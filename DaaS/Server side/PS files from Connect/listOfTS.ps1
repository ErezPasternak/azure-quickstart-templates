#2 PowerShell script that provide a list of TS

#for every script that you want to run, make sure that you run the command.
#     Set-ExecutionPolicy Unrestricted -scope Process
#so you can run the scripts files

#must be the first running line.
param(
    [string]$adminUser       = $(throw "-adminUser is required."),
    [string]$adminPassword   = $(throw "-adminPassword is required."),
    [string]$State           = "Running"
)


#Run CloudConnect.ps1 that will load the needed dlls
E:\PM\Dev\CloudConnect\Code\CloudConnect\MegaConnectIntegrationTest\ComponentIntegrationTests\bin\x64\Debug\CloudConnect.ps1

#LogIn
$regularUser = New-Object Ericom.CloudConnect.Utilities.SpaceCredentials("regularUser")
$adminApi = [Ericom.MegaConnect.Runtime.XapApi.AdministrationProcessingUnitClassFactory]::GetInstance($regularUser)
$adminSessionId = $adminApi.CreateAdminsession($adminUser, $adminPassword,"rooturl","en-us")

#get a list of all remote hosts that are running
$RemoteHostList = $adminApi.RemoteHostStatusSearch($adminSessionId.AdminSessionId, $State, "", "100", "100", "0", "", "true", "true", "true")
$RemoteHostList

