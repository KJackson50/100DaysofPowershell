$drives = Get-PSDrive -PSProvider FileSystem
foreach ($drive in $drives) {
    if ($drive.Free -lt 1GB) {
        Write-Host "$($drive.Name) has low disk space: $([math]::round($drive.Free / 1GB, 2)) GB free"
    } elseif ($drive.Free -lt 10GB) {
        Write-Host "$($drive.Name) has moderate disk space: $([math]::round($drive.Free / 1GB, 2)) GB free"
    } else {
        Write-Host "$($drive.Name) has sufficient disk space: $([math]::round($drive.Free / 1GB, 2)) GB free"
    }
}
