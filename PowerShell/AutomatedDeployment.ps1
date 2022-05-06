<#
.SYNOPSIS
   YSoft SAFEQ 6 script to help with updating SAFEQ in different locations.

.DESCRIPTION
   Script automates the update of Site Servers.

   Afterwards it is recommended to check that all services are really started.
   If the script fails on single node when restarting whole PRG, re-run the script on all nodes again.

.EXAMPLE
   Run the PowerShell as Administrator, then launch the script in it.

.NOTES
  Version:        1.00
  Creation Date:  02/May/2022
#>

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------
# Main parameters
$InstallDriveLetter = "C:"
$ServersFile = "$($InstallDriveLetter)\Users\jelinek\Documents\CSS-automation\PowerShell\serverList.txt"
$InstallDirectoryName = "install"
$InstallDirectoryPath = "$($InstallDriveLetter):\$($InstallDirectoryName)"
$InstallPackageName = "ysq-server-ocr-install.zip"
$InstallPackageExe = "SafeQ6.exe"
$InstallPackageSource = "C:\install\$($InstallPackageName)"

# Credentials
$AdminUser = ".\administrator"
$AdminPass = "Start123" | ConvertTo-SecureString -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential ($AdminUser, $AdminPass)

# SQLCMD utility
# $sqlcmd_link = 'https://go.microsoft.com/fwlink/?linkid=2142258'

#-----------------------------------------------------------[Functions]------------------------------------------------------------


#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Admin rights check
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(([System.Security.Principal.SecurityIdentifier]'S-1-5-32-544'))) {
    Write-Warning 'Insufficient privileges. Please re-run the script as an Administrator.'
    Read-Host 'Press any key to exit the script'
    exit
}

Write-Host
Write-Host "========== COPYING STARTED =========="
Write-Host

# Upload the install packages to all servers.
$Servers = Get-Content $ServersFile
$ServerUpdates = @{}
foreach ($server in $Servers) {
    # Check if the remote installation directory exists and create it
    $RemoteInstallDirectory = "\\$($server)\c$\$($InstallDirectoryName)"
    $InstallationPackage = "$RemoteInstallDirectory\$InstallPackageName"
    If (!(Test-Path $RemoteInstallDirectory)) {
        New-Item -ItemType Directory -Force -Path $RemoteInstallDirectory | Out-Null
        Write-Host "Directory: $InstallDirectoryPath created on Server: $server"
    } else {
        Write-Host "Installation Directory already exists on $server"
    }

    # Configure the installation table for all servers
    $ServerUpdates.$server = @{}
    $ServerUpdates.$server.Name = $server
    $ServerUpdates.$server.InstallPack = $InstallationPackage
    $ServerUpdates.$server.LocalInstallPack = "$InstallDriveLetter\$InstallDirectoryName\$InstallPackageName"
    $ServerUpdates.$server.RemoteDestination = "$RemoteInstallDirectory"
    $ServerUpdates.$server.LocalDestination = "$InstallDriveLetter\$InstallDirectoryName"

    # Copy the installation package to the remote servers
    If (Test-Path $InstallationPackage) {
         Write-Host "The installation package already exists: $InstallationPackage"
    } else {
        Write-Host "Copying installation package to: $InstallationPackage"
        Copy-Item $InstallPackageSource -Destination $InstallationPackage
        Write-Host "The installation package is now available in: $InstallationPackage"
    }
}

Write-Host
Write-Host "========== COPYING COMPLETED =========="
Write-Host
Write-Host "========== UNZIP AND INSTALL STARTED =========="
Write-Host

foreach ($server in $ServerUpdates.Keys) {
    #$ZipFile = $ServerUpdates.$server.LocalInstallPack
    $ServerIp = $ServerUpdates.$server.Name
    $Session = New-PSSession -ComputerName $ServerIp -Credential $Credentials
    $current_host = Invoke-Command -Session $Session -ScriptBlock { hostname }
    Write-Host "Working on $current_host ."
    
    # Unpack the ZIP file
    $localInstaller = $ServerUpdates.$server.LocalInstallPack
    $localFolder = $ServerUpdates.$server.LocalDestination
    Invoke-Command -Session $Session -ScriptBlock {
        Expand-Archive -Path $($using:localInstaller) -DestinationPath $($using:localFolder) -Force -Verbose
        } -Verbose

    # Remove the zip file
    $remove_zip = [scriptblock]::Create('Remove-Item -Path $($ZipFile) -Recurse')
    Invoke-Command -Session $Session -ScriptBlock { $remove_zip }

    # Launch the installer
    $installer =  "$InstallDirectoryPath)\$InstallPackageExe"
    Invoke-Command -Session $Session -ScriptBlock { & cmd /c $($using:installer) '/S' } -Verbose
    Invoke-Command -Session $Session -ScriptBlock { $installer }

    $remove_installer = [scriptblock]::Create('Remove-Item -Path "$($InstallDriveLetter):\$($InstallDirectoryName)" -Recurse')
    Invoke-Command -Session $Session -ScriptBlock { $remove_installer }
        
    Get-PSSession | Remove-PSSession
}


Write-Host
Write-Host "========== UNZIP AND INSTALL STARTED =========="
Write-Host
Write-Host "========== DONE =========="
Write-Host

<# LOG FILE CHECK
# Wait for the installation to finish
Start-Sleep -s 180;
$VersionLine = Get-Content -Path "C:\SafeQ6\Management\management-server-install.log" -TotalCount 1
$Version = $VersionLine.Split('version')[-1].Trim()
$InstallationFinished = "false"

while ($InstallationFinished -match "false") {
    Start-Sleep -s 20;
    $FileContents = Get-Content -Path "$($ManagementFolder)\management-server-install.log"
    $CheckMatch = $FileContents | Where-Object { $_ -match "Installation of YSoft SafeQ Management Server version $($Version) finished" }
    $exception = $FileContents | Where-Object { $_ -match " ERROR:" }

    if ($CheckMatch -match '.*') {
        $InstallationFinished = "true"
    } elseif ($exception -match '.*') {
        Write-Host "Installation did not finish properly. Press any key to exit the script and try again..." -foregroundcolor Red;
        exit
    } else {
        Write-Host "Installation has not finished yet."
    }
}

Write-Host "Installation finished."

# Wait until SafeQ is up and running
Start-Sleep -s 99;
$StartupFinished = "false"

while ($startupFinished -match "false") {
    $FileContents = Get-Content -tail 100 -Path "C:\SafeQ6\Management\logs\management-service.log"
    $CheckMatch = $FileContents | Where-Object { $_ -match "Server startup in" }
    $exception = $filecontents | Where-Object { $_ -match "Exception" }

    if ($checkMatch -match '.*') {
        $startupFinished = "true"
    } elseif ($exception -match '.*') {
        Write-Host "Startup of the Management service failed. Press any key to exit the script and try again..." -foregroundcolor Red;
        exit
    } else {
        Write-Host "Waiting for Management Service to complete the startup."
        Start-Sleep -s 10;
    }
}


Write-Host "Update is completed. Press any key to continue..." -foregroundcolor Green;
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
#>
