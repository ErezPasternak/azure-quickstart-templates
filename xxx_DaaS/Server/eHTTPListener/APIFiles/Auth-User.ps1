param(
    [String]$Username = "new.user",
    [String]$Password = "123!#abcd"
)

Function Test-ADCredentials {
    param(
        $Username = 'user1',
        $Password = 'P@ssw0rd'
    )
    $Domain = (Get-ADDomainController).Domain

    Add-Type -AssemblyName System.DirectoryServices.AccountManagement
    $ct = [System.DirectoryServices.AccountManagement.ContextType]::Domain
    $pc = New-Object System.DirectoryServices.AccountManagement.PrincipalContext $ct, $Domain
    $isValid = ($pc.ValidateCredentials($Username, $Password) | Out-String).ToString().Trim() -eq "True"
    $response = $null
    if ($isValid -eq $true) {
        $email = ((Get-AdUser $Username -Properties EmailAddress | Select EmailAddress).EmailAddress | Out-String).Trim()
        
        $homepage = ""
        try {
            $homepage = ((Get-ADUser $Username  -Properties HomePage | Select HomePage).HomePage | Out-String).Trim()
        } catch { $homepage = "" }

        $response = @{
            status = "OK"
            success = "true"
            email = "$email"
            message = "Authentication OK"
        }
        if ($homepage.Length -gt 0) {
            $response.Add("homepage", $homepage)
        }
    } else {
        $response = @{
            status = "ERROR"
            message = "Authentication failed!"
        }
    }
    return $response
}

return (Test-ADCredentials -Username $Username -Password $Password)