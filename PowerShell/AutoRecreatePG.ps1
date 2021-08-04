<#
.SYNOPSIS
This script will recreate the database using the backup you will select.

.DESCRIPTION
Currently supports PostgreSQL for SafeQ 6.

.EXAMPLE

#>

Param (
    [Parameter(Mandatory=$false)][string]$PSQL = (Get-WmiObject Win32_Service | Where-Object Name -Like "*SQL*" | Select-Object -ExpandProperty "PathName" | Foreach-Object {(-split $_)[0].Trim("`"") -replace "pgservice.exe", "bin\psql.exe"} | Measure-Object -Minimum | Select-Object -ExpandProperty "Minimum"),
    [Parameter(Mandatory=$false)][string]$PGDump = ($PSQL | Foreach-Object {(-split $_)[0].Trim("`"") -replace "psql.exe", "pg_dump.exe"}),
    [Parameter(Mandatory=$false)][string]$PGhost = "127.0.0.1",
    [Parameter(Mandatory=$false)][string]$PGuser = "postgres"
     )

# User input variables
if(($PGDB = Read-Host "Type DB name or use default [SQDB6]") -eq ''){"SQDB6"}else{$PGDB}
if(($PGpass = Read-Host "Type postgres password or use default [111111]") -eq ''){"111111"}else{$PGpass}
if(($PGport = Read-Host "Type postgres port or use default [5433]") -eq ''){"5433"}else{$PGport}

Function TestDB([String]$PGDB){
	
	$pcmd = "SELECT 1 AS result FROM pg_database WHERE datname='$PGDB';"
	try{
		$queryResult = & $PSQL -p $PGport -U $PGuser -c $pcmd
		$rv = $queryResult[2]
		if ($rv -eq "(0 rows)") {
			$rv = 0
			if($myDebug){Write-Host "TestDB found no value: $rv"}
		} else{
			$rv = [int]$rv
			if($myDebug){Write-Host "TestDB found value: $rv"}
		}
		return $rv
	}
	catch
	{
		if($myDebug){Write-Host "TestDB failed on $db"}
		return -1
	}
}


#  STOP SERVICES
Get-Service *YSoft* | Where-Object {$_.Name -ne 'YSoftPGSQL' -and $_.Name -ne 'YYSoftPGSQL' -and $_.Name -ne 'YSoftEtcd'} | Stop-Service -WarningAction silentlyContinue

<#
# BACKUP 
C:\SafeQ5\PGSQL\bin\pg_dump.exe --host 127.0.0.1 # port 5433 # username "postgres" # no-password  # format custom # blobs # encoding UTF8 # verbose # file "C:\Users\Administrator\Desktop\bak\DATA\test.backup" "SQDB5"
C:\SafeQ5\PGSQL\bin\pg_dump.exe --host 127.0.0.1 # port 5433 # username "postgres" # no-password  # format custom # blobs # encoding UTF8 # verbose # file "C:\Users\Administrator\Desktop\bak\DATA\test.backup" "SQDB5_SQDW"

# SQL
DROP DATABASE SQDB5
DROP DATABASE SQDB5_SQDW

#  CREATE DBs
CREATE DATABASE SQDB5
CREATE DATABASE SQDB5_SQDW

# Upload license

# RESTORE
C:\SafeQ5\PGSQL\bin\pg_restore.exe --host 127.0.0.1 # port 5433 # username "postgres" # dbname "SQDB5" # no-password  # verbose "C:\Users\Administrator\Desktop\bak\MU62.backup"

C:\SafeQ5\PGSQL\bin\pg_restore.exe --host 127.0.0.1 # port 5433 # username "postgres" # dbname "SQDB5_SQDW" # no-password  # verbose "C:\Users\Administrator\Desktop\bak\MU62DW.backup"

# UPDATE database
UPDATE cluster_server SET ip_address = '10.0.125.144', description = 'CSS700' WHERE id=1
TRUNCATE TABLE smartq_validator (SQDB5, SQDB5_SQDW)

#>

# START SERVICES
Get-Service *YSoft* | Where-Object {$_.Name -ne 'YSoftPGSQL' -and $_.Name -ne 'YYSoftPGSQL' -and $_.Name -ne 'YSoftEtcd'} | Start-Service -WarningAction silentlyContinue
