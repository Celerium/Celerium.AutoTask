<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: Get-AutoTaskSpec.ps1
    Type: PowerShell

        AUTHOR:  David Schulte
        DATE:    2026-11-21
        EMAIL:   celerium@Celerium.org

    TODO:

.SYNOPSIS
    Downloads the latest online AutoTask OpenAPI (swagger) spec to the module folder

.DESCRIPTION
    The Get-AutoTaskSpec.ps1 script downloads the public OpenAPI (swagger) spec of the AutoTask REST API
    (https://webservices24.autotask.net/ATServicesRest/swagger/docs/v1, no authentication is required)
    and saves it to the module folder with the following naming convention:

        {product}-{version}.json

    The product is AutoTaskAPI. The info.version value of the AutoTask spec is always v1, so the version
    is the year & month of the download (yyyy.M) unless -SpecVersion is used, such as AutoTaskAPI-2026.11.json

    The AutoTask spec is the known exception of the Celerium projects that is stored in the module folder
    instead of the docs folder. The spec is saved exactly as it was downloaded

    The script never overwrites a different file without keeping it. When a file with the same
    name already exists & is different, the existing file is copied to build\Archive\<date> first.
    When the existing file is identical nothing is changed

    The New-AutoTaskResourceMap.ps1, Invoke-ModuleBuild.ps1, & Compare-AutoTaskSpec.ps1 scripts use the
    newest spec (highest version) in the module folder, so after a download run New-AutoTaskResourceMap.ps1
    to regenerate the resource map & remove the older spec when it is no longer needed

.PARAMETER Uri
    Url of the online OpenAPI spec

    By default the AUTOTASK_BASE_URI environment variable is used (<AUTOTASK_BASE_URI>/swagger/docs/v1),
    if it is not set https://webservices24.autotask.net/ATServicesRest/swagger/docs/v1 is used

.PARAMETER ReferencePath
    Uses a local spec file instead of downloading one, helpful for testing or offline use

.PARAMETER Product
    The product name used in the file name

    Default value: AutoTaskAPI

.PARAMETER SpecVersion
    The version used in the file name

    Default value: the current year & month, such as 2026.11

.PARAMETER OutputPath
    The folder to save the spec in

    Default value: the module folder of the repository

.EXAMPLE
    .\Get-AutoTaskSpec.ps1

    Downloads the online spec & saves it as Celerium.AutoTask\AutoTaskAPI-<yyyy.M>.json

.EXAMPLE
    .\Get-AutoTaskSpec.ps1 -ReferencePath .\swagger.json -SpecVersion 2026.11 -Verbose

    Saves a local copy of the spec & shows the progress

.EXAMPLE
    .\Get-AutoTaskSpec.ps1 -WhatIf

    Shows what would be saved without writing any files

.INPUTS
    N/A

.OUTPUTS
    PSCustomObject

.LINK
    https://celerium.org

#>

<############################################################################################
                                        Code
############################################################################################>
#Requires -Version 5.1

#Region     [ Parameters ]

[CmdletBinding(DefaultParameterSetName = 'Online', SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = 'Online')]
        [ValidateNotNullOrEmpty()]
        [string]$Uri,

        [Parameter(Mandatory = $true, ParameterSetName = 'File')]
        [ValidateNotNullOrEmpty()]
        [string]$ReferencePath,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Product = 'AutoTaskAPI',

        [Parameter(Mandatory = $false)]
        [ValidatePattern('^[A-Za-z0-9._+-]+$')]
        [string]$SpecVersion = (Get-Date -Format 'yyyy.M'),

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath
    )

#EndRegion  [ Parameters ]

Write-Verbose ''
Write-Verbose "START - $(Get-Date -Format yyyy-MM-dd-HH:mm)"
Write-Verbose ''

$StartDate = Get-Date

#Region     [ Prerequisites ]

$RootPath = Split-Path -Path $PSScriptRoot -Parent
if (-not $OutputPath) { $OutputPath = Join-Path -Path $RootPath -ChildPath 'Celerium.AutoTask' }

if ($PSCmdlet.ParameterSetName -eq 'Online' -and -not $Uri) {
    $Uri = if ($env:AUTOTASK_BASE_URI) { ($env:AUTOTASK_BASE_URI.TrimEnd('/') -replace '(?i)/v\d+(\.\d+)?$', '') + '/swagger/docs/v1' }
           else { 'https://webservices24.autotask.net/ATServicesRest/swagger/docs/v1' }
}

#EndRegion  [ Prerequisites ]

#Region     [ Download ]

Write-Verbose " - (1/3) - $(Get-Date -Format MM-dd-HH:mm) - Getting the spec"

