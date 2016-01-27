# Sever Monitor
param(
    [Parameter()][String]$EC_AdminUser = "ericom@ericom.local",
    [Parameter()][String]$EC_AdminPass = "Ericom123$",
    [Parameter()][String]$WebsitePath = "C:\Website",
    [Parameter()][String]$ServerPath = "C:\Server"
)

$startServer = "Start-Server.ps1"

$pathStartServer = Join-Path $ServerPath -ChildPath $startServer;

# Check if Server is Running
$isRunning = $false;
try {
    $HTTP_Request = [System.Net.WebRequest]::Create('http://localhost:2222/index.html')
    # We then get a response from the site.
    $HTTP_Response = $HTTP_Request.GetResponse()
    # We then get the HTTP code as an integer.
    $HTTP_Status = [int]$HTTP_Response.StatusCode
    if ($HTTP_Status -eq 200) { 
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
$argumentsList = "-executionPolicy bypass -noexit -file `"$pathStartServer`" -EC_AdminUser `"$EC_AdminUser`" -EC_AdminPass `"$EC_AdminPass`" -WebsitePath `"$WebsitePath`""
# If not, then start server manually
if ($isRunning -eq $false) {
    Start-Process -Filepath $powershellBinary -ArgumentList $argumentsList -Passthru
}
exit;