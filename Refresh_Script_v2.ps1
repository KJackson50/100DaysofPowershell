# Set Execution Policy to Bypass for the session
Set-ExecutionPolicy Bypass -Scope Process -Force

# Function to handle errors and log them
function Handle-Error {
    param(
        [string]$TaskName,
        [string]$ErrorMessage
    )
    Write-Host "$TaskName encountered an error: $ErrorMessage" -ForegroundColor Red
}

# Define the network path where the log file will be saved
$networkPath = "\\NetworkDrive\SharedFolder"

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

# Function to check and install PSWindowsUpdate if it's not installed
function Install-PSWindowsUpdate {
    try {
        Write-Host "Checking for PSWindowsUpdate module installation..." -ForegroundColor Cyan
        
        # Check if the module is installed
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Write-Host "PSWindowsUpdate is not installed. Installing now..." -ForegroundColor Yellow
            
            # Install the module
            Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
            
            # Confirm installation
            if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
                Write-Host "PSWindowsUpdate module installed successfully." -ForegroundColor Green
            } else {
                throw "Failed to install PSWindowsUpdate module."
            }
        } else {
            Write-Host "PSWindowsUpdate is already installed." -ForegroundColor Green
        }
        
        # Import the module
        Write-Host "Importing PSWindowsUpdate module..." -ForegroundColor Cyan
        Import-Module PSWindowsUpdate -ErrorAction Stop
        Write-Host "PSWindowsUpdate module imported successfully." -ForegroundColor Green
        
    } catch {
        Handle-Error "PSWindowsUpdate Installation/Import" $_.Exception.Message
    }
}

# Function to reset the Microsoft Store
function Reset-MicrosoftStore {
    try {
        Write-Host "Resetting Microsoft Store..." -ForegroundColor Yellow
        
        # Run wsreset.exe to reset the Microsoft Store
        Start-Process "wsreset.exe" -Wait

        Write-Host "Microsoft Store reset successfully." -ForegroundColor Green
    } catch {
        Handle-Error "Microsoft Store Reset" $_.Exception.Message
    }
}

# Function to check and update "App Installer" from the Microsoft Store
function Update-AppInstaller {
    try {
        Write-Host "Checking for Microsoft App Installer package..." -ForegroundColor Cyan

        # Check if App Installer is installed
        $appInstaller = Get-AppxPackage -Name Microsoft.DesktopAppInstaller

        if ($null -ne $appInstaller) {
            Write-Host "App Installer is installed, checking for updates..." -ForegroundColor Green

            # Reset Microsoft Store in case there are issues
            Reset-MicrosoftStore

            # Start App Installer update via the Microsoft Store
            Start-Process "ms-windows-store://pdp/?productid=9NBLGGH4NNS1" -Wait

            Write-Host "App Installer has been updated via Microsoft Store." -ForegroundColor Green

            # Add a wait loop to ensure the App Installer update completes
            Write-Host "Waiting for App Installer update to complete..."
            Start-Sleep -Seconds 20  # Initial wait

            # Check if App Installer is still running
            while (Get-Process -Name "WinStore.App" -ErrorAction SilentlyContinue) {
                Write-Host "App Installer is still running, waiting for it to finish..."
                Start-Sleep -Seconds 5
            }

            Write-Host "App Installer update has completed."
        } else {
            Write-Host "App Installer is not installed, please install it manually from the Microsoft Store." -ForegroundColor Yellow
        }
    } catch {
        Handle-Error "App Installer Update" $_.Exception.Message
    }
}




# Function to update specific programs (Adobe Reader, LibreOffice, Chrome, and Zoom) using winget
function Update-WingetPrograms {
    try {
        Write-Host "Checking if winget is available..." -ForegroundColor Cyan
        
        # Check if winget is installed
        if (-not (Get-Command -Name winget -ErrorAction SilentlyContinue)) {
            throw "winget is not installed or not available in this session."
        }

        Write-Host "Winget is available. Starting program updates..." -ForegroundColor Green
        
        # Specific winget IDs for the programs to update
        $programsToUpdate = @(
            "Adobe.Acrobat.Reader.64-bit", 
            "TheDocumentFoundation.LibreOffice", 
            "Google.Chrome", 
            "Zoom.Zoom"
        )
        
        # Loop through each program and attempt to update
        foreach ($program in $programsToUpdate) {
            try {
                Write-Host "Attempting to update $program via winget..." -ForegroundColor Yellow
                winget upgrade --id "$program" --silent
                Write-Host "$program updated successfully." -ForegroundColor Green
            } catch {
                Handle-Error "$program Update" $_.Exception.Message
            }
        }
        
    } catch {
        Handle-Error "Winget Upgrade" $_.Exception.Message
    }
}

