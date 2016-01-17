#for every script that you want to run, make sure that you run the command.
#     Set-ExecutionPolicy Unrestricted -scope Process
#so you can run the scripts files


#connect to the adminApi and get the adminSessionId.
#Run CloudConnect.ps1 that will load the needed dlls
E:\PM\Dev\CloudConnect\Code\CloudConnect\MegaConnectIntegrationTest\ComponentIntegrationTests\bin\x64\Debug\CloudConnect.ps1

#LogIn
$regularUser = New-Object Ericom.CloudConnect.Utilities.SpaceCredentials("regularUser")
$adminApi = [Ericom.MegaConnect.Runtime.XapApi.AdministrationProcessingUnitClassFactory]::GetInstance($regularUser)
$adminSessionId = $adminApi.CreateAdminsession("ccadmin", ".Admin1!","rooturl","en-us")
#print the Guid
"Guid=" + $adminSessionId
#Guid=<CreateAdminSessionResponse AdminSessionId='0fe13849-1be0-4eb5-8560-bec98d90ce86', ErrorId='NoError'>

#get the remote hoste list:
$RemoteHostList = $adminApi.RemoteHostStatusSearch($adminSessionId.AdminSessionId, "Running", "", "100", "100", "0", "", "true", "true", "true")

#print the remote hoste list.
$RemoteHostList


#PowerShell script that provide a list of all apps on a TS
#now this will be for all the TS in the list that we got before.
        
#the function is public Stream GetApplicationsForServer(String requestVersion, string hostId, bool allServers) from resourcedefinitionpage.impl.cs
$AdminWebService = [Ericom.CloudConnect.AdminWebService.AdminUIService]::GetInstance()
foreach ($RH in $RemoteHostList){
    $browsingFolder = $adminApi.SendCustomRequest(	$adminSessionId.AdminSessionId, 
												$RH.RemoteAgentId,
											   [Ericom.MegaConnect.Runtime.XapApi.StandaloneServerRequestType]::HostAgentApplications,
											   "null",
											   "false",
											   "999999999")
   $browsingFolder
   $applications
             foreach ($browsingItem in $browsingFolder.Files.Values)
            {
                $fullPath = Path.Combine($browsingItem.Path, $browsingItem.Name);
				$fullPath
            }

}