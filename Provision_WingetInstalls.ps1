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

function Install-Applications {
    param (
        [string[]]$AppsToInstall = @("Google Chrome", "LibreOffice", "PDF Sam Basic", "Adobe Acrobat Reader DC", "FortiClient VPN")
    )

    foreach ($App in $AppsToInstall) {
        # Check if the app is already installed
        $installedApp = winget list --source winget | Where-Object { $_.Name -like "*$App*" }
        
        if (-not $installedApp) {
            Write-Host "Installing $App..."
            winget install --exact --id $App -s winget -e
        }
        else {
            Write-Host "$App is already installed."
        }
    }
}




Reset-MicrosoftStore
Update-AppInstaller
Install-Applications
