﻿# Sever Monitor
param(
    [Parameter()][String]$EC_AdminUser = "ericom@ericom.local",
    [Parameter()][String]$EC_AdminPass = "Ericom123$",
    [Parameter()][String]$WebsitePath = "C:\DaaS-Portal\Website",
    [Parameter()][String]$ServerPath = "C:\DaaS-Portal\Webserver",
    [Parameter()][String]$ServerPort = "2233",
    [Parameter()][String]$baseADGroupRDP = "DaaS-RDP",
    [Parameter()][String]$externalFqdn = "localhost"
)

$startServer = "Start-Server.ps1"

$pathStartServer = Join-Path $ServerPath -ChildPath $startServer;

# Check if Server is Running
$isRunning = $false;
try {
    $HTTP_Request = [System.Net.WebRequest]::Create("http://localhost:$ServerPort/DaaS/index.html")
    # We then get a response from the site.
    $HTTP_Response = $HTTP_Request.GetResponse()
    # We then get the HTTP code as an integer.
    $HTTP_Status = [int]$HTTP_Response.StatusCode
    if ($HTTP_Response.ContentType -eq "text/html") { 
        Write-Host "Site is OK!"
        $isRunning = $true;
    }
    else {
        Write-Host "The Site may be down, please check!"
        $isRunning = $false;
    }
    # Finally, we clean up the http request by closing it.
    $HTTP_Response.Close()
} catch {
    Write-Host "Server is Unreachable..."
    $isRunning = $false;
}

$powershellBinary = "C:\Windows\System32\WindowsPowershell\v1.0\powershell.exe"
$argumentsList = "-executionPolicy bypass -noexit -file `"$pathStartServer`" -EC_AdminUser `"$EC_AdminUser`" -EC_AdminPass `"$EC_AdminPass`" -WebsitePath `"$WebsitePath`" -ServerPort `"$ServerPort`" -BaseADGroupRDP `"$baseADGroupRDP`" -externalFqdn `"$externalFqdn`" "
# If not, then start server manually
if ($isRunning -eq $false) {
    Start-Process -Filepath $powershellBinary -ArgumentList $argumentsList -Passthru
}
exit;