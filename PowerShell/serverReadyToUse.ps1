#Export-StartLayout -UseDesktopApplicationID -Path layout.xml
<#
.SYNOPSIS
   This script automates installation of important tools for a Windows server.
   It is to make your server ready for YSoft SafeQ 6 testing.

.DESCRIPTION
   In order for the script to function the internet connection is necessary

   Script automates installation of:
   - chocolatey (https://chocolatey.org/why-chocolatey)
   - latest .NET framework
   - Visual Studio Code
   - Git
   - Notepad++
   - Chrome (set as default)
   - Foxit reader
   - Wireshark
   - Total Commander
   - MobaXterm (https://mobaxterm.mobatek.net/)
   - Windows Features (Telnet, LPR Port Monitor, )

   Ideas:
   https://gist.github.com/timabell/608fb680bfc920f372ac
   https://stackoverflow.com/questions/48280464/how-can-i-associate-a-file-type-with-a-powershell-script


.EXAMPLE
   Run the PowerShell as Administrator, then launch the script in it.

.NOTES
  Version:        1.00
  Creation Date:  28/Dec/2021
#>
#-----------------------------------------------------------[Functions]------------------------------------------------------------

Function Set-FileAssociations($extension, $executable) {
    
    # create a filetype
    $filetype = cmd /c "assoc $extension 2>NUL"

    if ($filetype) {
        # If association already exists override it
        $filetype = $filetype.Split('=')[1]
    } else {
        # If filetype does not exist create it
        # ".log.1" becomes "log1file"
        $filetype = "$($extension.Replace('.',''))file"
        cmd /c 'assoc $ext=$name'
    }
    cmd /c "ftype $filetype=`"$executable`" `"%1`""
}


#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Admin rights check
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(([System.Security.Principal.SecurityIdentifier]'S-1-5-32-544'))) {
    Write-Warning 'Insufficient privileges. Please re-run the script as an Administrator.'
    Read-Host 'Press any key to exit the script'
    exit
}

# Install Chocolatey
try {
    choco upgrade chocolatey
}
catch {
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Start-Sleep 15
}


# Install required applications
choco install dotnetfx
choco install git
choco install vscode
choco install vscode-powershell
# https://code.visualstudio.com/docs/editor/command-line +powershell +git +darkorange

choco install foxitreader

choco install wireshark
choco install winpcap

choco install totalcommander

choco install mobaxterm

# Install Edge and set it as a default browser for HTTP and HTTPS
choco install microsoft-edge --force
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice" -name ProgId MSEdgeHTM
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice" -name ProgId MSEdgeHTM

# Install Notepad++ and set default file extensions
choco install notepadplusplus
choco install notepadplusplus-npppluginmanager

$extensions = @("conf", "config", "csv", "log", "md", "properties", "sql", "txt", "xml", "1", "2", "3")

foreach ($extension in $extensions) {
    $dottedextension="." + $extension
    Set-FileAssociations -extension $dottedextension -executable "C:\Program Files\Notepad++\notepad++.exe"
}

# Install Windows Features
# List: Get-WindowsFeature -ComputerName $env:computername
Install-WindowsFeature Telnet-Client
Install-WindowsFeature LPR-Port-Monitor

# Display hidden files in OS
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions

# pin services to the task bar
# https://docs.microsoft.com/en-us/windows/configuration/customize-and-export-start-layout
