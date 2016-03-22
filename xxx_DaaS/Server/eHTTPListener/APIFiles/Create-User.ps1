param(
    [bool]$Show = $true,
    [String]$Username = "zzz",
    [String]$Password = "1q2w3e!Q@W#E",
    [String]$Email = "generic.user@ericom.com",
    [String]$BaseADGroupRDP = "DaaS-RDP"
)

Function FindAndCreateUserInGroup {
	param(
        [bool]$Show,
		[String]$Username,
		[String]$Password,
		[String]$Email,
        [String]$BaseADGroupRDP
	)

    $nl = [Environment]::NewLine

    if ($Show -eq $true) {
        $res = [System.Windows.Forms.MessageBox]::Show("User : " + $Username + $nl + "Email: " + $Email, "Params" , 4)
        if ($res -ne "Yes") {
            return $null }  }

    $response = $null

    $securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force	
#    $domainName = (Get-ADDomainController).Domain
    $domainName = "test.local"
    $hasError = $false;
    try {
	    New-ADUser -Server $domainName -PasswordNeverExpires $true -SamAccountName $Username -Name $Username -Enabled $true -Verbose -EmailAddress $Email -AccountPassword $securePassword -UserPrincipalName ("$Username" + "@" + "$domainName") -ErrorAction Continue
        Add-ADGroupMember -Server $domainName -Identity (Get-ADGroup -Server $domainName $BaseADGroupRDP) -Members $Username
    } catch  {
        $hasError = $true;
        $HResult = $_.Exception.HResult
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
    }
    if ($hasError -eq $false) {
        # OK
        $response = @{
            success = $true
            status = "OK"
            message = "Your account has been created."
            data = @{
                test1 = $true
                test2 = "false"
            }
        }
    } else {
        if ($ErrorMessage -ne "The specified account already exists") {
            # delete account only for any error except when account already exists
            try {
                Remove-ADUser $Username -Server $domainName -Confirm:$false -ErrorAction SilentlyContinue 
            } catch { }
        }
        # problems
        $response = @{
            success = $false
            status = "ERROR"
            message = "$ErrorMessage"
            data = @{
                test3 = $true
                test4 = "false"
            }
        }
    }

    return $response
}


return FindAndCreateUserInGroup -Show $Show -Username $Username -Password $Password -Email $Email -BaseADGroupRDP $BaseADGroupRDP