param(
    $Password,
    $ADServer1PrivateIp,
    $ADServer2PrivateIp,
    $DomainDNSName
)

function BuildCredential {
    param([string] $ComputerName, [string] $Password, [switch] $Local, [string] $DomainDNSName)

    $Pass = ConvertTo-SecureString $Password -AsPlainText -Force
    if($Local) {
        $Cred = New-Object System.Management.Automation.PSCredential -ArgumentList "$ComputerName\administrator", $Pass
    }
    else {
        $Cred = New-Object System.Management.Automation.PSCredential -ArgumentList "administrator@$DomainDNSName", $Pass
    }
    Write-Output $Cred
}

$joinDomain = {
    param([string] $ComputerName, [pscredential] $DomainCred, [string] $DomainDNSName, [string] $DC1Ip, [string] $DC2Ip)

    Get-NetAdapter | Set-DnsClientServerAddress -ServerAddresses $DC1Ip, $DC2Ip
    Add-Computer -DomainName $DomainDNSName -Credential $DomainCred
    Restart-Computer -Force
}

foreach($computer in @("pull1","pull2")) {
    $localCred = BuildCredential -ComputerName $computer -Password $Password -Local
    Invoke-Command -ScriptBlock $joinDomain -ComputerName $computer -ArgumentList $computer, (BuildCredential -ComputerName $computer -Password $Password -DomainDNSName $DomainDNSName), $DomainDNSName, $ADServer1PrivateIp, $ADServer2PrivateIp -Credential $localCred    
}