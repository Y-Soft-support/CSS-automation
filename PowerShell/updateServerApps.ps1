function Set-DefaultBrowser
{
    param($defaultBrowser)

    $regKey      = "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\{0}\UserChoice"
    $regKeyFtp   = $regKey -f 'ftp'
    $regKeyHttp  = $regKey -f 'http'
    $regKeyHttps = $regKey -f 'https'

    switch -Regex ($defaultBrowser.ToLower())
    {
        # Internet Explorer
        'ie|internet|explorer' {
            Set-ItemProperty $regKeyFtp   -name ProgId IE.FTP
            Set-ItemProperty $regKeyHttp  -name ProgId IE.HTTP
            Set-ItemProperty $regKeyHttps -name ProgId IE.HTTPS
            break
        }
        # Google Chrome
        'cr|google|chrome' {
            Set-ItemProperty $regKeyFtp   -name ProgId ChromeHTML
            Set-ItemProperty $regKeyHttp  -name ProgId ChromeHTML
            Set-ItemProperty $regKeyHttps -name ProgId ChromeHTML
            break
        }
    } 

# thanks to http://newoldthing.wordpress.com/2007/03/23/how-does-your-browsers-know-that-its-not-the-default-browser/
}


# Install Chocolatey
try {
    choco upgrade chocolatey
}
catch {
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Start-Sleep 15
}


# Install required applications
choco install dotnet
choco install git
choco install vscode
choco install vscode-powershell
# https://code.visualstudio.com/docs/editor/command-line +powershell +git +darkorange

choco install notepadplusplus
choco install notepadplusplus-npppluginmanager

choco install googlechrome
choco install foxitreader

choco install wireshark
choco install winpcap

choco install totalcommander

choco install mobaxterm

## choco install fiddler # maybe not

# Set default browser to Chrome
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\ftp\UserChoice" -name ProgId ChromeHTML
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice" -name ProgId ChromeHTML
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice" -name ProgId ChromeHTML

<#
telnet
print management
lpr monitor
#>