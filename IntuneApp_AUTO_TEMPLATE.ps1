#######################################################
## KJackson
## created 7.19.23
#######################################################

#Pre-reqs = Install-Module MSGraph, IntuneWin32App, AzureAD, and PSIntuneAuth
$Modules = @('MSGraph', 'IntuneWin32App', 'AzureAD', 'PSIntuneAuth')

foreach ($Module in $Modules) {
    if (-not (Get-Module -ListAvailable -Name $Module)) {
        Write-Host "Installing $Module..."
        Install-Module -Name $Module -Force -Scope CurrentUser
    } else {
        Write-Host "$Module is already installed."
    }
}

#Connect to Graph API - Commented out if running from master file. if running individually, uncomment below line.
$TenantID = Read-Host "Enter your Tenant domain (i.e. - domain.com or domain.onmicrosoft.com)"$TenantID = Read-Host "Enter your Tenant domain (i.e. - domain.com or domain.onmicrosoft.com)"
$ClientID = Read-Host "Enter your Client ID from Azure App Registration"
Connect-MSIntuneGraph -TenantID $TenantID -ClientId $ClientID


function New-IntuneWin32AppRequirementRule {
    <#
    .SYNOPSIS
        Construct a new requirement rule as an optional requirement for Add-IntuneWin32App cmdlet.
 
    .DESCRIPTION
        Construct a new requirement rule as an optional requirement for Add-IntuneWin32App cmdlet.
 
    .PARAMETER Architecture
        Specify the architecture as a requirement for the Win32 app.
 
    .PARAMETER MinimumSupportedOperatingSystem
        Specify the minimum supported operating system version as a requirement for the Win32 app.
 
    .PARAMETER MinimumFreeDiskSpaceInMB
        Specify the minimum free disk space in MB as a requirement for the Win32 app.
 
    .PARAMETER MinimumMemoryInMB
        Specify the minimum required memory in MB as a requirement for the Win32 app.
 
    .PARAMETER MinimumNumberOfProcessors
        Specify the minimum number of required logical processors as a requirement for the Win32 app.
 
    .PARAMETER MinimumCPUSpeedInMHz
        Specify the minimum CPU speed in Mhz (as an integer) as a requirement for the Win32 app.
 
    .NOTES
        Author: Nickolaj Andersen
        Contact: @NickolajA
        Created: 2020-01-27
        Updated: 2020-01-27
 
        Version history:
        1.0.0 - (2020-01-27) Function created
    #>    
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the architecture as a requirement for the Win32 app.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("x64", "x86", "All")]
        [string]$Architecture,

        [parameter(Mandatory = $true, HelpMessage = "Specify the minimum supported operating system version as a requirement for the Win32 app.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("1607", "1703", "1709", "1803", "1809", "1903")]
        [string]$MinimumSupportedOperatingSystem,

        [parameter(Mandatory = $false, HelpMessage = "Specify the minimum free disk space in MB as a requirement for the Win32 app.")]
        [ValidateNotNullOrEmpty()]
        [int]$MinimumFreeDiskSpaceInMB,

        [parameter(Mandatory = $false, HelpMessage = "Specify the minimum required memory in MB as a requirement for the Win32 app.")]
        [ValidateNotNullOrEmpty()]
        [int]$MinimumMemoryInMB,

        [parameter(Mandatory = $false, HelpMessage = "Specify the minimum number of required logical processors as a requirement for the Win32 app.")]
        [ValidateNotNullOrEmpty()]
        [int]$MinimumNumberOfProcessors,

        [parameter(Mandatory = $false, HelpMessage = "Specify the minimum CPU speed in Mhz (as an integer) as a requirement for the Win32 app.")]
        [ValidateNotNullOrEmpty()]
        [int]$MinimumCPUSpeedInMHz
    )
    # Construct table for supported architectures
    $ArchitectureTable = @{
        "x64" = "x64"
        "x86" = "x86"
        "All" = "x64,x86"
    }

    # Construct table for supported operating systems
    $OperatingSystemTable = @{
        "1607" = "v10_1607"
        "1703" = "v10_1703"
        "1709" = "v10_1709"
        "1803" = "v10_1803"
        "1809" = "v10_1809"
        "1903" = "v10_1903"
        "1909" = "v10_1909"
        "2004" = "v10_2004"
    }

    # Construct ordered hash-table with least amount of required properties for default requirement rule
    $RequirementRule = [ordered]@{
        "applicableArchitectures" = $ArchitectureTable[$Architecture]
        "minimumSupportedOperatingSystem" = @{
            $OperatingSystemTable[$MinimumSupportedOperatingSystem] = $true
        }
    }

    # Add additional requirement rule details if specified on command line
    if ($PSBoundParameters["MinimumFreeDiskSpaceInMB"]) {
        $RequirementRule.Add("minimumFreeDiskSpaceInMB", $MinimumFreeDiskSpaceInMB)
    }
    if ($PSBoundParameters["MinimumMemoryInMB"]) {
        $RequirementRule.Add("minimumMemoryInMB", $MinimumMemoryInMB)
    }
    if ($PSBoundParameters["MinimumNumberOfProcessors"]) {
        $RequirementRule.Add("minimumNumberOfProcessors", $MinimumNumberOfProcessors)
    }
    if ($PSBoundParameters["MinimumCPUSpeedInMHz"]) {
        $RequirementRule.Add("minimumCpuSpeedInMHz", $MinimumCPUSpeedInMHz)
    }

    return $RequirementRule
}


