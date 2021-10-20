$CNAME = [System.Net.Dns]::GetHostName()
$IPx = [System.Net.Dns]::GetHostAddresses($CNAME) |
       Where-Object { $_.AddressFamily -eq "InterNetwork" }
$IPAddressesForSAN = [String]::Join("&IPAddress=",$IPx)

New-SelfSignedCertificate -Subject "ap.ysoft.local" -TextExtension @("2.5.29.17={text}DNS=localhost&DNS=$($CNAME)&IPAddress=$($IPAddressesForSAN)") -KeyAlgorithm RSA -KeyLength 2048 -KeyUsage digitalSignature -NotAfter (Get-Date).AddYears(10) -CertStoreLocation cert:\LocalMachine\My
