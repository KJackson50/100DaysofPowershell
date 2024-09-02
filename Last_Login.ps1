#Invoke-Command -ComputerName "RemotePC" -ScriptBlock {
    Get-WmiObject -Class Win32_UserProfile | 
    Where-Object { $_.LocalPath -like 'C:\Users\*' } | 
    Select-Object LocalPath, 
                  @{Name="LastUseTime";Expression={[System.Management.ManagementDateTimeConverter]::ToDateTime($_.LastUseTime)}} |
    Sort-Object LastUseTime -Descending | 
    Select-Object -First 10
#}
