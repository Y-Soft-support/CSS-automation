<#
.SYNOPSIS
   YSoft SAFEQ 6 SPOC group restart and cache deletion script
 
.DESCRIPTION
   Script helps to reinitialize the SPOC / SPOC group by cache deletion.
   - It automates the steps described in the documentation.
   - The old SPOC cache, the old log files (SPOC, Terminal Server) can be found in the original location with suffix _backup_<datetime> . You can delete them if you do not need them for later analysis.
 
   Run the script as follows:
   - Run the script on all members of a single SPOC group.
   - Follow on-scren instructions to stop SAFEQ services on all SPOC servers at once.
   - Once the script displays "To restart whole SPOC Group, …" on all the servers:
   -- follow on-screen instructions on one of the servers. Script will delete caches and start SAFEQ services.
   -- once the initialization of first server finishes, you may continue with initialization of another server (one by one).
   - Afterwards it is recommended to check that all services are really started.
    
   If the script fails on single node when restarting whole SPOC group, re-run the script on all nodes again.
 
   Script can be also used for a cache deletion on a standalone SPOC.
 
.EXAMPLE
   Run the PowerShell as Administrator, then launch the script in it.
 
.NOTES
  Version:        1.07
  Last Modified:  02/Mar/2022
#>
 
#-----------------------------------------------------------[Parameters]-----------------------------------------------------------
 
# Start TS service automatically when SPOC finishes cache recovery ($true) or wait for command from administrator ($false)
$tsautostart = $true
 
#-----------------------------------------------------------[Execution]------------------------------------------------------------
 
#Admin rights check
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(([System.Security.Principal.SecurityIdentifier]'S-1-5-32-544'))) {
    Write-Warning 'Administrative rights are missing. Please re-run the script as an Administrator.'
    Read-Host 'Press any key to exit the script'
    exit
}
 
#Check path and set it manually if required
$pm_sqdir = Get-ChildItem -Path HKLM:\SYSTEM\CurrentControlSet\Services | Where-Object {(($_ | Get-ItemProperty).PSChildName) -eq 'YSoftSQ-SPOC'}
if (!$pm_sqdir) {
    Read-Host 'Spooler Controller service not found. Terminating.'
    throw
}
$pm_sqdir = ($pm_sqdir | Get-ItemProperty).ImagePath.Split()[0].Trim('`"') -replace ('\\?bin\\wrapper.exe?','')
Write-Output ((Get-Date).ToString("HH:mm:ss") + " Spooler Controller path set to: $pm_sqdir")
 
#Stop YSoft SAFEQ services
Read-Host ((Get-Date).ToString("HH:mm:ss") + " Press Enter to stop YSoft SAFEQ services")
Write-Output ((Get-Date).ToString("HH:mm:ss") + " Stopping services")
 
Get-Service *YSoft* | Where-Object {$_.Name -ne 'YSoftPGSQL' -and $_.Name -ne 'YYSoftPGSQL' -and $_.Name -ne 'YSoftSQ-Management' -and $_.Name -ne 'YSoftSQ-LDAP' -and $_.Name -ne 'YSoftIms'} | Stop-Service -passThru -Force -ErrorAction SilentlyContinue
if (((( Get-Service *YSoft* | Where-Object {$_.Status -ne "Stopped"} | Where-Object {$_.Name -ne 'YSoftPGSQL' -and $_.Name -ne 'YYSoftPGSQL' -and $_.Name -ne 'YSoftSQ-Management' -and $_.Name -ne 'YSoftSQ-LDAP' -and $_.Name -ne 'YSoftIms'}) | Measure-Object ).Count) -gt 0)
{
    Throw "Some YSoft SAFEQ services are still running, try to stop them manually and then start the script again."
}
 
Write-Output ((Get-Date).ToString("HH:mm:ss") + " Services stopped")
Read-Host ((Get-Date).ToString("HH:mm:ss") + " To restart whole SPOC Group, stop services on all members of the group now. When done press any key to continue on one of the nodes")
 
#Backup directories
Write-Output ((Get-Date).ToString("HH:mm:ss") + " Renaming cache and log directory")
$pm_foldertorename = "$pm_sqdir\logs","$pm_sqdir\terminalserver\logs","$pm_sqdir\SpoolCache"
$timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
foreach ($pm_folder in $pm_foldertorename) {
    $pm_foldernewname = $pm_folder+"_backup_"+$timestamp
    Rename-Item -Path $pm_folder -NewName $pm_foldernewname -ErrorAction SilentlyContinue
    if (Test-Path $pm_foldernewname) {" Renamed: $pm_folder to $($pm_foldernewname.Split('\')[-1])"}
}
 
