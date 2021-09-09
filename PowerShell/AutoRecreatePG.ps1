<#
.SYNOPSIS
This script will recreate the database using the backup you will select.

.DESCRIPTION
Currently supports PostgreSQL for SafeQ 6.

.EXAMPLE

#>

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

# Default PostgreSQl connection
$PG_BIN = "c:\SafeQ6\Management\PGSQL\bin" 
$PG_HOST = "127.0.0.1"
$PG_PORT = "5433"
$PG_DB = "SQDB6"
$PG_USER = "postgres"
$env:PGPASSWORD = "111111"
# if(($PG_DB = Read-Host "Type DB name or use default [SQDB6]") -eq ''){"SQDB6"}else{$PGDB}

# SQL commands
$DROP_DB = "DROP DATABASE SQDB6;"
$CREATE_DB = "CREATE DATABASE SQDB6;"

# Backup folder
$BACKUP_FILE = "C:\backup\SQDB6.backup"

#-----------------------------------------------------------[Functions]------------------------------------------------------------

Function Test-DatabaseConnection([String]$PGDB){
	
	$query = "SELECT 1 AS result FROM pg_database WHERE datname='$PGDB';"
	try{
		$queryResult = & $PG_BIN\psql.exe -p $PG_PORT -U $PG_USER -c $query
		$rv = $queryResult[2]
		if ($rv -eq "(0 rows)") {
			$rv = 0
			if($myDebug){Write-Host "TestDB found no value: $rv"}
		} else {
			$rv = [int]$rv
			if($myDebug){Write-Host "TestDB found value: $rv"}
		}
		return $rv
	} catch {
		if($myDebug){Write-Host "TestDB failed on $db"}
		return -1
	}
}

Function Backup-Database {
    & $PG_BIN\pg_dump -Fc dbname > $BACKUP_FILE
}

Function Restore-Database {
    # DROP the DB and create it again
    & $PG_BIN\runtime\psql.exe -U postgres -p 5433 -c $DROP_DB;
    & $PG_BIN\runtime\psql.exe -U postgres -p 5433 -c $CREATE_DB;

    # restore DB backup
    & $PG_BIN\pg_restore -d SQDB6 -U postgres -p 5433 $BACKUP_FILE;
}


#-----------------------------------------------------------[Execution]------------------------------------------------------------

# Test the connection to db and that the DB exists
$PSQL = (Get-WmiObject Win32_Service | Where-Object Name -Like "*SQL*" | Select-Object -ExpandProperty "PathName" | Foreach-Object {(-split $_)[0].Trim("`"") -replace "pgservice.exe", "bin\psql.exe"} | Measure-Object -Minimum | Select-Object -ExpandProperty "Minimum")
$PG_DUMP = ($PSQL | Foreach-Object {(-split $_)[0].Trim("`"") -replace "psql.exe", "pg_dump.exe"})
$PSQL = (Get-WmiObject Win32_Service | Where-Object Name -Like "*SQL*" | Select-Object -ExpandProperty "PathName" | Foreach-Object {(-split $_)[0].Trim("`"") -replace "pgservice.exe", "bin\psql.exe"} | Measure-Object -Minimum | Select-Object -ExpandProperty "Minimum")
Test-DatabaseConnection $PG_DB
PG_BIN
# Stop all YSoft services
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
