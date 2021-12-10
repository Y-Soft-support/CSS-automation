<#
.SYNOPSIS
   YSoft SAFEQ 6 installation script for Management Service. It is mainly for Technical Analyst practical test evaluation.

.DESCRIPTION
   Script automates installation of Management Service and restoration of a PostgreSQL database.
   Before running the script:
   - Make sure the pgAdmin 4 is installed
   - Upload desired Management Service installer version to C:\install
   - Upload the backup of the database to C:\backup and make sure its name is SQDB6.backup

   Afterwards it is recommended to check that all services are really started.
   If the script fails on single node when restarting whole PRG, re-run the script on all nodes again.

.EXAMPLE
   Run the PowerShell as Administrator, then launch the script in it.

.NOTES
  Version:        1.03
  Creation Date:  04/Sep/2020
#>

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------
# $INSTALL_SOURCE = ? TODO
$PGPASS = '111111'

$DROP_DB = "DROP DATABASE SQDB6;"
$CREATE_DB = "CREATE DATABASE SQDB6;"

$SQL_1 = "TRUNCATE TABLE cluster_mngmt.cluster_server;"
$SQL_2 = "UPDATE cluster_mngmt.tenants SET db_pass='111111' WHERE schema_name='tenant_1';"
$SQL_3 = "UPDATE cluster_mngmt.tenant_warehouses SET db_pass='111111' WHERE schema_name='dwhtenant_1';"
$SQL_4 = "ALTER ROLE tenantuser_1 WITH PASSWORD '111111';"
$SQL_5 = "ALTER ROLE dwhtenantuser_1 WITH PASSWORD '111111';"
$SQL_6 = "UPDATE cluster_mngmt.users SET pass = '`$2a`$12`$H5.1EcVQHvGkO/LrTtXbj.S8O1O.WzKKVgAgoDlkb4QOpylHdJI9u' WHERE login = 'admin';"
$SQL_7 = "UPDATE tenant_1.users SET pass = '`$2a`$12`$H5.1EcVQHvGkO/LrTtXbj.S8O1O.WzKKVgAgoDlkb4QOpylHdJI9u' WHERE login = 'admin';"
$SQL_UPD = $SQL_1, $SQL_2, $SQL_3, $SQL_4, $SQL_5, $SQL_6, $SQL_7

$IPV4 = (Get-NetIPAddress | Where-Object {$_.AddressState -eq "Preferred" -and $_.PrefixLength -eq 22}).IPAddress

$PGA_HKLM = "\SOFTWARE\pgAdmin 4"

$SafeqFolder = "C:\SafeQ6"
$ManagementFolder = "$($SafeqFolder)\Management"

#-----------------------------------------------------------[Functions]------------------------------------------------------------

Function Get-PgAdminPath {
    try {
        $PgAdminVersion = Get-ChildItem -Path HKLM:$($PGA_HKLM) -Name
        $PgAdmin = Get-ItemPropertyValue -Path HKLM:$($PGA_HKLM)\$($PgAdminVersion) -Name InstallPath
    }
    catch {
        $PgAdmin = $null
    }
  
    Return $PgAdmin
}

Function cleaningAfterUninstall {

    $reg1 = "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Y Soft Corporation\YSoft SafeQ 6"
    $reg2 = '"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "SAFEQ_HOME"'
    $reg3 = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\YSoft SafeQ 6}"
    $registries = $reg1, $reg2, $reg3

    Remove-Item -LiteralPath $SafeqFolder -Force -Recurse -ErrorAction SilentlyContinue

    if (Test-Path HKLM:\SYSTEM\CurrentControlSet\Services\YSoftEtcd) {sc.exe delete -Name "YSoftEtcd" | Out-Null}
    if (Test-Path HKLM:\SYSTEM\CurrentControlSet\Services\YSoftIms) {sc.exe delete "YSoftIms" | Out-Null}
    if (Test-Path HKLM:\SYSTEM\CurrentControlSet\Services\YSoftSQ-LDAP) {sc.exe delete "YSoftSQ-LDAP" | Out-Null}
    if (Test-Path HKLM:\SYSTEM\CurrentControlSet\Services\YSoftSQ-Management) {sc.exe delete -Name "YSoftSQ-Management" | Out-Null}
    if (Test-Path HKLM:\SYSTEM\CurrentControlSet\Services\YSoftSQ-EUI) {sc.exe delete "YSoftSQ-EUI" | Out-Null}
    if (Test-Path HKLM:\SYSTEM\CurrentControlSet\Services\YSoftSQ-FSP) {sc.exe delete "YSoftSQ-FSP" | Out-Null}
    if (Test-Path HKLM:\SYSTEM\CurrentControlSet\Services\YSoftSQ-SPOC) {sc.exe delete "YSoftSQ-SPOC" | Out-Null}
    if (Test-Path HKLM:\SYSTEM\CurrentControlSet\Services\YSoftSQ-SPOCGS) {sc.exe delete "YSoftSQ-SPOCGS" | Out-Null}
    if (Test-Path HKLM:\SYSTEM\CurrentControlSet\Services\YSoftSQ-TS) {sc.exe delete "YSoftSQ-TS" | Out-Null}
    if (Test-Path HKLM:\SYSTEM\CurrentControlSet\Services\YSoftSQ-WPS) {sc.exe delete "YSoftSQ-WPS" | Out-Null}
    if (Test-Path HKLM:\SYSTEM\CurrentControlSet\Services\YSoftImsProxy) {sc.exe delete "YSoftImsProxy" | Out-Null}
    if (Test-Path HKLM:\SYSTEM\CurrentControlSet\Services\ABBYY.Licensing.FineReaderEngine.Windows.11.0) {sc.exe delete "ABBYY.Licensing.FineReaderEngine.Windows.11.0" | Out-Null}

    ForEach ($reg in $registries) {
        if (Test-Path $reg) {Remove-Item -Path $reg -Force -Verbose}
    }
}