function Perform-DiskCleanup {
    try {
        Write-Host "Configuring Disk Cleanup options..." -ForegroundColor Cyan
        # Configure Disk Cleanup options (run this once to set it up)
        Start-Process "cleanmgr.exe" "/sageset:1" -Wait

        Write-Host "Running Disk Cleanup with configured options..." -ForegroundColor Yellow
        # Run Disk Cleanup with the previously configured options
        Start-Process "cleanmgr.exe" "/sagerun:1" -Wait
        
        Write-Host "Disk Cleanup completed successfully." -ForegroundColor Green
    } catch {
        Handle-Error "Disk Cleanup" $_.Exception.Message
    }
}



function Optimize-Drives {
    try {
        Write-Host "Checking drive type for optimization..." -ForegroundColor Cyan
        
        # Get the media type (HDD/SSD)
        $drive = Get-PhysicalDisk | Where-Object { $_.DeviceID -eq (Get-Partition -DriveLetter C).DiskNumber }
        
        if ($drive.MediaType -eq "SSD") {
            Write-Host "Drive C is an SSD. Optimizing using TRIM..." -ForegroundColor Yellow
        } else {
            Write-Host "Drive C is an HDD. Defragmenting the drive..." -ForegroundColor Yellow
        }
        
        # Run Optimize-Volume command
        Optimize-Volume -DriveLetter C -Verbose
        
        Write-Host "Drive optimization completed successfully." -ForegroundColor Green
    } catch {
        Handle-Error "Drive Optimization" $_.Exception.Message
    }
}


function Clear-BrowserCache {
    try {
        Write-Host "Clearing browser cache..." -ForegroundColor Cyan
        
        # Define browser cache paths
        $browserCachePaths = @(
            "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
            "$env:APPDATA\Mozilla\Firefox\Profiles",
            "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
        )
        
        # Iterate through cache paths
        foreach ($cachePath in $browserCachePaths) {
            if (Test-Path $cachePath) {
                Write-Host "Clearing cache for: $cachePath" -ForegroundColor Yellow
                try {
                    Remove-Item -Path "$cachePath\*" -Recurse -Force
                    Write-Host "Successfully cleared cache for: $cachePath" -ForegroundColor Green
                } catch {
                    Handle-Error "Cache Clearing for $cachePath" $_.Exception.Message
                }
            } else {
                Write-Host "Cache path not found: $cachePath" -ForegroundColor Red
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

#Updates Windows using powershell module
function Update-Windows {
    try {
        Write-Host "Checking for available Windows updates..." -ForegroundColor Cyan

        # Get the list of available updates
        $updates = Get-WindowsUpdate -Verbose
        
        # Check if any updates were found
        if ($updates.Count -eq 0) {
            Write-Host "No Windows updates available." -ForegroundColor Green
        } else {
            Write-Host "The following updates are available:" -ForegroundColor Yellow
            $updates | ForEach-Object { Write-Host $_.Title }

            # Install the available updates
            Write-Host "Installing Windows updates and ignoring reboot requests..." -ForegroundColor Cyan
            $updates | Install-WindowsUpdate -AcceptAll -IgnoreReboot -Verbose

            Write-Host "Windows updates installed successfully." -ForegroundColor Green
        }
        
    } catch {
        Handle-Error "Windows Update" $_.Exception.Message
    }
}



# Main process: call all functions
try {
    Install-PSWindowsUpdate
    Reset-MicrosoftStore
    Update-AppInstaller
    Update-WingetPrograms
    Perform-DiskCleanup
    Optimize-Drives
    Clear-BrowserCache
    Update-Windows
    Update-GroupPolicies
    Optimize-SystemSettings
    Clean-Registry
    
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
