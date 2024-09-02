$url = "https://github.com/git-for-windows/git/releases/download/v2.32.0.windows.1/Git-2.32.0-64-bit.exe"
$output = "$env:USERPROFILE\Downloads\GitInstaller.exe"
Invoke-WebRequest -Uri $url -OutFile $output

# Run the installer silently
Start-Process -FilePath $output -ArgumentList "/SILENT /NORESTART" -NoNewWindow -Wait
