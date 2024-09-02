# Define the remote computer name or IP address
$remoteComputer = "RemoteMachineName"  # Replace with the name or IP address of the remote machine

# Prompt for credentials to authenticate on the remote machine
$cred = Get-Credential

# Use Invoke-Command to run the winget command remotely with error handling
Invoke-Command -ComputerName $remoteComputer -Credential $cred -ScriptBlock {
    try {
        # Attempt to install Notepad++ using winget on the remote machine
        $result = winget install "Notepad++.Notepad++" -e --silent
        
        # Check if the installation was successful and output the result
        if ($result) {
            Write-Host "Winget executed successfully. Installed Notepad++."
        } else {
            Write-Host "Winget did not return a success message."
        }
    } catch {
        # Handle any errors that occur during the winget execution
        Write-Host "An error occurred during the installation: $_"
    }
}