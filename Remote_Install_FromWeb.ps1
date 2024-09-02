$remoteComputer = "RemotePCName"

$scriptBlock = {
    $url = "https://dl.google.com/chrome/install/standalonesetup64.exe"
    $output = "$env:USERPROFILE\Downloads\ChromeInstaller.exe"
    
    Invoke-WebRequest -Uri $url -OutFile $output
    
    if (Test-Path $output) {
        Write-Host "Chrome installer downloaded successfully."

        try {
            Start-Process -FilePath $output -ArgumentList "/silent /install" -NoNewWindow -Wait
            Write-Host "Chrome installed successfully."
        } catch {
            Write-Host "Error during Chrome installation: $_"
        }
    } else {
        Write-Host "Chrome installer download failed."
    }
}

Invoke-Command -ComputerName $remoteComputer -ScriptBlock $scriptBlock -Credential (Get-Credential)
