#This function simplifys logging throughout the script
function Write-Log {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path "C:\temp\Update_Logs\RecentUpdate.txt" -Value "$timestamp $Message"
}

#Check to see if the C:\temp directory exists, if not, create it
if (-not(Test-Path C:\temp\Update_Logs)){
New-Item -Path C:\temp\Update_Logs -ItemType Directory
}
else{
Write-Host "Directory Already Exists"
}

#Import and install module
if (-not(Get-InstalledModule PSWindowsUpdate)){
Import-Module PSWindowsUpdate
Install-Module PSWindowsUpdate
}
else{
Write-Host "Module Already Imported"
}

#Check for and install updates / push to log file
$updates = Get-WindowsUpdate

if (-not($updates)){
Write-Log "There are no updates at this time"
}
else{
Install-WindowsUpdate | out-file C:\temp\Update_Logs\RecentUpdate.txt -append
Get-Date | out-file C:\temp\Update_Logs\RecentUpdate.txt -Append
}


