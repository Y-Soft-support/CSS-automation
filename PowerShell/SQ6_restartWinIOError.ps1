<#
.SYNOPSIS
    YSoft SafeQ 6 exception restart utility
.DESCRIPTION
    Set SafeQ variable first
    Script helps to restart a YSoft SafeQ service on a certain condition
    Schedule a task to run in intervals
    It is recommended to 
.EXAMPLE
    Run the script as Adminstrator from PowerShell.
#>
Param (
    [Parameter(Mandatory=$false)][string]$folder = 'C:\SafeQ6\MPS\logs\',
    [Parameter(Mandatory=$false)][string]$logDir = ('mps-WinIOError_'+(Get-Date).ToString("yyyy-MM-dd")+'.log' )
     )


# folder for logging, path to log to check
$path=$folder+'\mps.log'

$logFile = $folder+'\'+$logDir

if (-not (Test-Path $logFile))
    { New-Item -Path $logFile -ItemType File
    }

function logToFile
    {$message=(Write-Output ((Get-Date).ToString("yyyy-MM-dd_HH:mm:ss")) $args[0])

    Add-Content -Path $logFile -Value $message
    }

function checkMatch
    {[array]::Reverse($filecontents)

    $logMatch = $filecontents | Where-Object { $_ -match 'EXCEPTION: System.IO.IOException: The process cannot access the file' } | Select-Object -First 1
    
    if ($logMatch.length -gt 3)
        {Get-Service YSoftSQ-MPS | Stop-Service -passThru -Force -ErrorAction SilentlyContinue

        $newname = ("mps."+((Get-Date).ToString("yyyy-MM-dd_HH-mm-ss"))+".log")

        Rename-Item -Path $path -NewName $newname

        if (Get-Service YSoftSQ-MPS | Where-Object {$_.Status -ne "Stopped"})
            {Throw "YSoft SafeQ Mobile Print Server service is still running, try to stop it manually and then start the script again." | logToFile
            }

        # start YSoft SafeQ MPS service.
        try
        {Get-Service YSoftSQ-MPS | Start-Service
        }
    
            catch
                {Throw "Starting YSoft SafeQ Mobile Print Server service has failed, terminating. Please try it again manually." | logToFile
                }

            finally
                {logToFile " FINISHED - MPS service restarted due to SystemIOException."
                }
        }

        else
            {logToFile " FINISHED - SystemIOException not found."
            }
    }


# loop through the log

$fp = 0

while ($true)
{
	$fs = [System.IO.File]::Open( ( Resolve-Path $path ), [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)

	$filesize = $fs.Length
	Write-Host "File size: $($filesize)"

	# check if the file has rolled over. If it has then start over
	if ($fp -gt $filesize)
	{
		$fp = 0
	}

	# has the file changed
	if ($fp -lt $filesize)
	{
		# roll $fp back a bit in case the last read split the text we are looking for
		if ($fp -gt 1000)
		{
			$fp = $fp - 1000
		}

		$databuffer = New-Object Byte[] 100000
		$fp = $fs.Seek($fp, [System.IO.SeekOrigin]::Begin)
		$fp = $fp + $fs.Read($databuffer, 0, 100000)
		

		$filecontents = [System.Text.Encoding]::ASCII.GetString($databuffer)
		# look for the exception in $filecontents
        checkMatch $filecontents

		# output $filecontents as an example
		$filecontents
		Write-Host "Done"
	}
	$fs.Dispose()

	Start-Sleep -Seconds 60
}