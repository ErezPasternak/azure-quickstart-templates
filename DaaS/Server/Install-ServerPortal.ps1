# WARNING: Please run this script with Administrator priviledges
$EC_AdminUser = "admin@test.local"
$EC_AdminPass = "admin"
$ServerPort = "2222"

$siteUrl = "https://github.com/ErezPasternak/azure-quickstart-templates/raw/EricomConnect/DaaS/Server/Website.zip"
$serverUrl = "https://github.com/ErezPasternak/azure-quickstart-templates/raw/EricomConnect/DaaS/Server/eHTTPListener.zip"

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

# Step 3: unpack resources
$shellSite = new-object -com shell.application
$zipSite = $shellSite.NameSpace($siteDestination)
$siteTempDestination = Join-Path $tempDestination -ChildPath "Website"
New-Item $siteTempDestination -ItemType Directory -Force
foreach($item in $zipSite.items())
{
    $shellSite.Namespace($siteTempDestination).copyhere($item)
}
Move-Item $siteTempDestination -Destination $finalDestination

$shellServer = new-object -com shell.application
$zipServer = $shellServer.NameSpace($serverDestination)
$serverTempDestination = Join-Path $tempDestination -ChildPath "Webserver"
New-Item $serverTempDestination -ItemType Directory -Force
foreach($item in $zipServer.items())
{
    $shellServer.Namespace($serverTempDestination).copyhere($item)
}
Move-Item $serverTempDestination -Destination $finalDestination

# Clean up: delete Temporary Files
Remove-Item $tempDestination -Force -Recurse


# Install PowerShell Modules
$powershellModuleFolder = "$env:ProgramFiles\WindowsPowerShell\Modules"
$serverModuleFolder = Join-Path $powershellModuleFolder -ChildPath "eHTTPListener"
New-Item $serverModuleFolder -ItemType Directory -Force
Copy-Item ((Join-Path $finalDestination -ChildPath "Webserver") + "eHTTPListener.*") -Destination $serverModuleFolder -Force

$WebsitePath = Join-Path $finalDestination -ChildPath "Website"
$ServerPath = Join-Path $finalDestination -ChildPath "Webserver"
cd (Join-Path $finalDestination -ChildPath "Webserver")
$registerServer = ".\Task-Registration.ps1 -EC_AdminUser `"$EC_AdminUser`" -EC_AdminPass `"$EC_AdminPass`" -WebsitePath `"$WebsitePath`" -ServerPath `"$ServerPath`" -ServerPort `"$ServerPort`" "
Invoke-Expression $registerServer
