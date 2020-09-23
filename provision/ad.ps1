Import-Module ServerManager
Import-Module ActiveDirectory
New-ADuser -Name "kertest" -SamAccountName kertest -Enabled $true -AccountPassword (ConvertTo-SecureString -AsPlainText "SuperSecure@123!!!" -Force)
New-ADuser -Name "svctest" -SamAccountName svctest -Enabled $true -AccountPassword (ConvertTo-SecureString -AsPlainText "Monkey.123" -Force)
setspn -A sky.net/kertest kertest
setspn -A sky.net/svctest svctest
Add-ADGroupMember -Identity "Administrators" -Members svctest
Add-ADGroupMember -Identity "Users" -Members kertest

Set-ADAccountPassword -Identity administrator -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "Password#" -Force)

New-ADuser -Name "httpclientlinux" -SamAccountName httpclientlinux -Enabled $true -AccountPassword (ConvertTo-SecureString -AsPlainText "Password#" -Force) -ChangePasswordAtLogon $false -PasswordNeverExpires $true -TrustedForDelegation $true
Get-ADUser httpclientlinux | Set-ADAccountControl  -doesnotrequirepreauth $true
ktpass -princ HTTP/clientlinux.mshome.net@MSHOME.NET -pass Password# -mapuser mshome\httpclientlinux -crypto all -ptype KRB5_NT_PRINCIPAL -out httpclientlinux.keytab -kvno 0
setspn -a HTTP/clientlinux httpclientlinux
setspn -a HTTP/clientlinux.mshome.net httpclientlinux

$HVHost01 = "clientlinux.mshome.net"
$HV01Spns = @("HTTP/$HVHost01")
$delegationProperty = "msDS-AllowedToDelegateTo"
$delegateToSpns = $HV01Spns
$HV01Account = Get-ADUser httpclientlinux
$HV01Account | Set-ADObject -Add @{$delegationProperty=$delegateToSpns}
Set-ADAccountControl $HV01Account -TrustedToAuthForDelegation $true

New-ADuser -Name "cifsclientlinux" -SamAccountName cifsclientlinux -Enabled $true -AccountPassword (ConvertTo-SecureString -AsPlainText "Password#" -Force) -ChangePasswordAtLogon $false -PasswordNeverExpires $true -TrustedForDelegation $true
Get-ADUser cifsclientlinux | Set-ADAccountControl  -doesnotrequirepreauth $true
ktpass -princ cifs/clientlinux.mshome.net@MSHOME.NET -pass Password# -mapuser mshome\cifsclientlinux -crypto all -ptype KRB5_NT_PRINCIPAL -out cifsclientlinux.keytab -kvno 0
setspn -a cifs/clientlinux cifsclientlinux
setspn -a cifs/clientlinux.mshome.net cifsclientlinux

$HVHost01 = "clientlinux.mshome.net"
$HV01Spns = @("cifs/$HVHost01")
$delegationProperty = "msDS-AllowedToDelegateTo"
$delegateToSpns = $HV01Spns
$HV01Account = Get-ADUser cifsclientlinux
$HV01Account | Set-ADObject -Add @{$delegationProperty=$delegateToSpns}
Set-ADAccountControl $HV01Account -TrustedToAuthForDelegation $true


$FileName = "C:\vagrant\provision\cifsclientlinux.keytab"
if (Test-Path $FileName) {
  Remove-Item $FileName
}

$FileName = "C:\vagrant\provision\httpclientlinux.keytab"
if (Test-Path $FileName) {
  Remove-Item $FileName
}

cp .\cifsclientlinux.keytab C:\vagrant\provision\
cp .\httpclientlinux.keytab C:\vagrant\provision\

# dns
Add-DnsServerResourceRecordA -Name "clientlinux" -ZoneName "mshome.net" -AllowUpdateAny -IPv4Address "192.168.56.14" -TimeToLive 01:00:00

# primary dns
netsh interface ip set dns "Ethernet 3" static 192.168.56.2 primary

# enable kerberos debug
# Get the value of the Kerberos logging property
Get-ItemProperty HKLM:\System\CurrentControlSet\Control\Lsa\Kerberos\Parameters
# Add the log level key for Kerberos logging
New-ItemProperty HKLM:\System\CurrentControlSet\Control\Lsa\Kerberos\Parameters -Name "LogLevel" -value "1" -PropertyType dword
# Enable Kerberos logging
Set-ItemProperty HKLM:\System\CurrentControlSet\Control\Lsa\Kerberos\Parameters -Name "LogLevel" -value "1"

# Disable Server Manager when logging in to Windows Server
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose

# auto logon
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty $RegPath "AutoAdminLogon" -Value "1" -type String
Set-ItemProperty $RegPath "DefaultUsername" -Value "MSHOME.NET\vagrant" -type String
Set-ItemProperty $RegPath "DefaultPassword" -Value "vagrant" -type String