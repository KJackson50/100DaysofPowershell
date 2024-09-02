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
