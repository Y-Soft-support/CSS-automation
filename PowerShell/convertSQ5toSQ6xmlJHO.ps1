$file = "c:\temp\xml\YSoftSafeQSettings_orig.xml"
$destination = "c:\temp\xml\Sq5ConvertedFromSq6.xml"
$open = "<value>"
$close = "</value>"
$openReplace = "<value><![CDATA["
$closeReplace = "]]></value>"
$pattern = "<?xml|<configuration|<properties|<property|<key|<value|</property|</properties|</configuration"

# Opening value
$content = [System.IO.File]::ReadAllText($file).Replace($open,$openReplace)
[System.IO.File]::WriteAllText($destination, $content)

# Closing value
$content = [System.IO.File]::ReadAllText($destination).Replace($close,$closeReplace)
[System.IO.File]::WriteAllText($destination, $content)

# Keep only <property><key><value></property> structure, remove all other
(Get-Content $destination) | Where-Object { $_ -match $pattern } | Set-Content $destination

# Update major attributes properties
$first = "<configuration>"
$firstReplace = "<configuration><properties>"
$last = "</configuration>"
$lastReplace = "</properties></configuration>"

$content = [System.IO.File]::ReadAllText($destination).Replace($first,$firstReplace)
[System.IO.File]::WriteAllText($destination, $content)

$content = [System.IO.File]::ReadAllText($destination).Replace($last,$lastReplace)
[System.IO.File]::WriteAllText($destination, $content)
