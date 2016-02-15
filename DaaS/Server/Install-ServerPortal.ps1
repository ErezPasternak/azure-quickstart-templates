# WARNING: Please run this script with Administrator privileges
param(
    [Parameter()][String]$EC_AdminUser = "ericom@ericom.local",
    [Parameter()][String]$EC_AdminPass = "Ericom123$",
    [Parameter()][String]$ServerPort = "2233",
    [Parameter()][String]$baseADGroupRDP = "DaaS-RDP",
    [Parameter()][String]$remoteHostPattern = "rdsh*",
    [Parameter()][String]$externalFqdn = "localhost"
)

# Remove previous installation
try {
    Invoke-WebRequest "http://localhost:$ServerPort/api?exit"
} catch {  }
try {
    Unregister-ScheduledJob -Name StartPSServer -Force -ErrorAction SilentlyContinue
} catch {  }
try {
    Unregister-ScheduledJob -Name MonitorPSServer -Force -ErrorAction SilentlyContinue
} catch {  }
try {
    if(Test-Path "C:\DaaS-Portal") {
        Remove-Item "C:\DaaS-Portal" -Recurse -Force
    }
} catch {  }

Start-Sleep -Seconds 5

$siteUrl = "https://github.com/ErezPasternak/azure-quickstart-templates/raw/EricomConnect/DaaS/Server/Website.zip"
$serverUrl = "https://github.com/ErezPasternak/azure-quickstart-templates/raw/EricomConnect/DaaS/Server/eHTTPListener.zip"
$bootstrapUrl = "https://github.com/ErezPasternak/azure-quickstart-templates/raw/EricomConnect/DaaS/Server/Bootstrap-DaaS.ps1"

$finalDestination = "C:\DaaS-Portal";
$tempDestination = "C:\portaltmp";
New-Item -Path $tempDestination -ItemType Directory -Force -ErrorAction SilentlyContinue
New-Item -Path $finalDestination -ItemType Directory -Force -ErrorAction SilentlyContinue

# Step 1: Download website
$siteResource = "website.zip"
$siteSource = $siteUrl
$siteDestination = Join-Path $tempDestination -ChildPath $siteResource
Invoke-WebRequest $siteSource -OutFile $siteDestination
Unblock-File $siteDestination

# Step 2: Download webserver
$serverResource = "webserver.zip"
$serverSource = $serverUrl
$serverDestination = Join-Path $tempDestination -ChildPath $serverResource
Invoke-WebRequest $serverSource -OutFile $serverDestination
Unblock-File $serverDestination

Start-Sleep -Seconds 5

# download bootstrap
$bootstrapFile = "Bootstrap.ps1"
$bootstrapSource = $bootstrapUrl
$bootstrapDestination = Join-Path $tempDestination -ChildPath $bootstrapFile
Invoke-WebRequest $bootstrapSource -OutFile $bootstrapDestination
Unblock-File $bootstrapDestination


# Step 3: unpack resources
$shellSite = new-object -com shell.application
$zipSite = $shellSite.NameSpace($siteDestination)
$siteTempDestination = Join-Path $tempDestination -ChildPath "Website"
New-Item $siteTempDestination -ItemType Directory -Force
foreach($item in $zipSite.items())
{
    $shellSite.Namespace($siteTempDestination).copyhere($item)
}
Start-Sleep -Seconds 5
Copy-Item $siteTempDestination -Destination $finalDestination -Force -Recurse

$shellServer = new-object -com shell.application
$zipServer = $shellServer.NameSpace($serverDestination)
$serverTempDestination = Join-Path $tempDestination -ChildPath "Webserver"
New-Item $serverTempDestination -ItemType Directory -Force
foreach($item in $zipServer.items())
{
    $shellServer.Namespace($serverTempDestination).copyhere($item)
}
Start-Sleep -Seconds 5
Copy-Item $serverTempDestination -Destination $finalDestination -Force -Recurse


Copy-Item $bootstrapDestination -Destination $finalDestination -Force

# Clean up: delete Temporary Files
Remove-Item $tempDestination -Force -Recurse


# Install PowerShell Modules
$powershellModuleFolder = "$env:ProgramFiles\WindowsPowerShell\Modules"
$serverModuleFolder = Join-Path $powershellModuleFolder -ChildPath "eHTTPListener"
New-Item $serverModuleFolder -ItemType Directory -Force
$modules = (Join-Path $finalDestination -ChildPath "Webserver") + "\eHTTPListener.*"  
Move-Item $modules -Destination $serverModuleFolder -Force

# Running Bootstrap
$boostrapRun = Join-Path $finalDestination -ChildPath $bootstrapFile
cd $finalDestination
$adminUsername = $EC_AdminUser.Split("@")[0];
Invoke-Expression ".\Bootstrap.ps1 -adminUsername `"$adminUsername`" -adminPassword `"$EC_AdminPass`" -baseADGroupRDP `"$baseADGroupRDP`" -remoteHostPattern `"$remoteHostPattern`""

# Register Server
$WebsitePath = Join-Path $finalDestination -ChildPath "Website"
$ServerPath = Join-Path $finalDestination -ChildPath "Webserver"
cd (Join-Path $finalDestination -ChildPath "Webserver")
$registerServer = ".\Task-Registration.ps1 -EC_AdminUser `"$EC_AdminUser`" -EC_AdminPass `"$EC_AdminPass`" -WebsitePath `"$WebsitePath`" -ServerPath `"$ServerPath`" -ServerPort `"$ServerPort`" -BaseADGroupRDP `"$baseADGroupRDP`" -externalFqdn `"$externalFqdn`""
Invoke-Expression $registerServer

# Open in Browser
$url = "http://localhost:$ServerPort/";
Start-Process -FilePath $url