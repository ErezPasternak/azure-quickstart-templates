param(
    [String]$Username = "new.user",
    [String]$Password = "123!#abcd",
    [String]$Email = "generic.user@ericom.com",
    [String]$BaseADGroupRDP = "DaaS-RDP"
)

Function FindAndCreateUserInGroup {
	param(
		[String]$Username,
		[String]$Password,
		[String]$Email,
        [String]$BaseADGroupRDP
	)
    
    $response = $null

    $securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force	
    $domainName = (Get-ADDomainController).Domain
    $hasError = $false;
    try {
	    New-ADUser -PasswordNeverExpires $true -SamAccountName $Username -Name "$Username" -Enabled $true -Verbose -EmailAddress $Email -AccountPassword $securePassword -UserPrincipalName ("$Username" + "@" + "$domainName") -ErrorAction Continue
        Add-ADGroupMember -Identity (Get-ADGroup $BaseADGroupRDP) -Members $Username
    } catch  {
        $hasError = $true;
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
    }
    if ($hasError -eq $false) {
        # OK
        $response = @{
            success = "true"
            status = "OK"
            message = "Your account has been created."
        }
    } else {
        try {
            Remove-ADUser $Username -Confirm:$false -ErrorAction SilentlyContinue 
        } catch { }
        # problems
        $response = @{
            status = "ERROR"
            message = "$ErrorMessage"
        }
    }

    return $response
}


return FindAndCreateUserInGroup -Username $Username -Password $Password -Email $Email -BaseADGroupRDP $BaseADGroupRDP