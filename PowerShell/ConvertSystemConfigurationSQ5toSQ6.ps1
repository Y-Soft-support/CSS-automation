<#
.SYNOPSIS
  The script converts exported system configuration in XML from YSoft SafeQ 5 to YSoft SafeQ 6 format.
       
.DESCRIPTION
  The tool processes YSoftSafeQSettings_*.xml file exported from YSoft SafeQ 5.
  The file is converted into an XML that follows the standard of YSoft SafeQ 6.
  Upon the completion of the conversion the converted XML file is ready to be imported into YSoft SafeQ 6.

  The tool does not address
  
  PowerShell 3.0 or higher is required, current version can be listed by command: $PSVersionTable.PSVersion.Major
  The script must be launched using PowerShell as an Administrator
     
.PARAMETER originalFile
  Defines the path to the file with YSoft SafeQ 5 exported configuration
  Default value: "C:\temp\xml\YSoftSafeQSettings_original.xml"

.PARAMETER convertedFile
  Defines the path to the file ready to import to YSoft SafeQ 6
  Default value: "C:\temp\xml\YSoftSafeQSettings_converted.xml"

.NOTES
  Version:        1.0
  Creation Date:  29/12/2021
      
.EXAMPLE
  Run Windows PowerShell as an administrator and launch the command as follows:
  C:\Users\Administrator\Downloads> .\ConvertSystemConfigurationSQ5toSQ6.ps1
#>

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

$originalFile = "C:\temp\xml\YSoftSafeQSettings_original.xml"
$convertedFile = "C:\temp\xml\YSoftSafeQSettings_converted.xml"

# tag modifiers
$OPEN = "<value>"
$CLOSE = "</value>"
$SQ6_OPEN = "<value><![CDATA["
$SQ6_CLOSE = "]]></value>"
$PATTERN = "<?xml|<configuration|<properties|<property|<key|<value|</property|</properties|</configuration"

$FIRST = "<configuration>"
$SQ6_FIRST = "<configuration><properties>"
$LAST = "</configuration>"
$SQ6_LAST = "</properties></configuration>"

#-----------------------------------------------------------[Execution]-----------------------------------------------------------

# Opening value
$content = [System.IO.File]::ReadAllText($originalFile).Replace($OPEN,$SQ6_OPEN)
[System.IO.File]::WriteAllText($convertedFile, $content)

# Closing value
$content = [System.IO.File]::ReadAllText($convertedFile).Replace($close,$SQ6_CLOSE)
[System.IO.File]::WriteAllText($convertedFile, $content)

# Keep only <property><key><value></property> structure, remove all other
(Get-Content $convertedFile) | Where-Object { $_ -match $PATTERN } | Set-Content $convertedFile

# Update major attributes properties
$content = [System.IO.File]::ReadAllText($convertedFile).Replace($FIRST,$SQ6_FIRST)
[System.IO.File]::WriteAllText($convertedFile, $content)

$content = [System.IO.File]::ReadAllText($convertedFile).Replace($LAST,$SQ6_LAST)
[System.IO.File]::WriteAllText($convertedFile, $content)

#<?xml version="1.0" encoding="UTF-8"?>

Write-Host @"
The converted file is ready for import into YSoft SafeQ 6.
Location: $($convertedFile)
Press any key to continue...
"@ -foregroundcolor Green;

# The pause technique below is not supported in interpreters such as Visual Studio Code or even PowerShell ISE.
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
