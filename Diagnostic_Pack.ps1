$cpuUsage = Get-WmiObject -Class Win32_Processor | Select-Object -ExpandProperty LoadPercentage
if ($cpuUsage -gt 80) {
    Write-Host "High CPU usage: $cpuUsage%"
} elseif ($cpuUsage -gt 50) {
    Write-Host "Moderate CPU usage: $cpuUsage%"
} else {
    Write-Host "Low CPU usage: $cpuUsage%"
}

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

$memory = Get-WmiObject -Class Win32_OperatingSystem
$totalMemory = $memory.TotalVisibleMemorySize / 1KB / 1KB  # Convert from KB to GB
$freeMemory = $memory.FreePhysicalMemory / 1KB / 1KB  # Convert from KB to GB

if ($freeMemory -lt 1) {
    Write-Host "Warning: Low memory available: $([math]::round($freeMemory, 2)) GB"
} elseif ($freeMemory -lt 4) {
    Write-Host "Moderate memory available: $([math]::round($freeMemory, 2)) GB"
} else {
    Write-Host "Sufficient memory available: $([math]::round($freeMemory, 2)) GB"
}