#Create working direcotry for the Application, set download location, and download installer
$appfolder = new-item -Path "G:\My Drive\Scripts\win32apps" -Name "Chrome" -ItemType Directory -Force
$downloadsource = 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi'
$filename = "googlechromestandaloneenterprise64.msi"
$downloaddestination = $appfolder
Start-BitsTransfer -Source $downloadsource -Destination $appfolder\$filename | Out-Null


#logo download - image file must be PNG or JPG
$logoURL = "https://logowik.com/content/uploads/images/google-chrome-2022-new5983.jpg"
$LogoFileName = "chrome.png"
Invoke-WebRequest -Uri $logoURL -D -OutFile $downloaddestination\$LogoFileName


#Create the intunewin file from source and destination variables and assign IntuneWin file location variable
$Source = $appfolder
$SetupFile = $filename
$Destination = $appfolder
$CreateAppPackage = New-IntuneWin32AppPackage -SourceFolder $Source -SetupFile $SetupFile -OutputFolder $Destination -Verbose -Force
$IntuneWinFile = $CreateAppPackage.Path
if (-not $IntuneWinFile) {
    Write-Host "Package creation failed. No .intunewin file was created."
    exit
} else {
    Write-Host "Package created successfully at $IntuneWinFile"
}



#Get intunewin file MSI MetaData <- Did not work for Chrome. May need to retrieve Product Code manually 
$IntuneWinMetaData = Get-IntuneWin32AppMetaData -FilePath $IntuneWinFile


#Names Application, description and publisher info as it appears in MEM - Examples below
$Displayname = "Zoom Desktop Client"
$Description = "Zoom Desktop Client"
$Publisher = "Zoom"


##Create MSI product code detection rule - Retrieve MSI code if you don't have it. Alternate method commented below to use File existence. MSIs are recommended to use Product Code. 
$DetectionRule = New-IntuneWin32AppDetectionRuleMSI -ProductCode $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductCode
#$DetectionRule = New-IntuneWin32AppDetectionRuleFile -Existence -FileOrFolder Firefox.exe -Path "C:\Program Files\Mozilla Firefox\" -Check32BitOn64System $false -DetectionType "exists"

#Create Requirement Rule (32/64 bit and minimum Windows Version)
$ArchitectureRequired = "All"
$MinimumOSBuild = "1607"
$RequirementRule = New-IntuneWin32AppRequirementRule -Architecture $ArchitectureRequired -MinimumSupportedOperatingSystem $MinimumOSBuild
 

#Create a cool Icon from the downloaded image file (if you want) - comment out lines if you don't want or can't find an image file
$ImageFile = "$appfolder\$LogoFileName"
$Icon = New-IntuneWin32AppIcon -FilePath $ImageFile
 

#****Install and Uninstall Commands - not needed for MSI installs****
#$InstallCommandLine = "7zipX64.exe /S"
#$UninstallCommandLine = "%systemdrive%\Program Files\7-Zip\Uninstall.exe"


#Builds the App and Uploads to Intune
Add-IntuneWin32App -FilePath $IntuneWinFile -DisplayName $DisplayName -Description $Description -Publisher $Publisher -InstallExperience "system" -RestartBehavior "suppress" -DetectionRule $DetectionRule -RequirementRule $RequirementRule -Icon $Icon -Verbose