if(Test-Path -Path $pm_sqdir\SpoolCache ){
    Throw ((Get-Date).ToString("HH:mm:ss") + " Terminating as deleting cache has failed. Make sure all the services are stopped, then use the script again.")
}
else {
    Write-Output ((Get-Date).ToString("HH:mm:ss") + " Renaming cache and log directory finished")
}
 
#Start SPOC service and wait for initialization
try
{
    Write-Output ((Get-Date).ToString("HH:mm:ss") + " Starting YSoft SAFEQ SPOC service")
    Start-Service YSoftSQ-SPOC -ErrorAction Stop
}
catch
{
    Throw "Starting YSoftSQ-SPOC service has failed, terminating"
}
finally
{
}
 
try
{
    Write-Output ((Get-Date).ToString("HH:mm:ss") + " Waiting for $pm_sqdir\conf\remoteConfImg.xml to be created")
    do {Start-Sleep 2 } until (Test-Path $pm_sqdir\conf\remoteConfImg.xml)
    [xml]$remoteConf= get-content $pm_sqdir\conf\remoteConfImg.xml
    $pm_orsFailoverLockManager = $remoteConf.configuration.property | Where-Object {$_.key -eq 'orsFailoverLockManager'}
 
    if ($pm_orsFailoverLockManager.Value -eq 'true')
    {
        $pm_lookupstring = 'Download\sentities\sfinished\sfrom\sother\sORSes\sin\sNRG'
    }
 
    elseif ($pm_orsFailoverLockManager.Value -eq 'false')
    {
        $pm_lookupstring = 'End\sof\sprocessing\sof\sGetNewJobsByUsersResponseMessage'
    }
}
catch
{
    Throw "Error occurred while trying to verify configuration in remoteConfImg.xml, terminating"
}
finally
{
    if (-Not($pm_lookupstring))
    {
        Throw "Property orsFailoverLockManager not found in remoteConfImg.xml, terminating"
    }
    Write-Output ((Get-Date).ToString("HH:mm:ss") + " SPOC initialization in progress, please wait")
}
 
do
{
    Start-Sleep -Seconds 10
    $spocLog = Get-Content -Encoding String -Path $pm_sqdir\logs\spoc.log
    [array]::Reverse($spocLog)
    $spocLogMatch = $spocLog | Where-Object { $_ -match $pm_lookupstring } | Select-Object -First 1
}
until (($spocLogMatch | Measure-Object).Count -gt 0)
Write-Output ((Get-Date).ToString("HH:mm:ss") + " SPOC initialization finished.")
Write-Output ((Get-Date).ToString("HH:mm:ss") + " If you were restarting the whole SPOC group, you may continue with startup of the next SPOC group member.")
 
#Start TS service and wait for initialization
if ($tsautostart -eq $false) {
    Read-Host ((Get-Date).ToString("HH:mm:ss") + " Press Enter to start YSoft SAFEQ Terminal Server and other remaining services")
}
 
try
{
    Write-Output ((Get-Date).ToString("HH:mm:ss") + " Starting YSoft SAFEQ Terminal Server service")
    Get-Service YSoft*TS*, YSoft*TerminalServer | Start-Service -ErrorAction Stop
}
catch
{
    Throw "Starting YSoft SAFEQ Terminal Server service has failed, terminating. Please try it again manually and then start all the remaining services."
}
finally
{
    Write-Output ((Get-Date).ToString("HH:mm:ss") + " TS initialization in progress, please wait")
}
 
do
{
    Start-Sleep -Seconds 10
    $tslog = Get-Content -Encoding String -Path $pm_sqdir\terminalserver\logs\terminalserver.log
    [array]::Reverse($tslog)
    $tslogMatch = $tslog | Where-Object { $_ -match 'TS\sfully\sstarted' } | Select-Object -First 1
}
until (($tslogMatch | Measure-Object).Count -gt 0)
Write-Output ((Get-Date).ToString("HH:mm:ss") + " TS initialization finished")
        
 
#Start remaining services and wait for initialization
Write-Output ((Get-Date).ToString("HH:mm:ss") + " Starting any remaining YSoft SAFEQ services that were also stopped")
try
{
    Get-Service *YSoft* |  Where-Object {$_.ServiceName -ne 'YSoftSQ-SPOCGS'} | Start-Service -ErrorAction Stop
}
catch
{
    Write-Output ((Get-Date).ToString("HH:mm:ss") + " Startup of some additional YSoft SAFEQ services has failed. Make sure to start all remaining YSoft SAFEQ services manually.")
}
finally
{
    Write-Output ((Get-Date).ToString("HH:mm:ss") + " FINISHED - services are fully initialized." )
}