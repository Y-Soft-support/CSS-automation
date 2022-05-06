# list of servers to be updated
$servers = "10.0.116.101", "10.0.117.86"

# Credentials
$AdminUser = ".\administrator"
$AdminPass = "Start123" | ConvertTo-SecureString -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential ($AdminUser, $AdminPass)

Write-Host
Write-Host "========== INSTALL STARTED =========="
Write-Host

$jobIds = @()

foreach ($server in $servers) {
    $Session = New-PSSession -ComputerName $server -Credential $Credentials
    $here = Invoke-Command -Session $Session -ScriptBlock { hostname }
    Write-Host $here

    Invoke-Command -Session $Session -ScriptBlock { Start-Sleep -Seconds 15 } -Verbose
    #Invoke-Command -Session $Session -ScriptBlock { & cmd /c "C:\Install\MU68\SafeQ6.exe" '/S' } -Verbose

    $jobIds.add("Hello")

    Get-PSSession | Remove-PSSession
}

Write-Host $jobIds

Write-Host
Write-Host "========== UNZIP AND INSTALL STARTED =========="
Write-Host
Write-Host "========== DONE =========="
Write-Host
