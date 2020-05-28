<#
.SYNOPSIS
    YSoft SafeQ 6 Print Roaming Group (PRG) restart utility
.DESCRIPTION
    Script helps to restart a single Site Server from PRG.
    When it is required to restart the PRG run the script as follows:
     - First run requires setting up an environment variable SAFEQ6
     - Run the script on all members of one PRG.
     - Once run the script will stop all required services on a particular member of the PRG.
     - Synchronize all members of PRG to the following point "To restart whole Print Roaming Group, …"
     - Afterwards continue with only one member at a time until the script finishes.
     - Script will automatically start the services at the end.
    It is recommended to check that all services are really started.
.EXAMPLE
    Run the script as Adminstrator from PowerShell.
#>

Param (
    [Parameter(Mandatory=$false)][string]$timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
     )


#Check path and set if required
if (-not (Test-Path env:SAFEQ6)) { $env:SAFEQ6 = Read-Host "SafeQ path variable not found please enter the path (e.g.: C:\SafeQ6):" }
Write-Output ((Get-Date).ToString("HH:mm:ss") + " SafeQ path variable set.")

#Stop YSoft SafeQ services
Write-Output ((Get-Date).ToString("HH:mm:ss") + " Press Enter to stop YSoft SafeQ services...")
Read-Host
Write-Output ((Get-Date).ToString("HH:mm:ss") + " Stopping services")

Get-Service *YSoft* | Where-Object {$_.Name -ne 'YSoftPGSQL' -and $_.Name -ne 'YYSoftPGSQL' -and $_.Name -ne 'YSoftSQ-Management' -and $_.Name -ne 'YSoftSQ-LDAP' -and $_.Name -ne 'YSoftIms'} | Stop-Service -passThru -Force -ErrorAction SilentlyContinue

if (((( Get-Service *YSoft* | Where-Object {$_.Status -ne "Stopped"} | Where-Object {$_.Name -ne 'YSoftPGSQL' -and $_.Name -ne 'YYSoftPGSQL' -and $_.Name -ne 'YSoftSQ-Management' -and $_.Name -ne 'YSoftSQ-LDAP' -and $_.Name -ne 'YSoftIms'}) | Measure-Object ).Count) -gt 0)
    {Throw "Some YSoft SafeQ services are still running, try to stop them manually and then start the script again."
    }

    Write-Output ((Get-Date).ToString("HH:mm:ss") + " Services stopped")
    Write-Output ((Get-Date).ToString("HH:mm:ss") + " To restart whole Print Roaming Group, stop services on all members of the group now. When done press any key to continue...")
    Read-Host

#Backup directories in question
Write-Output ((Get-Date).ToString("HH:mm:ss") + " Renaming cache and log directories")
Rename-Item -Path $env:SAFEQ6\SPOC\logs -NewName $timestamp"_logs_backup" -ErrorAction SilentlyContinue
Rename-Item -Path $env:SAFEQ6\SPOC\terminalserver\logs -NewName $timestamp"_tslogs_backup" -ErrorAction SilentlyContinue
Rename-Item -Path $env:SAFEQ6\SPOC\SpoolCache -NewName $timestamp"_cache_backup"
Write-Output ((Get-Date).ToString("HH:mm:ss") + " Renaming cache and log directories finished")

try 
    {Write-Output ((Get-Date).ToString("HH:mm:ss") + " Starting services")
    Start-Service YSoftSQ-SPOC
    }

    catch
        {Throw "Starting YSoftSQ-SPOC service has failed, terminating"
        }

    finally
        {
        }

try
    {Start-Sleep -Seconds 10
    [xml]$remoteConf= get-content $env:SAFEQ6\SPOC\conf\remoteConfImg.xml
    $pm_orsFailoverLockManager = $remoteConf.configuration.property | Where-Object {$_.key -eq 'orsFailoverLockManager'}

    if ($pm_orsFailoverLockManager.Value -eq 'true')
        {$pm_lookupstring = 'Download\sentities\sfinished\sfrom\sother\sORSes\sin\sNRG'
        }

    elseif ($pm_orsFailoverLockManager.Value -eq 'false')
        {$pm_lookupstring = 'End\sof\sprocessing\sof\sGetNewJobsByUsersResponseMessage'
        }
    }

    catch
        {Throw "Error occurred while trying to verify configuration in remoteConfImg.xml, terminating"
        }

    finally
        {if (-Not($pm_lookupstring))
            {Throw "Property orsFailoverLockManager not found in remoteConfImg.xml, terminating"
            }
            Write-Output ((Get-Date).ToString("HH:mm:ss") + " Waiting for ORS to finish downloading of all data")
        }


do
    {Start-Sleep -Seconds 10
            $spocLog = Get-Content -Encoding String -Path $env:SAFEQ6\SPOC\logs\spoc.log
            [array]::Reverse($spocLog)
            $spocLogMatch = $spocLog | Where-Object { $_ -match $pm_lookupstring } | Select-Object -First 1
       }
    until (($spocLogMatch | Measure-Object).Count -gt 0)

    try
       {Get-Service YSoft*TS, YSoft*TerminalServer | Start-Service
       }
    
    catch
       {Throw "Starting YSoft SafeQ Terminal Server service has failed, terminating. Please try it again manually and then start all the remaining services."
       }

    finally
       {Write-Output ((Get-Date).ToString("HH:mm:ss") + " Waiting for Terminal Server to fully initialize")
       }

do
    {Start-Sleep -Seconds 10
    $tslog = Get-Content -Encoding String -Path $env:SAFEQ6\SPOC\terminalserver\logs\terminalserver.log
    [array]::Reverse($tslog)
    $tslogMatch = $tslog | Where-Object { $_ -match 'TS\sfully\sstarted' } | Select-Object -First 1
    }
    
    until (($tslogMatch | Measure-Object).Count -gt 0)
       

Write-Output ((Get-Date).ToString("HH:mm:ss") + " Starting any remaining YSoft SafeQ services that were also stopped")

try
    {Get-Service *YSoft* -passThru |  Where-Object {$_.ServiceName -notcontains "YSoftSQ-SPOCGS"} | Start-Service
    }

    catch
        {Write-Output ((Get-Date).ToString("HH:mm:ss") + " Startup of some additional YSoft SafeQ services has failed. Make sure to start all remaining YSoft SafeQ services manually.")
        }

    finally
        {Write-Output ((Get-Date).ToString("HH:mm:ss") + " FINISHED - Site Server and Terminal Server are fully initialized.")
        }
