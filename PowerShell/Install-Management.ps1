<#
.SYNOPSIS
   YSoft SAFEQ 6 installation script for Management Service. It is mainly for Technical Analyst practical test evaluation.

.DESCRIPTION
   Script automates installation of Management Service and restoration of a database.
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
# Get pgAdmin Folder
$PgAdminVersion = Get-ChildItem -Path HKLM:"\SOFTWARE\pgAdmin 4" -Name
$PgAdminPath = Get-ItemPropertyValue -Path HKLM:"\SOFTWARE\pgAdmin 4\$($PgAdminVersion)" -Name InstallPath

$DROP_DB = "DROP DATABASE SQDB6;"
$CREATE_DB = "CREATE DATABASE SQDB6;"

$SQL_1 = "TRUNCATE TABLE cluster_mngmt.cluster_server;"
$SQL_2 = "UPDATE cluster_mngmt.tenants SET db_pass='111111' WHERE schema_name='tenant_1';"
$SQL_3 = "UPDATE cluster_mngmt.tenant_warehouses SET db_pass='111111' WHERE schema_name='dwhtenant_1';"
$SQL_4 = "ALTER ROLE tenantuser_1 WITH PASSWORD '111111';"
$SQL_5 = "ALTER ROLE dwhtenantuser_1 WITH PASSWORD '111111';"

$SQL_UPD = $SQL_1, $SQL_2, $SQL_3, $SQL_4, $SQL_5

#-----------------------------------------------------------[Functions]------------------------------------------------------------

Function cleaningAfterUninstall {
    # param([string]$ServiceName)
    Remove-Item -LiteralPath "C:\SafeQ6" -Force -Recurse -ErrorAction SilentlyContinue
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
    # if (Test-Path HKLM:\SYSTEM\CurrentControlSet\Services\ABBYY.Licensing.FineReaderEngine.Windows.11.0) {sc.exe delete "ABBYY.Licensing.FineReaderEngine.Windows.11.0" | Out-Null}
    # DeleteRegKey "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${REGISTRY_PRODUCT_NAME}"
    # DeleteRegValue "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "SAFEQ_HOME"
    # DeleteRegKey "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Y Soft Corporation\YSoft SafeQ 6"
}


#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Admin rights check
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(([System.Security.Principal.SecurityIdentifier]'S-1-5-32-544'))) {
    Write-Warning 'Administrative rights are missing. Please re-run the script as an Administrator.'
    Read-Host 'Press any key to exit the script'
    exit
}

# Clean the system
Write-Host "Cleaning the previously installed SafeQ installation."
if (Test-Path C:\SafeQ6) {
    try {
        Start-Process -Wait C:\SafeQ6\Management\uninstall.exe /S
    } catch {
        Write-Host "YSoft SafeQ 6 is already uninstalled."
    } finally {
        cleaningAfterUninstall
        Write-Host "YSoft SafeQ 6 additional cleaning is finished."
    }
}

# Install Management Service
C:\Install\ysq-management-server-install.exe /S /CFG:dbPassword=111111 /CFG:noStartSvcs /CFG:dbClass=PGSQL /CFG:localGUID=mgmt201 /CFG:usedLocalIp=10.0.116.177 /CFG:embeddedDB /D=C:\SafeQ6\Management;
Write-Host "New YSoft SafeQ 6 installation has started."

# Wait for the installation to finish
Start-Sleep -s 180;
$fin = "finished"
$version = "6.0.*.[0-9]"
$installationFinished = "false"

while ($installationFinished -match "false") {
Start-Sleep -s 20;
$filecontents = Get-Content -tail 10 -Path "C:\SafeQ6\Management\management-server-install.log"
$checkMatch = $filecontents | Where-Object { $_ -match "Installation of YSoft SafeQ Management Server version $($version) $($fin)" }

    if ($checkMatch -match '.*') {
        $installationFinished = "true"
    } else {
        Write-Host "Installation has not finished yet."
    }
}

Write-Host "Installation finished."

<#  # Stop services 
Stop-Service -Name "YSoftSQ-Management";
Stop-Service -Name "YSoftSQ-LDAP";
Stop-Service -Name "YSoftIms";
#>

# Restore Database
$env:PGPASSWORD = '111111';

& $PgAdminPath\runtime\psql.exe -U postgres -p 5433 -c $DROP_DB;
& $PgAdminPath\runtime\psql.exe -U postgres -p 5433 -c $CREATE_DB;
& $PgAdminPath\runtime\pg_restore -d SQDB6 -U postgres -p 5433 c:\backup\sqdb6.backup;
# text format: & $PgAdminPath\runtime\psql.exe -d SQDB6 -U postgres -p 5433 -1 -f c:\backup\sqdb6.backup;

ForEach ($sql in $SQL_UPD) {
    & $PgAdminPath\runtime\psql.exe -U postgres -p 5433 -d SQDB6 -c $sql; 
}

# update remote access to the DB server
# Add-Content C:\SafeQ6\Management\PGSQL-data\pg_hba.conf "`nhost    all             all             10.0.0.0/16            trust"

# Start Management Service
Start-Service -Name "YSoftSQ-Management";

<#  # Start other services
Start-Service -Name "YSoftSQ-LDAP";
Start-Service -Name "YSoftIms";
#>

# Wait until SafeQ is up and running
# Started Application in
Start-Sleep -s 99;
$startupFinished = "false"

while ($startupFinished -match "false") {
    $filecontents = Get-Content -tail 100 -Path "C:\SafeQ6\Management\logs\management-service.log"
    $checkMatch = $filecontents | Where-Object { $_ -match "Server startup in" }

    if ($checkMatch -match '.*') {
        $startupFinished = "true"
    } elseif (Get-Service | Where-Object {$_.Status -eq "Stopped" -and $_.Name -eq "YSoftSQ-Management"}) {
        #$checkMatch = $filecontents | Where-Object { $_ -match "Exception" }
        Write-Host "Check the mangement-service.log file it seems something is going wrong!" -foregroundcolor Red
    }    else {
        Write-Host "Waiting for Management Service to complete the startup."
        Start-Sleep -s 10;
    }
}

Write-Host "Startup is completed."

<# TODO: Admin pasword change

# To MU 30:
UPDATE [cluster_mngmt].[users] SET pass = '$2a$12$KoX2bsKdA0PjrYlxIX8S5.ATTJNn3.xRYxiu/OZKLlw9.M6Ml2Vjq' WHERE login = 'admin'
UPDATE [tenant_1].[users] SET pass = '$2a$12$KoX2bsKdA0PjrYlxIX8S5.ATTJNn3.xRYxiu/OZKLlw9.M6Ml2Vjq' WHERE login = 'admin'
# From MU 30:
UPDATE [cluster_mngmt].[users] SET pass = '$2a$12$H5.1EcVQHvGkO/LrTtXbj.S8O1O.WzKKVgAgoDlkb4QOpylHdJI9u' WHERE login = 'admin'
UPDATE [tenant_1].[users] SET pass = '$2a$12$H5.1EcVQHvGkO/LrTtXbj.S8O1O.WzKKVgAgoDlkb4QOpylHdJI9u' WHERE login = 'admin'
#>

# TODO: Activate YSoft SafeQ License automatically (an API user is needed or database insert must be done)
$license = Get-Content "\\10.0.0.105\licence_devel\SafeQ 6.0\current\license.xml" -Raw
Set-Clipboard -Value $license

Write-Host "SQDB6 database was succesfully restored. License for activation is in your clipboard or you can rerun License-To-Clipboard.ps1. Press any key to continue..." -foregroundcolor Green;
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
