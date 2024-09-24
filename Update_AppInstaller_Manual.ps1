# Define the App Installer package name
$appInstallerPackageName = "Microsoft.DesktopAppInstaller"

# Check if App Installer is installed
$appInstaller = Get-AppxPackage -Name $appInstallerPackageName -ErrorAction SilentlyContinue

if ($appInstaller) {
    Write-Host "App Installer is installed. Checking for updates..."

    try {
        # Open Microsoft Store to the updates page
        Start-Process -FilePath "ms-windows-store://updates"
        
        Write-Host "Microsoft Store opened. Please allow updates to complete."
        
        # Optionally, wait for some time to allow updates to complete
        Start-Sleep -Seconds 60
        
    } catch {
        Write-Error "Failed to open Microsoft Store for updates: $_"
        exit 1
    }
} else {
    Write-Host "App Installer is not installed. Installing it from the Microsoft Store..."
    try {
        # Install the App Installer if it's missing using Add-AppxPackage
        Add-AppxPackage -Name $appInstallerPackageName -ErrorAction Stop
        Write-Host "App Installer has been installed successfully."
    } catch {
        Write-Error "Failed to install App Installer: $_"
        exit 1
    }
}

# Exit the script when the check and updates are complete
Write-Host "App Installer update or installation process completed. Exiting script."
exit 0
