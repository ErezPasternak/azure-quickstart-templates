# Update Mail account password in Active Directory

$Admin ="admin@test.local"
$AdminPassword = "admin"
$User = "admin"


$AdminsecurePassword = ConvertTo-SecureString -String $AdminPassword -AsPlainText -Force;
$AdminCredentials = New-Object System.Management.Automation.PSCredential ($Admin, $AdminsecurePassword);
Set-ADUser -Identity $User -HomePage "IOEQTK4hTMH0GvIpD4Eh"  -Server "test.local" -Credential $AdminCredentials -ErrorAction SilentlyContinue