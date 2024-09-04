# Set Execution Policy to Bypass for the session
Set-ExecutionPolicy Bypass -Scope Process -Force

# Check if winget is installed, and attempt to install it if not
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget is not installed. Attempting to install via Microsoft Store..."

    # Use PowerShell to invoke the installation of winget (App Installer)
    try {
        # This command opens the Microsoft Store page for App Installer
        Start-Process "ms-windows-store://pdp/?productid=9nblggh4nns1" -Wait
        
        Write-Host "Please install the App Installer package from the Microsoft Store to get winget."
        Write-Host "After installation, please rerun this script."
        exit 1  # Exit the script because winget is not installed yet
    } catch {
        Handle-Error "winget Installation" $_.Exception.Message
        exit 1  # Exit script if there was an error attempting to install winget
    }
} else {
    Write-Host "winget is already installed."
}

# Function to check and update 'App Installer' via Microsoft Store
function Update-AppInstaller {
    try {
        # Check if 'App Installer' is installed
        $appInstaller = Get-AppxPackage -Name Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue
        
        if ($appInstaller) {
            Write-Host "App Installer is installed. Ensuring it is up-to-date..."

            # Open Microsoft Store to update 'App Installer' (ProductID for App Installer)
            Start-Process "ms-windows-store://pdp/?productid=9nblggh4nns1" -Wait

            Write-Host "Please ensure the App Installer is updated via the Microsoft Store."
        } else {
            Write-Host "App Installer is not installed. Installing via Microsoft Store..."
            
            # Open Microsoft Store to install 'App Installer'
            Start-Process "ms-windows-store://pdp/?productid=9nblggh4nns1" -Wait

            Write-Host "Please install the App Installer package from the Microsoft Store."
            exit 1  # Exit the script because 'App Installer' is not installed yet
        }
    } catch {
        Handle-Error "App Installer Update" $_.Exception.Message
        exit 1  # Exit script if there was an error
    }
}


# Function to handle errors and log them
function Handle-Error {
    param(
        [string]$TaskName,
        [string]$ErrorMessage
    )
    Write-Host "$TaskName encountered an error: $ErrorMessage" -ForegroundColor Red
}

# Define the network path where the log file will be saved
$networkPath = "\\SHC0012LT119\Refresh"

# Get the hostname of the computer
$hostname = $env:COMPUTERNAME

# Create a log file path using the hostname
$logFile = "$networkPath\$hostname-log.txt"

# Check if the network path is available
$transcriptStarted = $false
if (Test-Path $networkPath) {
    try {
        # Start transcript to capture all script output if the path is available
        Start-Transcript -Path $logFile -Append -NoClobber
        Write-Host "Logging to network path: $logFile"
        $transcriptStarted = $true
    } catch {
        Handle-Error "Logging Setup" "Unable to start logging to $logFile $($_.Exception.Message)"
    }
} else {
    Write-Host "Network path $networkPath is not available. Skipping logging."
}

# Ensure PSWindowsUpdate is installed and imported
function Install-PSWindowsUpdate {
    try {
        Write-Host "Checking for PSWindowsUpdate module..."
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Write-Host "Installing PSWindowsUpdate module..."
            Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
        }
        Import-Module PSWindowsUpdate -ErrorAction Stop
        Write-Host "PSWindowsUpdate module installed and imported successfully."
    } catch {
        Handle-Error "PSWindowsUpdate Installation/Import" $_.Exception.Message
    }
}

# Function to update all programs using winget
function Update-WingetPrograms {
    try {
        Write-Host "Updating all programs via winget..."
        
        # Command to upgrade all programs
        winget upgrade --all --silent

        Write-Host "All programs have been updated successfully."

    } catch {
        Handle-Error "Winget Upgrade" $_.Exception.Message
    }
}


# Function to perform disk cleanup
function Perform-DiskCleanup {
    try {
        Write-Host "Running Disk Cleanup..."
        Start-Process "cleanmgr.exe" "/verylowdisk"
    } catch {
        Handle-Error "Disk Cleanup" $_.Exception.Message
    }
}

# Function to optimize or defragment SSD/HDD
function Optimize-Drives {
    try {
        Write-Host "Optimizing drives..."
        Optimize-Volume -DriveLetter C -Verbose
    } catch {
        Handle-Error "Drive Optimization" $_.Exception.Message
    }
}

# Function to clear browser cache by deleting cache directories
function Clear-BrowserCache {
    try {
        Write-Host "Clearing browser cache..."
        
        # Corrected cache paths for different browsers
        $browserCachePaths = @(
            "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
            "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
            "$env:APPDATA\Mozilla\Firefox\Profiles\*\cache2",
            "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
            "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache"
        )
        
        # Loop through each cache path and remove its contents
        foreach ($cachePath in $browserCachePaths) {
            if (Test-Path $cachePath) {
                Write-Host "Clearing cache for: $cachePath"
                Remove-Item -Path "$cachePath\*" -Recurse -Force
            } else {
                Write-Host "Cache path not found: $cachePath"
            }
        }

    } catch {
        Handle-Error "Clear Browser Cache" $_.Exception.Message
    }
}


# Function to update group policies
function Update-GroupPolicies {
    try {
        Write-Host "Updating group policies..."
        gpupdate /force | Out-Null
    } catch {
        Handle-Error "Group Policy Update" $_.Exception.Message
    }
}

# Function to adjust system settings for performance optimization
function Optimize-SystemSettings {
    try {
        Write-Host "Optimizing system settings..."
        Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'AutoEndTasks' -Value 1
        Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'HungAppTimeout' -Value 1000
    } catch {
        Handle-Error "Optimize System Settings" $_.Exception.Message
    }
}

# Function to clean up the registry
function Clean-Registry {
    try {
        Write-Host "Cleaning up the registry..."
        $script = @"
        $ErrorActionPreference = 'SilentlyContinue'
        $shell = New-Object -ComObject Shell.Application
        $shell.Namespace(0xA).Self.InvokeVerb('Delete')
"@
        Invoke-Expression $script
    } catch {
        Handle-Error "Registry Cleanup" $_.Exception.Message
    }
}

# Updated function to perform Windows Updates (includes drivers)
function Update-Windows {
    try {
        Write-Host "Checking for available Windows updates..."

        # Get the list of available updates
        $updates = Get-WindowsUpdate -Verbose
        
        if ($updates.Count -eq 0) {
            Write-Host "No Windows updates available."
        } else {
            Write-Host "The following updates are available:"
            $updates | ForEach-Object { Write-Host $_.Title }

            # Install the available updates
            Write-Host "Installing Windows updates..."
            $updates | Install-WindowsUpdate -AcceptAll -IgnoreReboot -Verbose

            Write-Host "Windows updates installed successfully."
        }
        
    } catch {
        Handle-Error "Windows Update" $_.Exception.Message
    }
}

# Main process: call all functions
try {
    Write-Host "Starting main process..."
    Update-AppInstaller
    Install-PSWindowsUpdate
    Update-WingetPrograms
    Perform-DiskCleanup
    Optimize-Drives
    Clear-BrowserCache
    Update-GroupPolicies
    Optimize-SystemSettings
    Clean-Registry
    Update-Windows
    Write-Host "Main process completed successfully."
} catch {
    Handle-Error "Main Process" $_.Exception.Message
}

# Stop the transcript only if it was started
if ($transcriptStarted) {
    try {
        Stop-Transcript
    } catch {
        Handle-Error "Stop Transcript" "Unable to stop logging: $_.Exception.Message"
    }
}

# Notify that the process is complete
[System.Windows.MessageBox]::Show("All tasks have been completed successfully!")