if ($PSCmdlet.ParameterSetName -eq 'File') {

    if (-not (Test-Path -Path $ReferencePath -PathType Leaf)) { throw "The reference spec was not found at [ $ReferencePath ]" }

    $Source = $ReferencePath
    $Bytes  = [System.IO.File]::ReadAllBytes((Resolve-Path -Path $ReferencePath).ProviderPath)

}
else {

    $Source = $Uri

    # Windows PowerShell does not always negotiate TLS 1.2 by default
    if ($PSEdition -eq 'Desktop') {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    }

    try { $Response = Invoke-WebRequest -Uri $Uri -Method GET -UseBasicParsing -ErrorAction Stop }
    catch { throw "Unable to download the spec from [ $Uri ] - $($_.Exception.Message)" }

    $Bytes = $Response.RawContentStream.ToArray()

}

#EndRegion  [ Download ]

#Region     [ Validate ]

Write-Verbose " - (2/3) - $(Get-Date -Format MM-dd-HH:mm) - Validating the spec"

$Text = [System.Text.Encoding]::UTF8.GetString($Bytes).TrimStart([char]0xFEFF)

if ($Text.TrimStart() -notmatch '^\{') { throw "The spec from [ $Source ] is not valid JSON" }
try { $Spec = $Text | ConvertFrom-Json -ErrorAction Stop }
catch { throw "The spec from [ $Source ] is not valid JSON - $($_.Exception.Message)" }

if (-not $Spec.openapi -and -not $Spec.swagger) { throw "The file from [ $Source ] is not an OpenAPI spec, it does not have an openapi or swagger property" }
if (-not $Spec.paths -or @($Spec.paths.PSObject.Properties).Count -eq 0) { throw "The spec from [ $Source ] does not have any paths" }

$FileName   = "$Product-$SpecVersion.json"
$FilePath   = Join-Path -Path $OutputPath -ChildPath $FileName

#EndRegion  [ Validate ]

#Region     [ Save ]

Write-Verbose " - (3/3) - $(Get-Date -Format MM-dd-HH:mm) - Saving [ $FilePath ]"

$Status      = 'Created'
$ArchiveFile = $null

if (Test-Path -Path $FilePath -PathType Leaf) {

    $Existing = [System.IO.File]::ReadAllBytes($FilePath)

    $Sha        = [System.Security.Cryptography.SHA256]::Create()
    $SameFile   = [System.BitConverter]::ToString($Sha.ComputeHash($Existing)) -eq [System.BitConverter]::ToString($Sha.ComputeHash($Bytes))
    $Sha.Dispose()

    $Status = if ($SameFile) { 'Unchanged' } else { 'Replaced' }

}

if ($Status -eq 'Replaced') {

    # The previous file is kept so that nothing is lost
    $ArchiveFolder  = Join-Path -Path (Join-Path -Path (Join-Path -Path $RootPath -ChildPath 'build') -ChildPath 'Archive') -ChildPath (Get-Date -Format 'yyyyMMdd-HHmmss')
    $ArchiveFile    = Join-Path -Path $ArchiveFolder -ChildPath $FileName

    if ($PSCmdlet.ShouldProcess($FilePath, "Replace with the new spec (the existing file is copied to [ $ArchiveFile ])")) {
        New-Item -Path $ArchiveFolder -ItemType Directory -Force > $null
        Copy-Item -Path $FilePath -Destination $ArchiveFile -Force
        [System.IO.File]::WriteAllBytes($FilePath, $Bytes)
    }
    else { $ArchiveFile = $null }

}
elseif ($Status -eq 'Created') {

    if ($PSCmdlet.ShouldProcess($FilePath, 'Save the spec')) {
        if (-not (Test-Path -Path $OutputPath -PathType Container)) { New-Item -Path $OutputPath -ItemType Directory -Force > $null }
        [System.IO.File]::WriteAllBytes($FilePath, $Bytes)
    }

}

#EndRegion  [ Save ]

Write-Verbose ''
Write-Verbose "END - $(Get-Date -Format yyyy-MM-dd-HH:mm)"
Write-Verbose ''

$TimeToComplete = New-TimeSpan -Start $StartDate -End (Get-Date)
Write-Verbose 'Time to complete'
Write-Verbose ($TimeToComplete | Select-Object * -ExcludeProperty Ticks,Total*,Milli* | Out-String)

[PSCustomObject]@{
    Status      = $Status
    Path        = $FilePath
    Product     = $Product
    Version     = $SpecVersion
    Title       = "$($Spec.info.title)"
    Endpoints   = @($Spec.paths.PSObject.Properties).Count
    Source      = $Source
    ArchivePath = $ArchiveFile
}
