#3 PowerShell script that provide a list of all apps on a TS


#for every script that you want to run, make sure that you run the command.
#     Set-ExecutionPolicy Unrestricted -scope Process
#so you can run the scripts files

#must be the first running line.
param(
      [string]$adminUser       = $(throw "-adminUser is required.")
    , [string]$adminPassword   = $(throw "-adminPassword is required.")
    , [string]$outFile         = "NoOutFile"
)

<#
$adminUser    = "ccadmin"
$adminPassword = ".Admin1!"
$outFile      = E:\PM\Dev\CloudConnect\Code\CloudConnect\PsScripts\out.txt
#>

function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

$SaveToFile
$NoOutFileStr = "NoOutFile"
if($outFile -eq $NoOutFileStr)
{
    $script:SaveToFile = $false
    $script:outFilePath
}
else
{
    $script:SaveToFile = $true
    $script:outFilePath = Join-Path (Get-ScriptDirectory) $outFile
    #clear the file.
    #out-file -filepath $outFilePath
}

#$outFilePath = "E:\PM\Dev\CloudConnect\Code\CloudConnect\PsScripts\out.txt"

#Run CloudConnect.ps1 that will load the needed dlls
E:\PM\Dev\CloudConnect\Code\CloudConnect\MegaConnectIntegrationTest\ComponentIntegrationTests\bin\x64\Debug\CloudConnect.ps1

#LogIn
$regularUser = New-Object Ericom.CloudConnect.Utilities.SpaceCredentials("regularUser")
$adminApi = [Ericom.MegaConnect.Runtime.XapApi.AdministrationProcessingUnitClassFactory]::GetInstance($regularUser)
$adminSessionId = $adminApi.CreateAdminsession($adminUser, $adminPassword,"rooturl","en-us")

$RemoteHostList = $adminApi.RemoteHostStatusSearch($adminSessionId.AdminSessionId, "Running", "", "100", "100", "0", "", "true", "true", "true")
[Array]$OutArray = @()

#FlattenFilesForDirectory(string remoteHostId, List<HostApplication> applications, string remoteAgentId, BrowsingFolder browsingFolder)
function FlattenFilesForDirectory ($browsingFolder)
{
	foreach ($browsingItem in $browsingFolder.Files.Values)
	{

        $script:OutArray =  [Array]$OutArray + $browsingItem
        
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
if($script:SaveToFile -eq $true)
{
    $script:OutArray | Export-Csv -Path $outFilePath 
}
else
{
    $script:OutArray
}
