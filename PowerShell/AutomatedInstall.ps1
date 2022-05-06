# list of servers to be updated
$SQ6SpoolerController = "10.0.116.101"

# Credentials
$AdminUser = ".\administrator"
$AdminPass = "Start123" | ConvertTo-SecureString -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential ($AdminUser, $AdminPass)

Write-Host
Write-Host "========== INSTALL STARTED =========="
Write-Host

$Session = New-PSSession -ComputerName $SQ6SpoolerController -Credential $Credentials
$here = Invoke-Command -Session $Session -ScriptBlock { hostname }
Write-Host $here
# Invoke-Command -Session $Session -ScriptBlock { Start-Process "C:\Install\MU68\SafeQ6.exe /S" } -Verbose
Invoke-Command -Session $Session -ScriptBlock { & cmd /c "C:\Install\MU68\SafeQ6.exe" '/S' } -Verbose

Get-PSSession | Remove-PSSession

<#
foreach ($server in $ServerUpdates.Keys) {
    #$ZipFile = $ServerUpdates.$server.LocalInstallPack
    $ServerIp = $ServerUpdates.$server.Name
    $Creds = New-Object System.Management.Automation.PSCredential ($AdminUser, $AdminPass)
    $Session = New-PSSession -ComputerName $ServerIp -Credential $Creds
    $current_host = Invoke-Command -Session $Session -ScriptBlock { hostname }
    Write-Host "Working on $current_host ."
    
    # Unpack the ZIP file
    $unzip = [scriptblock]::Create("Expand-Archive -LiteralPath $($ServerUpdates.$server.LocalInstallPack) -DestinationPath $($ServerUpdates.$server.LocalDestination) -Force")
    Write-Host $unzip
    Invoke-Command -Session $Session -ScriptBlock { $unzip }

    $remove_zip = [scriptblock]::Create('Remove-Item -Path $($ZipFile) -Recurse')
    Invoke-Command -Session $Session -ScriptBlock { $remove_zip }

    # Launch the installer
    $installer =  [scriptblock]::Create('& $($InstallDirectoryPath)\SafeQ6.exe /S')
    Invoke-Command -Session $Session -ScriptBlock { $installer }

    $remove_installer = [scriptblock]::Create('Remove-Item -Path "$($InstallDriveLetter):\$($InstallDirectoryName)" -Recurse')
    Invoke-Command -Session $Session -ScriptBlock { $remove_installer }
    #>
    Get-PSSession | Remove-PSSession
#}


Write-Host
Write-Host "========== UNZIP AND INSTALL STARTED =========="
Write-Host
Write-Host "========== DONE =========="
Write-Host
