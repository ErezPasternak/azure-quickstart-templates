$_adminUser = "ericom@daas.local"
$_adminPass = "Ericom123$"
$_lookUpHosts = "broker.daas.local:2233/"

$workingDirectory = "$env:ProgramFiles\Ericom Software\Ericom Connect Configuration Tool"
$configFile = "EricomConnectConfigurationTool.exe"
$connectCli = "ConnectCli.exe"    
$configPath = Join-Path $workingDirectory -ChildPath $configFile
$cliPath = Join-Path $workingDirectory -ChildPath $connectCli

# publish admin page via ESG
$argumentsCli = "EsgConfig /adminUser `"$_adminUser`" /adminPassword `"$_adminPass`" common ExternalWebServer`$UrlServicePointsFilter=`"<UrlServicePointsFilter> <UrlFilter> <UrlPathRegExp>^/DaaS</UrlPathRegExp> <UrlServicePoints>http://$_lookUpHosts</UrlServicePoints></UrlFilter> </UrlServicePointsFilter>`"";
                
$exitCodeCli = (Start-Process -Filepath $cliPath -ArgumentList "$argumentsCli" -Wait -Passthru).ExitCode;
if ($exitCodeCli -eq 0) {
    Write-Verbose "ESG: Admin page has been succesfuly published."
} else {
    Write-Verbose "$cliPath $argumentsCli"
    Write-Verbose ("ESG: Admin page could not be published.. Exit Code: " + $exitCode)
} 