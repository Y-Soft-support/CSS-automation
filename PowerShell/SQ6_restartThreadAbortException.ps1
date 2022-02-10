<#
.SYNOPSIS
    YSoft SafeQ 6 exception restart utility
.DESCRIPTION
    Script helps to restart a Terminal Server service on a certain condition
    Schedule a task to run in intervals
    It is recommended to 
.EXAMPLE
    Run the script as Adminstrator from PowerShell.
#>

#Check SafeQ variable or set if required and clear exception variable
if (-not (Test-Path env:SAFEQ6)) { $env:SAFEQ6 = Read-Host "SafeQ path variable not found please enter the path (e.g.: C:\SafeQ6):" }
Write-Output ((Get-Date).ToString("HH:mm:ss") + " SafeQ path variable set.")


#Parse log for ThreadAbortException exception
$tslog = Get-Content -Encoding String -Path $env:SAFEQ6\SPOC\terminalserver\logs\terminalserver.log
[array]::Reverse($tslog)
$tslogMatch = $tslog | Where-Object { $_ -match 'ThreadAbortException' } | Select-Object -First 1


#Stop YSoft SafeQ TS service if exception was found
if ($tslogMatch.length -gt 3)
    {Get-Service YSoftSQ-TS | Stop-Service -passThru -Force -ErrorAction SilentlyContinue
    if (Get-Service YSoftSQ-TS | Where-Object {$_.Status -ne "Stopped"})
        {Throw "YSoft SafeQ Terminal Service is still running, try to stop them manually and then start the script again."
        }

    #Start YSoft SafeQ TS service.
    try
       {Get-Service YSoft*TS, YSoft*TerminalServer | Start-Service
       }
    
        catch
            {Throw "Starting YSoft SafeQ Terminal Server service has failed, terminating. Please try it again manually and then start all the remaining services."
            }

        finally
            {Write-Output ((Get-Date).ToString("HH:mm:ss") + " FINISHED - Terminal Server service restarted.")
            }
    }

    else
        {Write-Output ((Get-Date).ToString("HH:mm:ss") + " FINISHED - ThreadAbortException not found.")
        }
    