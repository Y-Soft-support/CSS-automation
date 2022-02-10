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

# SQL commands
$DROP_DB = "DROP DATABASE $($PG_DB);"
$CREATE_DB = "CREATE DATABASE $($PG_DB);"

# Backup file path
$timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
$BACKUP_FILE = "C:\backup\SQDB6_$timestamp.backup"

# Miscelaneous
$IPV4 = (Get-NetIPAddress | Where-Object {$_.AddressState -eq "Preferred" -and $_.PrefixLength -eq 22}).IPAddress
$CNAME = [System.Net.Dns]::GetHostName()

#-----------------------------------------------------------[Functions]------------------------------------------------------------

Function Test-DatabaseConnection($database) {

	$query = "SELECT 1 FROM pg_database WHERE datname='$database';"
	try{
		$queryResult = & $PG_BIN\psql.exe -p $PG_PORT -U $PG_USER -c $query
		$check = $queryResult[3]
		if ($check -eq "(1 row)") {
			Write-Host "Database check successful."
		} else {
			Write-Host "Database not found. Please verify the database name."
		}
	} catch {
		Write-Host "Verify the database connection parameters."
		Read-Host 'Press any key to exit the script'
		exit
	}
}

Function Backup-Database {
    & $PG_BIN\pg_dump -h $PG_HOST -p $PG_PORT -U $PG_USER -Fc $PG_DB > $BACKUP_FILE | Out-Null
}

Function Restore-Database {
    # DROP the DB and create it again
    & $PG_BIN\runtime\psql.exe -U postgres -p 5433 -c $DROP_DB;
    & $PG_BIN\runtime\psql.exe -U postgres -p 5433 -c $CREATE_DB;

    # restore DB backup
    & $PG_BIN\pg_restore -d SQDB6 -U postgres -p 5433 $BACKUP_FILE;
}

Function Update-ClusterServer {
	$SQL_1 = UPDATE cluster_server SET ip_address = '$IPV4', description = '$CNAME' WHERE id=1
	$SQL_2 = TRUNCATE TABLE smartq_validator  # (SQDB5, SQDB5_SQDW)
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

# TODO: Detect PG folder

# Test if the connection to database is open and that the database exists
Test-DatabaseConnection $PG_DB

# Stop all YSoft services
Get-Service *YSoft* | Where-Object {$_.Name -ne 'YSoftPGSQL' -and $_.Name -ne 'YYSoftPGSQL' -and $_.Name -ne 'YSoftEtcd'} | Stop-Service -WarningAction silentlyContinue

# Backup of the database
Backup-Database

# Recreate the database from the backup
Restore-Database

# Reset password for the admin


# UPDATE database
Update-ClusterServer


# Start all YSoft services
Get-Service *YSoft* | Where-Object {$_.Name -ne 'YSoftPGSQL' -and $_.Name -ne 'YYSoftPGSQL' -and $_.Name -ne 'YSoftEtcd'} | Start-Service -WarningAction silentlyContinue


<# Test the connection to db and that the DB exists
$PSQL = (Get-WmiObject Win32_Service | Where-Object Name -Like "*SQL*" | Select-Object -ExpandProperty "PathName" | Foreach-Object {(-split $_)[0].Trim("`"") -replace "pgservice.exe", "bin\psql.exe"} | Measure-Object -Minimum | Select-Object -ExpandProperty "Minimum")
$PG_DUMP = ($PSQL | Foreach-Object {(-split $_)[0].Trim("`"") -replace "psql.exe", "pg_dump.exe"})
$PSQL = (Get-WmiObject Win32_Service | Where-Object Name -Like "*SQL*" | Select-Object -ExpandProperty "PathName" | Foreach-Object {(-split $_)[0].Trim("`"") -replace "pgservice.exe", "bin\psql.exe"} | Measure-Object -Minimum | Select-Object -ExpandProperty "Minimum")
Test-DatabaseConnection $PG_DB
PG_BIN


# Upload license

# UPDATE database
UPDATE cluster_server SET ip_address = '10.0.125.144', description = 'CSS700' WHERE id=1
TRUNCATE TABLE smartq_validator (SQDB5, SQDB5_SQDW)


#>
