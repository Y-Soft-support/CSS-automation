<#
.SYNOPSIS
    YSoft SafeQ 6 event detection and notification utility.

.DESCRIPTION
    Script verifies the monitored log file and will send a notification in case the event was detected.
    The detected events are registered in an event.log file with a timestamp of when it was detected.
    
.PARAMETER MONITORED_LOG
    Defines the log source for the monitored event.

.PARAMETER MONITORED_EVENT
    Determines what message is verified in the log files.

.PARAMETER LOG_LINES
    Defines number of log files lines that could contain the information about the device name in the affected thread

.PARAMETER SMTP

.PARAMETER FROM
    Defines the sender of the message.

.PARAMETER TO
    Defines the receiver of the message.

.EXAMPLE
    Schedule a task to run in 10 minutes intervals.
#>

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

$MONITORED_LOG = "C:\SafeQ6\SPOC\logs\spoc.log"
$EVENT_LOG = "C:\SafeQ6\event.log"
$MONITORED_EVENT = "Owner of the job cannot be recognized - accounted as unknown user and device cost-center."
$LOG_LINES = 100

$SMTP = "smtp.gmail.com"
$FROM = "Event Monitor <event_monitor@safeq.com>"
$TO = "safeq@safeq.com"

$SUBJECT = "ALERT: Monitored event detected"
$HEADER = "Dear Admin, `n
The monitored event has been detected: `n"
$FOOTER = "`n Please proceed as recommended. `n
`n
Thank you.`n
Event Monitor"

#-----------------------------------------------------------[Functions]-----------------------------------------------------------

function Write-LogMessage([String] $message, [String] $severity='INFO') {
    $timeStamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss,fff")

    # Log structure
    if($EVENT_LOG) {
        "$timeStamp | $($severity.PadRight(8, ' ')) | $message" | Out-File -FilePath $EVENT_LOG -Append
    }
}

function Get-ThreadName([String] $message) {
    # The fourth information in the log is the thread name
    $threadName = $message -split "\s+" | Select-Object -Skip 3 | Select-Object -First 1
    $threadNameClean = $threadName.Trim('|')

    return $threadNameClean
}

function Get-DeviceName($log, $pattern) {
    # Get line with a thread name and getDeviceById
    $logLine = $log -split "\n" | Where-Object { $_ -match "getDeviceById" -and $pattern } | Select-Object -First 1
    
    # The specific device name is available between name=' AND  ', description
    $deviceName = GetStringBetweenTwoStrings "name='" "', description" $logLine

    return $deviceName
}

function GetStringBetweenTwoStrings( $firstString, $secondString, $data ) {

    #Regex pattern to compare two strings
    $pattern = "$firstString(.*?)$secondString"

    #Perform the opperation
    $result = [regex]::Match($data,$pattern).Groups[1].Value

    #Return result
    return $result
}

function detectEvents ( $occurence=$null, $existingOccurence=$null ) {
    if ( $null -ne $occurence ) {
        if ( $null -eq $existingOccurence ) {
            # Get log extract with additional log lines
            $logExtract = Get-Content -Path $MONITORED_LOG | Select-String -Pattern $($occurence) -CaseSensitive -SimpleMatch -Context 0, $LOG_LINES
            # Extract the affected device name
            $affectedDevice = Get-DeviceName $logExtract ( Get-ThreadName $occurence )

            # Log event occurence
            Write-LogMessage "Event detected: $($occurence)" "DEBUG"
            Write-LogMessage "Device affected: $($affectedDevice)" "DEBUG"

            # update event list
            $eventList[$affectedDevice] = $occurence
        }
    }
}

function prepareEmail () {
    $allOccurrences = "`n"
    $counter = 0
    $eventList.GetEnumerator() | ForEach-Object{
        $counter += 1
        $newEvent = "NEW EVENT $($counter)"
        $newLine = "$($newEvent)`nAffected device: {0}`nLog message: {1}`n`n" -f $_.key, $_.value
        $allOccurrences = $allOccurrences + $newLine
    }
            
    $email = $HEADER + "$($allOccurrences)" + $FOOTER

    return $email
}

#-----------------------------------------------------------[Execution]-----------------------------------------------------------

Write-LogMessage "Event detection has started. Looking for a new event occurence in: $($MONITORED_LOG)"
$alertResult = "No new occurence detected."

# Create event log if it does not exists
$isEventLog = Test-Path $EVENT_LOG
if (-Not $isEventLog) {New-Item -ItemType "file" -Path $EVENT_LOG | Out-Null}

# Parse log file for the monitored event
$detectedEvents = Get-Content -Path $MONITORED_LOG | Select-String -Pattern $MONITORED_EVENT -CaseSensitive -AllMatches

# Detect new occurences in the log file.
$eventList = @{}
foreach ($item in $detectedEvents) {
    $isEventAlreadyDetected = $null
    $isEventAlreadyDetected = Get-Content -Path $EVENT_LOG | Select-String -Pattern $item -CaseSensitive -SimpleMatch
    if ($null -ne $item) {
        detectEvents $item $isEventAlreadyDetected
    }
}

# Switch result state
if ($eventList.count -gt 0) {
    $alertResult = "$($eventList.count) new occurence(s) detected!"
}

Send-MailMessage -From $FROM -To $TO -Subject $SUBJECT -Body (PrepareEmail) -SmtpServer $SMTP      

Write-LogMessage "Event detection has finished with a result: $($alertResult)"
