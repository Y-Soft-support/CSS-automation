<#
.SYNOPSIS
    YSoft SafeQ 6 clean cache utility
.DESCRIPTION
    Script helps to refresh the cache of a Spooler Controller.
.EXAMPLE
    Run the script as Adminstrator from PowerShell.
#>

Param (
    [Parameter(Mandatory=$false)][string]$timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss"),
    [Parameter(Mandatory=$false)][string]$safeq6 = "C:\SafeQ6"
     )

#Stop YSoft SafeQ services
Write-Output ((Get-Date).ToString("HH:mm:ss") + " Press Enter to stop YSoft SafeQ SPOC and FSP services...")
Read-Host

Stop-Service YSoftSQ-SPOC -passThru -Force -ErrorAction SilentlyContinue
Stop-Service YSoftSQ-FSP -passThru -Force -ErrorAction SilentlyContinue

Write-Output ((Get-Date).ToString("HH:mm:ss") + " Services stopped")

#Backup directories in question
Write-Output ((Get-Date).ToString("HH:mm:ss") + " Renaming cache directory")
Rename-Item -Path $safeq6\SPOC\SpoolCache -NewName $timestamp"_cache_backup"
Write-Output ((Get-Date).ToString("HH:mm:ss") + " Renaming cache directory finished")

try 
    {Write-Output ((Get-Date).ToString("HH:mm:ss") + " Starting SPOC service.")
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
    [xml]$remoteConf= get-content $safeq6\SPOC\conf\remoteConfImg.xml
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

try 
    {Write-Output ((Get-Date).ToString("HH:mm:ss") + " Starting FSP service.")
    Start-Service YSoftSQ-FSP
    }

    catch
        {Throw "Starting YSoftSQ-FSP service has failed, terminating"
        }

    finally
        {
        }

Write-Output ((Get-Date).ToString("HH:mm:ss") + " CACHE CLEANED")