<#
.Synopsis
Update Mail account password in Active Directory

.NOTES   
Name: SaveMailPasswordinAD
Author: Erez Pasternak
Version: 1.0
DateCreated: 2016-05-29

#>

$Admin ="admin@test.local"
$AdminPassword = "admin"
$User = "admin"


$AdminsecurePassword = ConvertTo-SecureString -String $AdminPassword -AsPlainText -Force;
$AdminCredentials = New-Object System.Management.Automation.PSCredential ($Admin, $AdminsecurePassword);
Set-ADUser -Identity $User -HomePage "IOEQTK4hTMH0GvIpD4Eh"  -Server "test.local" -Credential $AdminCredentials -ErrorAction SilentlyContinue