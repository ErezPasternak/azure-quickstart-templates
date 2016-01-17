#4 PowerShell script that publish an App from a TS


#for every script that you want to run, make sure that you run the command.
#     Set-ExecutionPolicy Unrestricted -scope Process
#so you can run the scripts files

#must be the first running line.
param(
    [string]$adminUser       = $(throw "-username is required."),
    [string]$adminPassword   = $(throw "-adminPassword is required."),
    [string]$applicationName = "paint"
)

#LogIn
#Run CloudConnect.ps1 that will load the needed dlls
E:\PM\Dev\CloudConnect\Code\CloudConnect\MegaConnectIntegrationTest\ComponentIntegrationTests\bin\x64\Debug\CloudConnect.ps1
#CloudConnect.ps1

#LogIn
$regularUser = New-Object Ericom.CloudConnect.Utilities.SpaceCredentials("regularUser")
$adminApi = [Ericom.MegaConnect.Runtime.XapApi.AdministrationProcessingUnitClassFactory]::GetInstance($regularUser)
$adminSessionId = $adminApi.CreateAdminsession($adminUser, $adminPassword,"rooturl","en-us")


# this args will add "Araxis Merge"... set them according to the app you want to publish.
#$applicationName  = "Araxis Merge"
#$applicationName  = "Paint"



$RemoteHostList = $adminApi.RemoteHostStatusSearch($adminSessionId.AdminSessionId, "Running", "", "100", "100", "0", "", "true", "true", "true")

function FlattenFilesForDirectory ($browsingFolder, $rremoteAgentId ,$rremoteHostId)
{
	foreach ($browsingItem in $browsingFolder.Files.Values)
	{
        if(($browsingItem.Label -eq $applicationName))
        {
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

            $val4 = $resourceDefinition.DisplayProperties.GetLocalPropertyValue("IconString")
            $val4.LocalValue = $browsingItem.ApplicationString
            $val4.ComputeBy = "Literal"

            $val5 = $resourceDefinition.DisplayProperties.GetLocalPropertyValue("DisplayName")
            $val5.LocalValue = $applicationName
            $val5.ComputeBy = "Literal"

            try 
            {
                $adminApi.AddResourceDefinition($adminSessionId.AdminSessionId, $resourceDefinition, "true")
            } 
            catch [Exception] 
            {
                $_.Exception.Message
                $_.Exception.LogEntry.DescriptorName
                $_.Exception.LogEntry.M1
                $_.Exception.LogEntry.M2
                $_.Exception.LogEntry.M3
            }
            exit
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



