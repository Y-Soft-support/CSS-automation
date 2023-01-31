
# Get server name and IP
$CNAME = [System.Net.Dns]::GetHostName()
$IPx = [System.Net.Dns]::GetHostAddresses($CNAME) |
       Where-Object { $_.AddressFamily -eq "InterNetwork" }

# How many ports to create
$portPrefix = "SAFEQ"
$numberOfPorts = Read-Host "How many ports would you like to create?"


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
