<#
.SYNOPSIS
  The script helps with trainig certificates rebuild.
      
.DESCRIPTION
  The script:
    - generates new CSRs
    - signs CSRs
    - copies CSR, CER and KEY to training shared folders
  
  PowerShell 3.0 or higher is required, current version can be listed by command: $PSVersionTable.PSVersion.Major
  The script must be launched using PowerShell as an Administrator

.KUDOS
https://github.com/chrisdee/Scripts/blob/master/PowerShell/Working/certificates/GenerateCertificateSigningRequest(CSR).ps1

#>

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

$certificateTemp = "C:\Certificates\temp"
$certificatePath = "C:\Certificates\_valid"
$csrConfiguration = "C:\Certificates\CSR\conf"
$openSSL = "c:\Certificates\OpenSSL-Win64\bin\openssl.exe"


# Training Sets
$trainingSets = @{
    training0 = "CSS100_TRAINING", "CSS101_TRAINING", "CSS102_TRAINING", "CSS103_TRAINING", "CSS104_TRAINING", "CSS109_TRAINING",
        "10.0.66.100", "10.0.66.101", "10.0.66.102", "10.0.66.103", "10.0.66.104", "10.0.66.109", "10.0.66.90"<#;
    training1 = "CSS110_TRAINING", "CSS111_TRAINING", "CSS112_TRAINING", "CSS113_TRAINING", "CSS114_TRAINING", "CSS119_TRAINING",
        "10.0.66.110", "10.0.66.111", "10.0.66.112", "10.0.66.113", "10.0.66.114", "10.0.66.119", "10.0.66.81";
    training2 = "CSS120_TRAINING", "CSS121_TRAINING", "CSS122_TRAINING", "CSS123_TRAINING", "CSS124_TRAINING", "CSS129_TRAINING",
        "10.0.66.120", "10.0.66.121", "10.0.66.122", "10.0.66.123", "10.0.66.124", "10.0.66.129", "10.0.66.82";
    training3 = "CSS130_TRAINING", "CSS131_TRAINING", "CSS132_TRAINING", "CSS133_TRAINING", "CSS134_TRAINING", "CSS139_TRAINING",
        "10.0.66.130", "10.0.66.131", "10.0.66.132", "10.0.66.133", "10.0.66.134", "10.0.66.139", "10.0.66.83";
    training4 = "CSS140_TRAINING", "CSS141_TRAINING", "CSS142_TRAINING", "CSS143_TRAINING", "CSS144_TRAINING", "CSS149_TRAINING",
        "10.0.66.140", "10.0.66.141", "10.0.66.142", "10.0.66.143", "10.0.66.144", "10.0.66.149", "10.0.66.84";
    training5 = "CSS150_TRAINING", "CSS151_TRAINING", "CSS152_TRAINING", "CSS153_TRAINING", "CSS154_TRAINING", "CSS159_TRAINING",
        "10.0.66.150", "10.0.66.151", "10.0.66.152", "10.0.66.153", "10.0.66.154", "10.0.66.159", "10.0.66.85";
    training6 = "CSS160_TRAINING", "CSS161_TRAINING", "CSS162_TRAINING", "CSS163_TRAINING", "CSS164_TRAINING", "CSS169_TRAINING",
        "10.0.66.160", "10.0.66.161", "10.0.66.162", "10.0.66.163", "10.0.66.164", "10.0.66.169", "10.0.66.86";
    training7 = "CSS170_TRAINING", "CSS171_TRAINING", "CSS172_TRAINING", "CSS173_TRAINING", "CSS174_TRAINING", "CSS179_TRAINING",
        "10.0.66.170", "10.0.66.171", "10.0.66.172", "10.0.66.173", "10.0.66.174", "10.0.66.179", "10.0.66.87";
    training8 = "CSS180_TRAINING", "CSS181_TRAINING", "CSS182_TRAINING", "CSS183_TRAINING", "CSS184_TRAINING", "CSS189_TRAINING",
        "10.0.66.180", "10.0.66.181", "10.0.66.182", "10.0.66.183", "10.0.66.184", "10.0.66.189", "10.0.66.88";
    training9 = "CSS190_TRAINING", "CSS191_TRAINING", "CSS192_TRAINING", "CSS193_TRAINING", "CSS194_TRAINING", "CSS199_TRAINING",
        "10.0.66.190", "10.0.66.191", "10.0.66.192", "10.0.66.193", "10.0.66.194", "10.0.66.199", "10.0.66.90"#>
 }


#-----------------------------------------------------------[Functions]------------------------------------------------------------

Function New-CertificateSigningRequest ($trainingUser, $trainingServers) {

    # Create a file for CSR and for the certificate configuration
    $files = @{}
    $files['conf'] = "$($certificateTemp)\$($trainingUser)-csr.conf";
    $files['csr'] = "$($certificateTemp)\$($trainingUser)-csr.req";
    $files['key'] = "$($certificateTemp)\$($trainingUser).key";
    
    # Get the main host and the rest of the servers
    $trainingHost, $trainingServers = $trainingServers

    # Configure SANs
    $subjectAlternativeNames = ''
    foreach($item in $trainingServers) {
        if ($item -match "CSS*") {
            $subjectAlternativeNames += "DNS = $($item)" + [System.Environment]::NewLine
        } else {
            $subjectAlternativeNames += "IP = $($item)" + [System.Environment]::NewLine
        }
    }

    # Configure the certificate
    $certificateSettings = @"
[CA_default]
default_days = 365
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no
[req_distinguished_name]
emailAddress = $($trainingUser)@training.local
C = CZ
ST = Moravia
L = Brno
O = YSoft Corporation, a.s.
OU = YSoft SafeQ Training
CN = $($trainingHost)
[v3_req]
keyUsage = nonRepudiation, keyEncipherment, dataEncipherment, keyAgreement
extendedKeyUsage = serverAuth, clientAuth, codeSigning
subjectAltName = @alt_names
[alt_names]
DNS = *.training.local
$subjectAlternativeNames
"@
    

    # Save settings to a file in temp
    $certificateSettings > $files['conf'] | Out-Null

    # Create the CSR
    # & certreq -f -new $files['conf'] $files['csr'] > $null
    $env:OPENSSL_CONF = "C:\Certificates\OpenSSL-Win64\bin\openssl.cnf"
    & $($openSSL) req -new -newkey rsa:2048 -nodes -out $files['csr'] -keyout $($files['key']) -config $($files['conf'])
    # c:\Certificates\OpenSSL-Win64\bin\openssl.exe req -new -newkey rsa:2048 -nodes -out c:\Certificates\temp\training0-csr.req -keyout c:\Certificates\temp\training0.key -config c:\Certificates\CSR\conf\Training0_csr.cnf
}

Function Sign-CertificateSigningRequest ($csr) {
    $cerFile = $csr.Split(".")
    
    $ certreq.exe -attrib "CertificateTemplate:WebServer" $csr $cerFile
    Get-Content $cerFile

}

Function Copy-CertificateFiles ($trainingSet) {

}


#-----------------------------------------------------------[Execution]------------------------------------------------------------


# 
foreach ($trainingSet in $trainingSets.Keys) {
    Write-Host $trainingSet
    
    # Dictionary stores value as a string and we need a list
    $list = @()
    $list = $trainingSets[$trainingSet] -split " "

    New-CertificateSigningRequest $trainingSet $list
}


########################
# Remove temporary files
########################
#$files.Values | ForEach-Object {
#    Remove-Item $_ -ErrorAction SilentlyContinue
#}
