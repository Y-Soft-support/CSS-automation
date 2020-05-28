<#
.SYNOPSIS

Performs backup functions on the SafeQ installation according to various input flags

.DESCRIPTION

The SafeQBackup.ps1 script backs-up the SafeQ installation as requested by the input
flags and will remove old backups as defined so as to maintain a small history.

.PARAMETER backupDir
Specifies the path to the backup location (e.g. C:\SafeQ_Backups\Daily\).

.PARAMETER backupDb
Flag telling the script to backup the SafeQ database. Currently only supports PostgreSQL.

.PARAMETER backupConfig
Flag telling the script to backup the various SafeQ Config files and directories.

.PARAMETER backupBinaries
Flag telling the script to backup the various SafeQ binaries and directories.

.PARAMETER userName
String providing the login name to the PostgreSQL database

.PARAMETER password
String providing the password associated with the login to the PostgreSQL database

.PARAMETER maxRollCount
Number of backups to maintain when cleaning up old files.  Default is 3.  If parameter
is omitted, then no cleanup actions will be taken.

.PARAMETER restartServices
Flag telling the script to STOP and START YSOFT SAFEQ services during script operation.  
It is strongly recommended to use this flag in conjunction with the 'backupBinaries' flag
as some binaries will fail to be copied due to permission conflicts with running services.

.PARAMETER Debug
Flag telling the script to print additional debugging information.

.PARAMETER Verbose
Flag telling the script to print context information to the shell.

.INPUTS
None. You cannot pipe objects to SafeQBackup.ps1.

.OUTPUTS
None. Status progress to the shell only. SafeQBackup.ps1 does not generate any output objects
which can be piped to other operations.

.EXAMPLE
C:\PS> .\SafeQBackup.ps1 -backupDb -userName "postgres" -password "postgres" -backupDir "C:\SafeQ_Backups\Daily\" -maxRollCount 7 

.EXAMPLE
C:\PS> .\SafeQBackup.ps1 -backupDb -backupConfig -backupBinaries -userName "postgres" -password "postgres" -backupDir "C:\SafeQ_Backups\Weekly\" -maxRollCount 10

.EXAMPLE
C:\PS> .\SafeQBackup.ps1 -backupConfig -backupBinaries -Debug -Verbose
#>

param(
	[parameter(Mandatory=$true)]
	  [string]$backupDir,
	[parameter(Mandatory=$false)]
	  [switch]$backupDb=$false,
	[parameter(Mandatory=$false)]
	  [switch]$backupConfig,
	[parameter(Mandatory=$false)]
	  [switch]$backupBinaries,
	[parameter(Mandatory=$false)]
	  [string]$userName="postgres",
	[parameter(Mandatory=$false)]
	  [SecureString]$password,
	[parameter(Mandatory=$false)]
	  [int]$maxRollCount=3,
	[parameter(Mandatory=$false)]
	  [switch]$restartServices,
	[parameter(Mandatory=$false)]
	  [switch]$myDebug=$PSBoundParameters.Debug,
	[parameter(Mandatory=$false)]
	  [switch]$myVerbose=$PSBoundParameters.Verbose
)

#
# PARAMETER validation
#
if($myDebug){
	if (-not ([string]::IsNullOrEmpty($backupDir))){
		Write-Host "backupDir is set to: $backupDir"
	}
	if ($backupDb){
		Write-Host "backupDB value is: $backupDb"
	}
	if ($backupConfig){
		Write-Host "backupConfig is set to: $backupConfig"
	}
	if ($backupBinaries){
		Write-Host "backupBinaries is set to: $backupBinaries"
	}
	if (-not ([string]::IsNullOrEmpty($userName))){
		Write-Host "userName is set to: $userName"
	}
	if (-not ([string]::IsNullOrEmpty($password))){
		Write-Host "password is set to: $password"
	}
	if ($maxRollCount -gt 0){
		Write-Host "maxRollCount is set to: $maxRollCount"
	}
	if ($restartServices){
		Write-Host "restartServices is set to: $restartServices"
	}
	if ($myVerbose){
		Write-Host "Verbose is set to: $myVerbose"
	}
	Write-Host "Debug is set to: $myDebug"
}



