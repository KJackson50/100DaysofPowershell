#Script that checks status of all running services and outputs it into a log at startup

#Check to see if the C:\temp directory exists, if not, create it
if (-not(Test-Path C:\temp)){
New-Item -Path C:\temp -ItemType Directory
}
else{
Write-Host "Temp Directory Exists"
}
#Main code
Get-Service | Where-Object -Property "Status" -eq "Running" | out-file C:\temp\Service_Running.txt

#adds the current date to the end of the log
Get-Date | out-file C:\temp\Service_Running.txt -Append