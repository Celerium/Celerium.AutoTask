<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: Install-Prerequisites.ps1
    Type: PowerShell

        AUTHOR:  David Schulte
        DATE:    2023-04-1
        EMAIL:   celerium@Celerium.org
        Updated: 2026-11-21

    TODO:

.SYNOPSIS
    Installs the prerequisites needed to build and test a Celerium PowerShell project.

.DESCRIPTION
    The Install-Prerequisites script installs the prerequisites needed to
    build and test a Celerium PowerShell project.

    The various prerequisites required allow for the automation of documentation,
    GitHub Actions, Pester testing, and PowerShell module building.

    The script works on Windows PowerShell 5.1, PowerShell 7+, Linux, & macOS and
    installs the latest version of every module that is missing or out of date

.PARAMETER Modules
    Defines one or more modules to install

.PARAMETER ForceUpdate
    Update the modules if they are already installed

.EXAMPLE
    .\Install-Prerequisites.ps1

    Installs the prerequisites needed to build and test a Celerium PowerShell project.

.EXAMPLE
    .\Install-Prerequisites.ps1 -Modules Pester -ForceUpdate

    Installs or updates only the Pester module

.INPUTS
    N/A

.OUTPUTS
    N/A

.LINK
    https://celerium.org

#>

<############################################################################################
                                        Code
############################################################################################>
#Requires -Version 5.1

#Region  [ Parameters ]

[CmdletBinding(DefaultParameterSetName = 'Install', SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory=$false, ParameterSetName = 'Install')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Modules = @('ModuleBuilder', 'Pester', 'Microsoft.PowerShell.PlatyPS', 'PSScriptAnalyzer'),

        [Parameter(Mandatory=$false, ParameterSetName = 'Update')]
        [switch]$ForceUpdate
    )

#EndRegion  [ Parameters ]

Write-Verbose ''
Write-Verbose "START - $(Get-Date -Format yyyy-MM-dd-HH:mm) - [ $($PSCmdlet.ParameterSetName) ]"
Write-Verbose ''

#Region     [ Prerequisites ]

$StartDate = Get-Date

# Minimum version requirements, the latest version of every module is installed
#   - Microsoft.PowerShell.PlatyPS replaces the legacy platyPS module
$ModuleRequirements = @{
    'ModuleBuilder'                 = @{ MinimumVersion  = '3.2.18' }
    'Pester'                        = @{ MinimumVersion  = '6.2.0' }
    'Microsoft.PowerShell.PlatyPS'  = @{ MinimumVersion  = '1.0.0' }
    'PSScriptAnalyzer'              = @{ MinimumVersion  = '1.25.0' }
}

#EndRegion  [ Prerequisites ]

Write-Verbose " - (1/2) - $(Get-Date -Format MM-dd-HH:mm) - Checking Package Provider"

#Region     [ Modules & Providers ]

try {

    if ($PSEdition -eq 'Desktop') {

        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

        $PackageProvider = Get-PackageProvider -ListAvailable | Where-Object { $_.Name -eq 'NuGet' -and $_.Version -ge [version]'2.8.5.201' }
        if ($null -eq $PackageProvider) {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force > $null
        }

    }

    if ((Get-PSRepository -Name PSGallery -ErrorAction Stop).InstallationPolicy -ne 'Trusted') {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    }

}
Catch{
    Write-Error $_
    exit 1
}

#EndRegion  [ Modules & Providers ]

Write-Verbose " - (2/2) - $(Get-Date -Format MM-dd-HH:mm) - Installing Modules"

#Region     [ Main Code ]

foreach ($Module in $Modules) {

    $Requirement = $ModuleRequirements[$Module]
    if ($null -eq $Requirement) { $Requirement = @{} }

    $InstallParams = @{
        Name                = $Module
        Scope               = 'CurrentUser'
        Force               = $true
        AllowClobber        = $true
        SkipPublisherCheck  = $true
        ErrorAction         = 'Stop'
    }
    if ($Requirement.RequiredVersion) { $InstallParams.RequiredVersion = $Requirement.RequiredVersion }
    if ($Requirement.MinimumVersion)  { $InstallParams.MinimumVersion  = $Requirement.MinimumVersion }

    $FindParams = @{ Name = $Module; ErrorAction = 'SilentlyContinue' }
    if ($Requirement.RequiredVersion) { $FindParams.RequiredVersion = $Requirement.RequiredVersion }
    if ($Requirement.MinimumVersion)  { $FindParams.MinimumVersion  = $Requirement.MinimumVersion }

    $Latest = Find-Module @FindParams
    if (-not $Latest) {
        Write-Warning " -       - $(Get-Date -Format MM-dd-HH:mm) - [ $Module ] is not valid or was not found"
        exit 1
    }

    $Installed = Get-Module -Name $Module -ListAvailable | Where-Object {
        ( -not $Requirement.RequiredVersion -or $_.Version -eq [version]$Requirement.RequiredVersion ) -and
        ( -not $Requirement.MinimumVersion  -or $_.Version -ge [version]$Requirement.MinimumVersion )
    } | Sort-Object Version -Descending | Select-Object -First 1

    # The latest version is always used, an older version is updated
    $Outdated = $Installed -and ($Installed.Version -lt [version](($Latest.Version -split '-')[0]))

    if ($null -eq $Installed -or $Outdated -or $ForceUpdate) {

        $Action = if ($null -eq $Installed) { 'Installing' } else { 'Updating' }

        if ($PSCmdlet.ShouldProcess($Module, $Action)) {
            Write-Verbose " -       - $(Get-Date -Format MM-dd-HH:mm) - $Action [ $Module ]"
            try { Install-Module @InstallParams }
            catch {
                Write-Error $_
                exit 1
            }
        }

    }
    else {
        Write-Verbose " -       - $(Get-Date -Format MM-dd-HH:mm) - Already installed [ $($Installed.Name) | $($Installed.Version) ]"
    }

}

#EndRegion  [ Main Code ]

Write-Verbose ''
Write-Verbose "END - $(Get-Date -Format yyyy-MM-dd-HH:mm)"
Write-Verbose ''

$TimeToComplete = New-TimeSpan -Start $StartDate -End (Get-Date)
Write-Verbose 'Time to complete'
Write-Verbose ($TimeToComplete | Select-Object * -ExcludeProperty Ticks,Total*,Milli* | Out-String)
