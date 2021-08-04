<#
.SYNOPSIS
  The script helps rebuiliding ETCD cache of YSoft SafeQ 6 Management Service.
      
.DESCRIPTION
  The script identifies YSoft SafeQ installation, backs up ETCD cache and rebuilds it.
  The back up is created in C:\SafeQ6\Management\etcd folder.
  
  PowerShell 3.0 or higher is required, current version can be listed by command: $PSVersionTable.PSVersion.Major
  The script must be launched using PowerShell as an Administrator
     
.PARAMETER EtcdFolder
  Defines the folder where Mangement Server ETCD is installed.
  The parameter is auto detected. If you face some issues with detection you may configure it manually.
  Default ETCD path: "C:\SafeQ6\Management\etcd"

.NOTES
  Version:        0.1
  Creation Date:  11/05/2021
      
.EXAMPLE
  Run Windows PowerShell as an administrator and launch the command as follows:
  C:\Users\Administrator\Downloads> .\rebuildEtcd.ps1
#>

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

# PATH to ETCD folder
$EtcdExe = Get-ItemPropertyValue -Path HKLM:\SYSTEM\CurrentControlSet\Services\YSoftEtcd -Name ImagePath
$EtcdFolder = $EtcdExe.Split()[0].Trim('\prunsrv.exe')

# Timestamp
$Timestamp = "$((Get-Date).ToString('yyyyMMddHHmm'))"

# ETCD data
$EtcdData = "$($EtcdFolder)\$($env:COMPUTERNAME).etcd"

# Backup folder
$BackupFolder = "$($EtcdFolder)\backup_etcd_$($Timestamp)"

#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Admin rights check
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(([System.Security.Principal.SecurityIdentifier]'S-1-5-32-544'))) {
    Write-Warning 'Administrative rights are missing. Please re-run the script as an Administrator.'
    Pause
    exit
}

# Set working directory
Set-Location -Path $EtcdFolder

# Create backup directory
Write-Host "Creating backup directory: $($BackupFolder)" -ForegroundColor Yellow
New-Item -Path "$($BackupFolder)" -ItemType "directory" | Out-Null

# BACKUP ETCD values
Write-Host "Backing up current ETCD values."
$etcdDump = "$($BackupFolder)\etcddump.ps1"
& .\etcdctl.exe ls / | ForEach-Object{" .\etcdctl.exe --endpoint `"http://127.0.0.1:2379`" mk $($_ -replace `"/`", `"`") `"$(.\etcdctl.exe get $_)`"" | Out-File $etcdDump -append }
Start-Sleep -Seconds 5

# Stop ETCD service
Write-Host "Stopping ETCD service." -ForegroundColor Red
try { 
    Stop-Service YSoftEtcd -ErrorAction Stop
} 
catch { 
    Throw "Stopping YSoftEtcd service has failed, terminating"
} 
finally {
}

# BACKUP ETCD cache
Write-Host "Backing up ETCD cache into $($BackupFolder)"
Move-Item -Path $EtcdData -Destination "$($BackupFolder)\$($env:COMPUTERNAME).etcd"

# Start ETCD service
Write-Host "Starting ETCD service."
try { 
    Start-Service YSoftEtcd -ErrorAction Stop
    Start-Sleep -Seconds 5
} 
catch { 
    Throw "Starting YSoftEtcd service has failed, terminating"
} 
finally {
}

# Cluster health check
Write-Host "ETCD Healthcheck result:" -ForegroundColor Yellow
& .\etcdctl.exe --endpoint http://127.0.0.1:2379 cluster-health

# Restore ETCD Values
try{
    & $etcdDump | Out-Null
} 
catch { 
    Throw "Restoring ETCD cache has failed, terminating. Proceed with restoration of the ETCD values manually according to the documentation."
} 
finally {
    Write-Host "ETCD Values Restored" -ForegroundColor Green
}

Pause

<#
.\etcdctl.exe --endpoint http://127.0.0.1:2379 mk embeddedDb "0"
.\etcdctl.exe --endpoint http://127.0.0.1:2379 mk dbClass "PGSQL"
.\etcdctl.exe --endpoint http://127.0.0.1:2379 mk dbDbName "SQDB6"
.\etcdctl.exe --endpoint http://127.0.0.1:2379 mk dbHost "localhost"
.\etcdctl.exe --endpoint http://127.0.0.1:2379 mk dbPort "5433"
.\etcdctl.exe --endpoint http://127.0.0.1:2379 mk dbDbUsername "postgres"
.\etcdctl.exe --endpoint http://127.0.0.1:2379 mk encryptedUserPassword "%password%"
.\etcdctl.exe --endpoint http://127.0.0.1:2379 mk encryptedClusterPassword "%password%"
.\etcdctl.exe --endpoint http://127.0.0.1:2379 mk encryptedClusterGuestPassword "%password%"
#>