#
# Internal variables
#
#$user = "postgres"
#$password = "admin"
$dbs = "SQDB6","SQDB6_IMS","SQDB6_YPS"
$pg_dump = $env:SAFEQ_HOME + '\PGSQL\bin\pg_dump.exe'
$psql = $env:SAFEQ_HOME + '\PGSQL\bin\psql.exe'
$restartServices = 0 # set to 1 if you want services stopped. Dangerous without making this script more bulletproof!
$timeStamp = (Get-Date).ToString('yyyy-MM-dd_hhmm_ss')
$backupfolder = $env:USERPROFILE + '\Desktop\YSQ_backup_' + $timeStamp
$path = Get-WmiObject Win32_Service |
	Where-Object Name -Like "YSoft*" | 
	Select-Object -ExpandProperty "PathName" | 
	Foreach-Object {(-split $_)[0].Trim("`"") -replace "\\SafeQ6\\.*", "\SafeQ6\"} | 
	Measure-Object -Minimum | 
	Select-Object -ExpandProperty "Minimum"




#
# HELPER FUNCTIONS
#
Function TestDB([String]$db){
	$MyServer = "127.0.0.1"
	$MyPort  = "5433"
	$MyDB = "pg_database"
	#$MyUid = "postgres"
	#$MyPass = "wR7/|RSIB+,qao"
	
	$pcmd = "SELECT 1 AS result FROM pg_database WHERE datname='$db';"
	try{
		$queryResult = & $psql -p $MyPort -U $userName -c $pcmd
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

Function createBackupConf($backupfolder) {
$confBackupFolder = $backupfolder + "\Conf-Files"
if (Test-Path $path"Management\conf") {
	New-Item -Path $confBackupFolder"\Management\conf" -Type directory | Out-Null
	Copy-Item $path"Management\conf\*" $confBackupFolder"\Management\conf\" -Recurse
	}
if (Test-Path $path"Management\ims") {
	New-Item -Path $confBackupFolder"\Management\ims" -Type directory | Out-Null
	Copy-Item $path"Management\ims\application.properties" $confBackupFolder"\Management\ims\"
	}
if (Test-Path $path"Management\tomcat\conf") {
	New-Item -Path $confBackupFolder"\Management\tomcat\conf" -Type directory | Out-Null
	Copy-Item $path"Management\tomcat\conf\*" $confBackupFolder"\Management\tomcat\conf\" -Recurse
	}
if (Test-Path $path"Management\validator\conf") {
	New-Item -Path $confBackupFolder"\Management\validator\conf" -Type directory | Out-Null
	Copy-Item $path"Management\validator\conf\*" $confBackupFolder"\Management\validator\conf\" -Recurse
	}
if (Test-Path $path"Management\PGSQL-data\") {
	New-Item -Path $confBackupFolder"\Management\PGSQL-data\" -Type directory | Out-Null
	Copy-Item $path"Management\PGSQL-data\*.conf" $confBackupFolder"\Management\PGSQL-data\" -Recurse
	}
if (Test-Path $path"SPOC\conf") {
	New-Item -Path $confBackupFolder"\SPOC\conf" -Type directory | Out-Null
	Copy-Item $path"SPOC\conf\*" $confBackupFolder"\SPOC\conf\" -Recurse
	}
if (Test-Path $path"SPOC\EUI\conf") {
	New-Item -Path $confBackupFolder"\SPOC\EUI\conf" -Type directory | Out-Null
	Copy-Item $path"SPOC\EUI\conf\*" $confBackupFolder"\SPOC\EUI\conf\" -Recurse
	}
if (Test-Path $path"SPOC\EUI\ui-conf") {
	New-Item -Path $confBackupFolder"\SPOC\EUI\ui-conf" -Type directory | Out-Null
	Copy-Item $path"SPOC\EUI\ui-conf\*" $confBackupFolder"\SPOC\EUI\ui-conf\" -Recurse
	}
if (Test-Path $path"SPOC\tomcat\conf") {
	New-Item -Path $confBackupFolder"\SPOC\tomcat\conf" -Type directory | Out-Null
	Copy-Item $path"SPOC\tomcat\conf\*" $confBackupFolder"\SPOC\tomcat\conf\" -Recurse
	}
if (Test-Path $path"SPOC\terminalserver") {
	New-Item -Path $confBackupFolder"\SPOC\terminalserver" -Type directory | Out-Null
	Copy-Item $path"SPOC\terminalserver\*.config" $confBackupFolder"\SPOC\terminalserver\" -Recurse
	}
if (Test-Path $path"FSP\Service") {
	New-Item -Path $confBackupFolder"\FSP\Service" -Type directory | Out-Null
	Copy-Item $path"FSP\Service\configuration.bin" $confBackupFolder"\FSP\Service\"
	Copy-Item $path"FSP\Service\*.config" $confBackupFolder"\FSP\Service\" -Recurse
	}
if (Test-Path $path"WPS") {
	New-Item -Path $confBackupFolder"\WPS" -Type directory | Out-Null
	Copy-Item $path"WPS\*.config" $confBackupFolder"\WPS\" -Recurse
	}
if (Test-Path $path"YPS\conf") {
	New-Item -Path $confBackupFolder"\YPS\conf" -Type directory | Out-Null
	Copy-Item $path"YPS\conf\*" $confBackupFolder"\YPS\conf\" -Recurse
	}
if (Test-Path $path"YPS\ysoft") {
	New-Item -Path $confBackupFolder"\YPS\ysoft" -Type directory | Out-Null
	Copy-Item $path"YPS\ysoft\*" $confBackupFolder"\YPS\ysoft\" -Recurse
	}
if (Test-Path $path"PGSQL-data") {
	New-Item -Path $confBackupFolder"\PGSQL-data" -Type directory | Out-Null
	Copy-Item $path"PGSQL-data\*.conf" $confBackupFolder"\PGSQL-data\" -Recurse
	}
if (Test-Path $path"MPS\Service\conf") {
	New-Item -Path $confBackupFolder"\MPS\Service\conf" -Type directory | Out-Null
	Copy-Item $path"MPS\Service\conf\*" $confBackupFolder"\MPS\Service\conf\" -Recurse
	Copy-Item $path"MPS\Service\*.config" $confBackupFolder"\MPS\Service\" -Recurse
	}
if (Test-Path $path"AP\bin\connector") {
	New-Item -Path $confBackupFolder"\AP\bin\connector" -Type directory | Out-Null
	Copy-Item $path"AP\bin\connector\ConnectorService.exe.config" $confBackupFolder"\AP\bin\connector" -Recurse
	Copy-Item $path"AP\bin\connector\services\MdnsService.xml" $confBackupFolder"\AP\bin\connector" -Recurse
	}
}

Function createBackupBinaries($backupfolder) {
$binBackupFolder = $backupfolder + "\Binaries"
if (Test-Path $path"Management\bin") {
	New-Item -Path $binBackupFolder"\Management\bin" -Type directory | Out-Null
	Copy-Item $path"Management\bin\*" $binBackupFolder"\Management\bin\" -Recurse
	}
if (Test-Path $path"Management\dbsync") {
	New-Item -Path $binBackupFolder"\Management\dbsync" -Type directory | Out-Null
	Copy-Item $path"Management\dbsync\*" $binBackupFolder"\Management\dbsync\" -Recurse
	}
if (Test-Path $path"Management\ldapreplicator") {
	New-Item -Path $binBackupFolder"\Management\ldapreplicator" -Type directory | Out-Null
	Copy-Item $path"Management\ldapreplicator\*" $binBackupFolder"\Management\ldapreplicator\" -Recurse
	}
if (Test-Path $path"Management\libs") {
	New-Item -Path $binBackupFolder"\Management\libs" -Type directory | Out-Null
	Copy-Item $path"Management\libs\*" $binBackupFolder"\Management\libs\" -Recurse
	}
if (Test-Path $path"Management\utilities") {
	New-Item -Path $binBackupFolder"\Management\utilities" -Type directory | Out-Null
	Copy-Item $path"Management\utilities\*" $binBackupFolder"\Management\utilities\" -Recurse
	}
if (Test-Path $path"SPOC\bin") {
	New-Item -Path $binBackupFolder"\SPOC\bin" -Type directory | Out-Null
	Copy-Item $path"SPOC\bin\*" $binBackupFolder"\SPOC\bin\" -Recurse
	}
if (Test-Path $path"SPOC\drivers") {
	New-Item -Path $binBackupFolder"\SPOC\drivers" -Type directory | Out-Null
	Copy-Item $path"SPOC\drivers\*" $binBackupFolder"\SPOC\drivers\" -Recurse
	}
if (Test-Path $path"SPOC\extensions") {
	New-Item -Path $binBackupFolder"\SPOC\extensions" -Type directory | Out-Null
	Copy-Item $path"SPOC\extensions\*" $binBackupFolder"\SPOC\extensions\" -Recurse
	}
if (Test-Path $path"SPOC\libs") {
	New-Item -Path $binBackupFolder"\SPOC\libs" -Type directory | Out-Null
	Copy-Item $path"SPOC\libs\*" $binBackupFolder"\SPOC\libs\" -Recurse
	}
if (Test-Path $path"SPOC\terminalserver") {
	New-Item -Path $binBackupFolder"\SPOC\terminalserver" -Type directory | Out-Null
	Copy-Item $path"SPOC\terminalserver\*" $binBackupFolder"\SPOC\terminalserver\" -Recurse
	}
if (Test-Path $path"SPOC\server") {
	New-Item -Path $binBackupFolder"\SPOC\server" -Type directory | Out-Null
	Copy-Item $path"SPOC\server\*" $binBackupFolder"\SPOC\server\" -Recurse
	}
if (Test-Path $path"SPOC\utilities") {
	New-Item -Path $binBackupFolder"\SPOC\utilities" -Type directory | Out-Null
	Copy-Item $path"SPOC\utilities\*" $binBackupFolder"\SPOC\utilities\" -Recurse
	}
if (Test-Path $path"SPOC\versions") {
	New-Item -Path $binBackupFolder"\SPOC\versions" -Type directory | Out-Null
	Copy-Item $path"SPOC\versions\*" $binBackupFolder"\SPOC\versions\" -Recurse
	}
}


#
# STOP services
#
if ($restartServices) { 
		if($myVerbose){
			Write-Host "Stopping YSoft services"
			Get-Service *YSoft* | Where-Object {$_.Name -ne 'YSoftPGSQL' -and $_.Name -ne 'YYSoftPGSQL' -and $_.Name -ne 'YSoftEtcd'} | Stop-Service
		}
		else {
			Get-Service *YSoft* | Where-Object {$_.Name -ne 'YSoftPGSQL' -and $_.Name -ne 'YYSoftPGSQL' -and $_.Name -ne 'YSoftEtcd'} | Stop-Service -WarningAction silentlyContinue
		}
	}



#
# Validate output directory
#
if($backupDb -Or $backupConfig -Or $backupBinaries){
	if($myVerbose){Write-Host "Validating Backup Directory"}
	
	#Checking to verify that the path provided is a valid path and directory
	If(Test-Path -Path $backupDir -PathType Container){ 
			Try
			{
				$backupfolder = $backupDir + '\' + $timeStamp
				if($myVerbose){
					New-Item -ItemType Directory -Force -Path $backupfolder -ErrorAction stop
					Write-Host "Backup will be written to: $backupfolder"
				} else {
					New-Item -ItemType Directory -Force -Path $backupfolder -ErrorAction stop | out-null
				}
			}
			Catch
			{
				Throw "$backupDir was not found and script is unable to force directory creation!"
				break
			} 
	} Else {
		if($myVerbose){ Write-Host "$backupDir was not valid! Using $backupfolder." }
		$backupfolder = $backupfolder + '\' + $timeStamp
		if($myVerbose){
			New-Item -ItemType Directory -Force -Path $backupfolder -ErrorAction stop
		} else {
			New-Item -ItemType Directory -Force -Path $backupfolder -ErrorAction stop | out-null
		}
	}
}
Else {
	Write-Host "No valid backup flag has been set.  Please specify one or more of the following: -backupDB, -backupConfig, or -backupBinaries."
	Exit(-1)
}

#
# BACKUP Database
# 
if($backupDb) { 
	if($myVerbose){Write-Host "Beginning DB Backup Process"}
	set-item -force -path env:PGPASSWORD -value $password
	
	Foreach ($db in $dbs) {
		$outfile = $backupfolder + '\' + $timeStamp + '___' +  $db
		
		Try
		{
			$validDB = TestDB($db)
			#if($myVerbose){Write-Host "TestDB returned $validDB"}
			if($validDB) {
				if($myVerbose){Write-Host "Backing up $db"}
				& $pg_dump -Fc -p 5433 -U $userName -f $outfile $db
			} Else {
				if($myDebug){Write-Host "$db was not found."}
			}
		}
		Catch
		{
			if($myVerbose){Write-Host "Some problem, could not back up $db"}
		}
	}
	
	set-item -force -path env:PGPASSWORD -value $null
	if($myVerbose){Write-Host "Finished DB Backup Process"}
}


#
# CONFIG Files
#
if ($backupConfig) { 
	if($myVerbose){Write-Host "Beginning backupConfig section"}
	createBackupConf($backupfolder)
	if($myVerbose){Write-Host "Completed backupConfig section"}
}



#
# BINARIES Files
#
if ($backupBinaries) { 
	if($myVerbose){Write-Host "Beginning backupBinaries section"}
	createBackupBinaries($backupfolder)
	if($myVerbose){Write-Host "Completed backupBinaries section"}
}


#
# START services
#
if ($restartServices) { 
	if($myVerbose){
		Write-Host "Restarting YSoft services"
		Get-Service *YSoft* | Where-Object {$_.Name -ne 'YSoftSQ-SPOCGS'} | Start-Service 
	}
	else {
		Get-Service *YSoft* | Where-Object {$_.Name -ne 'YSoftSQ-SPOCGS'} | Start-Service -WarningAction silentlyContinue
	}
}



#
# DELETE OLD BACKUP
#
if($maxRollCount -gt 0){
	if($myVerbose){Write-Host "Beginning Removal of old DB backups"}

	$files_to_keep = Get-ChildItem -Path $backupDir | 
		Where-Object { $_.PsIsContainer } |
		Sort-Object LastWriteTime -Descending |
		Select-Object -first $maxRollCount
	if($myVerbose){Write-Host "Files to be kept:"}	
	if($myVerbose){Write-Host $files_to_keep}

	Get-Childitem $backupDir -exclude $files_to_keep | foreach ($_) {remove-item $_.fullname -Recurse}

	if($myVerbose){Write-Host "Finished removal old DB backups"}
}

#
# Usage
#
#---------------------------------
# Daily
#.\SafeQBackup.ps1 -backupDb -password "wR7/|RSIB+,qao" -backupDir "C:\SafeQ_Backups\Daily\" -maxRollCount 7
#
# Weekly
#.\SafeQBackup.ps1 -backupDb -backupWarehouse -backupConfig -backupBinaries -password "wR7/|RSIB+,qao" -backupDir "C:\SafeQ_Backups\Weekly\" -maxRollCount 10
	