Function Restore-Database {
    $env:PGPASSWORD = $PGPASS
    
    # recreate DB
    & $PgAdminPath\runtime\psql.exe -U postgres -p 5433 -c $DROP_DB;
    & $PgAdminPath\runtime\psql.exe -U postgres -p 5433 -c $CREATE_DB;

    # restore DB backup and update internal users
    # text format: & $PgAdminPath\runtime\psql.exe -d SQDB6 -U postgres -p 5433 -1 -f c:\backup\sqdb6.backup;
    & $PgAdminPath\runtime\pg_restore -d SQDB6 -U postgres -p 5433 c:\backup\sqdb6.backup;
    
    ForEach ($sql in $SQL_UPD) {
        & $PgAdminPath\runtime\psql.exe -U postgres -p 5433 -d SQDB6 -c $sql; 
    }
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Admin rights check
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(([System.Security.Principal.SecurityIdentifier]'S-1-5-32-544'))) {
    Write-Warning 'Insufficient privileges. Please re-run the script as an Administrator.'
    Read-Host 'Press any key to exit the script'
    exit
}

# Check pgAdmin 4 availability
if (Get-PgAdminPath) {
    $PgAdminPath = Get-PgAdminPath 
} else {
    Write-Warning 'The pgAdmin 4 not found. Please install the pgAdmin 4 manually from the following URL:'
    Start-Process "https://www.postgresql.org/ftp/pgadmin/pgadmin4/"
    Read-Host 'Press any key to exit the script.'
    exit
}

# Make sure the previous installation and leftovers are cleaned
Write-Host "Verifying and cleaning the previously installed SafeQ installation."
if (Test-Path $SafeqFolder) {
    try {
        Start-Process -Wait $($ManagementFolder)\uninstall.exe /S
    } catch {
        Write-Host "YSoft SafeQ 6 is already uninstalled."
    } finally {
        cleaningAfterUninstall
        Write-Host "YSoft SafeQ 6 additional cleaning is finished."
    }
}

# Install Management Service
C:\Install\ysq-management-server-install.exe /S /CFG:dbPassword=$PGPASS /CFG:noStartSvcs /CFG:dbClass=PGSQL /CFG:localGUID=mgmt /CFG:usedLocalIp=$IPV4 /CFG:embeddedDB /D=$ManagementFolder;
Write-Host "New YSoft SafeQ 6 installation has started."

# Wait for the installation to finish
Start-Sleep -s 180;
$VersionLine = Get-Content -Path "C:\SafeQ6\Management\management-server-install.log" -TotalCount 1
$Version = $VersionLine.Split('version')[-1].Trim()
$InstallationFinished = "false"

while ($InstallationFinished -match "false") {
Start-Sleep -s 20;
$FileContents = Get-Content -Path "$($ManagementFolder)\management-server-install.log" -TotalCount 1
$CheckMatch = $FileContents | Where-Object { $_ -match "Installation of YSoft SafeQ Management Server version $($Version) finished" }

    if ($CheckMatch -match '.*') {
        $InstallationFinished = "true"
    } else {
        Write-Host "Installation has not finished yet."
    }
}

Write-Host "Installation finished."

# Restore Database function
Restore-Database

# Start Management Service
Start-Service -Name "YSoftSQ-Management";

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

Write-Host "Startup is completed."

# TODO: Activate YSoft SafeQ License automatically (an API user is needed or database insert must be done)

$License = Get-Content "\\10.0.0.105\licence_devel\SafeQ 6.0\current\license.xml" -Raw
Set-Clipboard -Value $License

Write-Host "SQDB6 database was succesfully restored. License for activation is in your clipboard or you can rerun License-To-Clipboard.ps1. Press any key to continue..." -foregroundcolor Green;
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
