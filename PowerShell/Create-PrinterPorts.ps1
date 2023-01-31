<#
.SYNOPSIS
    A utility that creates printer ports in Windows.

.DESCRIPTION
    The script asks how many ports are to be created and creates as many ports as requested.
    The LPR port with IP address set to the local server and secure queue is created.
    It can be used to raise the number of ports in case it is run another time with a higher number of ports specified.
    
.PARAMETER portPrefix
    Defines the prefix of the port name. e.g. SAFEQ.
    The resulting name of the port is "SAFEQ_1:"

.PARAMETER numberOfPorts
    Defines the number of ports to be created.

.EXAMPLE
    With default configuration 5 printer ports are created.
#>

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

$portPrefix = "SAFEQ"
$numberOfPorts = 5

#-----------------------------------------------------------[Execution]-----------------------------------------------------------

# Get the hostname and IP address of the local server
$CNAME = [System.Net.Dns]::GetHostName()
$IPx = [System.Net.Dns]::GetHostAddresses($CNAME) |
       Where-Object { $_.AddressFamily -eq "InterNetwork" }

# Create as many ports as requested.
$i=1
for(;$i -le $numberOfPorts;$i++)
{
       $newPortName = "$($portPrefix)_$($i):"
       $checkpoint = Get-PrinterPort | Where-Object {$_.Name -eq $newPortName }
       if (-not $checkpoint ) {
              Add-PrinterPort -Name $newPortName -LprHostAddress $IPx -LprQueueName "secure" -LprByteCounting
              Write-Host "New port created: $newPortName"
       }
}
