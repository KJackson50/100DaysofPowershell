#This function simplifys logging throughout the script
function Write-Log {
    param (
        [Parameter(ValueFromPipeline=$true)]
        [string]$Message
    )

    process {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        # Log each line of output with a timestamp
        Add-Content -Path "C:\temp\Update_Logs\RecentUpdate.txt" -Value "$timestamp $Message"
    }
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
# Log the update results
Install-WindowsUpdate | ForEach-Object { Write-Log $_ }

# Log the current date (after updates are installed)
(Get-Date) | Write-Log
}


