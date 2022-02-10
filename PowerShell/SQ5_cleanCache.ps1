<#
.SYNOPSIS
    YSoft SafeQ 5 clean cache utility
.DESCRIPTION
    Script helps to refresh the cache of an ORS.
.EXAMPLE
    Run the script as an administrator using PowerShell.
#>

Param (
    [Parameter(Mandatory=$false)][string]$timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss"),
    [Parameter(Mandatory=$false)][string]$safeq5 = "C:\SafeQORS"
     )

#Stop YSoft SafeQ service
Write-Output ((Get-Date).ToString("HH:mm:ss") + " Press Enter to stop YSoft SafeQ ORS services...")
Read-Host

Stop-Service YSoftSafeQORS -passThru -Force -ErrorAction SilentlyContinue

Write-Output ((Get-Date).ToString("HH:mm:ss") + " Services stopped")

#Backup directories in question
Write-Output ((Get-Date).ToString("HH:mm:ss") + " Renaming cache directory")
Rename-Item -Path $safeq5\server\cache -NewName $timestamp"_cache_backup"
Write-Output ((Get-Date).ToString("HH:mm:ss") + " Renaming cache directory finished")

try 
    {Write-Output ((Get-Date).ToString("HH:mm:ss") + " Starting ORS service.")
    Start-Service YSoftSafeQORS
    }

    catch
        {Throw "Starting YSoftSafeQORS service has failed, terminating"
        }

    finally
        {
        }

try
    {Start-Sleep -Seconds 10
    [xml]$remoteConf= get-content $safeq5\conf\remoteConfImg.xml
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
            Write-Output ((Get-Date).ToString("HH:mm:ss") + " Waiting for SPOC to complete cache recovery")
        }

Write-Output ((Get-Date).ToString("HH:mm:ss") + " CACHE CLEANED")
