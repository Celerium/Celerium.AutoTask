<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: Compare-AutoTaskSpec.ps1
    Type: PowerShell

        AUTHOR:  David Schulte
        DATE:    2026-11-21
        EMAIL:   celerium@Celerium.org

    TODO:

.SYNOPSIS
    Compares the local AutoTask OpenAPI spec with the online version

.DESCRIPTION
    The Compare-AutoTaskSpec.ps1 script downloads the public OpenAPI (swagger) spec of the AutoTask REST API
    (https://webservices24.autotask.net/ATServicesRest/swagger/docs/v1, no authentication is required) and
    compares it with the local copy that is used to create the resource map (Celerium.AutoTask\AutoTaskAPI-<version>.json)

    The script reports the endpoints (method & path) that were added, removed, or changed and the
    schemas (swagger definitions or OpenAPI components) that were added, removed, or changed. An endpoint
    is changed when any part of its definition is different, such as its parameters, responses, or tags

    Nothing is changed unless -UpdateLocal is used. With -UpdateLocal the local spec is replaced by the
    online spec & the old local spec is first copied to build\Archive\<date> so nothing is lost. After an
    update run New-AutoTaskResourceMap.ps1 to regenerate the resource map

    The script works on Windows PowerShell 5.1, PowerShell 7+, Linux, & macOS

    The specs are compared by their content (endpoints & schemas), so a spec that only differs in
    formatting or property order is reported as identical

.PARAMETER LocalPath
    Path to the local OpenAPI spec

    Default value: the newest (highest version) AutoTaskAPI-<version>.json file in the module folder

.PARAMETER Uri
    Url of the online OpenAPI spec

    By default the AUTOTASK_BASE_URI environment variable is used (<AUTOTASK_BASE_URI>/swagger/docs/v1),
    if it is not set https://webservices24.autotask.net/ATServicesRest/swagger/docs/v1 is used

.PARAMETER ReferencePath
    Compares the local spec with another spec file instead of the online spec

.PARAMETER UpdateLocal
    Replaces the local spec with the online spec when they are different

    The previous local spec is copied to build\Archive\<date> first

.PARAMETER FailOnDifference
    Throws an error when the specs are different so that a CI workflow or scheduled task fails

.EXAMPLE
    .\Compare-AutoTaskSpec.ps1

    Compares the local spec with the online spec & returns the differences

.EXAMPLE
    .\Compare-AutoTaskSpec.ps1 -ReferencePath .\swagger.json -Verbose

    Compares the local spec with a local copy of the spec & shows the progress

.EXAMPLE
    .\Compare-AutoTaskSpec.ps1 -UpdateLocal

    Replaces the local spec with the online spec when they are different

.EXAMPLE
    .\Compare-AutoTaskSpec.ps1 -FailOnDifference

    Throws an error (non zero exit code) when the specs are different

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
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$LocalPath,

        [Parameter(Mandatory = $false, ParameterSetName = 'Online')]
        [ValidateNotNullOrEmpty()]
        [string]$Uri,

        [Parameter(Mandatory = $true, ParameterSetName = 'File')]
        [ValidateNotNullOrEmpty()]
        [string]$ReferencePath,

        [Parameter(Mandatory = $false)]
        [switch]$UpdateLocal,

        [Parameter(Mandatory = $false)]
        [switch]$FailOnDifference
    )

#EndRegion  [ Parameters ]

Write-Verbose ''
Write-Verbose "START - $(Get-Date -Format yyyy-MM-dd-HH:mm)"
Write-Verbose ''

$StartDate = Get-Date

#Region     [ Prerequisites ]

$RootPath   = Split-Path -Path $PSScriptRoot -Parent
$ModulePath = Join-Path -Path $RootPath -ChildPath 'Celerium.AutoTask'

if (-not $LocalPath) {

    # The newest (highest version) AutoTaskAPI-<version>.json file in the module folder is used
    $SpecFiles = @(Get-ChildItem -Path $ModulePath -Filter 'AutoTaskAPI-*.json' -File -ErrorAction SilentlyContinue | ForEach-Object {
        $Text = $_.BaseName -replace '^AutoTaskAPI-v?', ''
        if ($Text -match '^\d+$') { $Text += '.0' }
        $Parsed = $null
        [PSCustomObject]@{ File = $_; Version = if ([System.Version]::TryParse($Text, [ref]$Parsed)) { $Parsed } else { [System.Version]'0.0' } }
    })

    if ($SpecFiles.Count) { $LocalPath = ($SpecFiles | Sort-Object -Property Version, @{ Expression = { $_.File.Name } } -Descending | Select-Object -First 1).File.FullName }
    else { $LocalPath = Join-Path -Path $ModulePath -ChildPath 'AutoTaskAPI-2023.6.json' }

}

if (-not (Test-Path -Path $LocalPath -PathType Leaf)) { throw "The local spec was not found at [ $LocalPath ]" }

if ($PSCmdlet.ParameterSetName -eq 'Online' -and -not $Uri) {
    $Uri = if ($env:AUTOTASK_BASE_URI) { ($env:AUTOTASK_BASE_URI.TrimEnd('/') -replace '(?i)/v\d+(\.\d+)?$', '') + '/swagger/docs/v1' }
           else { 'https://webservices24.autotask.net/ATServicesRest/swagger/docs/v1' }
}

$HttpMethods = 'get', 'post', 'put', 'patch', 'delete', 'head', 'options'

#EndRegion  [ Prerequisites ]

#Region     [ Helper Functions ]

function ConvertTo-CanonicalJson {
    # Creates a JSON string where the properties of every object are sorted so that the order of the properties does not matter
    param ($Value)

    if ($null -eq $Value) { return 'null' }
    if ($Value -is [string]) { return (ConvertTo-Json -InputObject $Value -Compress) }
    if ($Value -is [bool]) { return $Value.ToString().ToLowerInvariant() }
    if ($Value -is [System.ValueType]) { return [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, '{0}', $Value) }

    if ($Value -is [System.Management.Automation.PSCustomObject]) {

        $Names = [string[]]@($Value.PSObject.Properties | ForEach-Object { $_.Name })
        [System.Array]::Sort($Names, [System.StringComparer]::Ordinal)

        $Pairs = foreach ($Name in $Names) { (ConvertTo-Json -InputObject $Name -Compress) + ':' + (ConvertTo-CanonicalJson -Value $Value.$Name) }
        return '{' + ($Pairs -join ',') + '}'

    }

    if ($Value -is [System.Collections.IEnumerable]) {
        $Items = foreach ($Item in $Value) { ConvertTo-CanonicalJson -Value $Item }
        return '[' + (@($Items) -join ',') + ']'
    }

    return (ConvertTo-Json -InputObject ([string]$Value) -Compress)
}

function Get-StringHash {
    param ([string]$Text)

    $Sha = [System.Security.Cryptography.SHA256]::Create()
    try { return [System.BitConverter]::ToString($Sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Text))) -replace '-', '' }
    finally { $Sha.Dispose() }
}

function Get-SpecIndex {
    # Creates a lookup of every endpoint & schema with the hash of its definition
    param ($Spec)

    $Endpoints = @{}
    $Schemas   = @{}

    foreach ($Path in $Spec.paths.PSObject.Properties) {
        foreach ($Method in $HttpMethods) {

            $Operation = $Path.Value.PSObject.Properties[$Method]
            if (-not $Operation) { continue }

            $Key = "$($Method.ToUpper()) $($Path.Name)"
            $Endpoints[$Key] = [PSCustomObject]@{ Hash = (Get-StringHash -Text (ConvertTo-CanonicalJson -Value $Operation.Value)); Operation = $Operation.Value }

        }
    }

    # Swagger 2.0 specs (AutoTask) store the schemas in definitions, OpenAPI 3 specs in components
    if ($Spec.PSObject.Properties['definitions']) {
        foreach ($Item in $Spec.definitions.PSObject.Properties) {
            $Schemas["definitions/$($Item.Name)"] = [PSCustomObject]@{ Hash = (Get-StringHash -Text (ConvertTo-CanonicalJson -Value $Item.Value)) }
        }
    }

    $Components = if ($Spec.PSObject.Properties['components']) { $Spec.components } else { [PSCustomObject]@{} }

    foreach ($Section in 'schemas', 'requestBodies', 'securitySchemes', 'parameters', 'responses') {

        $Items = $Components.PSObject.Properties[$Section]
        if (-not $Items) { continue }

        foreach ($Item in $Items.Value.PSObject.Properties) {
            $Schemas["$Section/$($Item.Name)"] = [PSCustomObject]@{ Hash = (Get-StringHash -Text (ConvertTo-CanonicalJson -Value $Item.Value)) }
        }

    }

    return [PSCustomObject]@{ Endpoints = $Endpoints; Schemas = $Schemas }
}

function Get-ChangedProperty {
    # Lists which parts of an endpoint (parameters, responses, tags, etc.) are different
    param ($Local, $Online)

    $Names = @(@($Local.PSObject.Properties.Name) + @($Online.PSObject.Properties.Name) | Select-Object -Unique)

    foreach ($Name in $Names) {
        $LocalJson  = if ($Local.PSObject.Properties[$Name]) { ConvertTo-CanonicalJson -Value $Local.$Name } else { $null }
        $OnlineJson = if ($Online.PSObject.Properties[$Name]) { ConvertTo-CanonicalJson -Value $Online.$Name } else { $null }
        # Case sensitive, the spec has changed only the case of a tag before (AutoTask / Autotask)
        if ($LocalJson -cne $OnlineJson) { $Name }
    }
}

function Compare-Index {
    param ($Local, $Online)

    $Added   = @($Online.Keys | Where-Object { -not $Local.ContainsKey($_) } | Sort-Object)
    $Removed = @($Local.Keys | Where-Object { -not $Online.ContainsKey($_) } | Sort-Object)
    $Changed = @($Local.Keys | Where-Object { $Online.ContainsKey($_) -and $Online[$_].Hash -ne $Local[$_].Hash } | Sort-Object)

    return [PSCustomObject]@{ Added = $Added; Removed = $Removed; Changed = $Changed }
}

#EndRegion  [ Helper Functions ]

#Region     [ Get Specs ]

Write-Verbose " - (1/4) - $(Get-Date -Format MM-dd-HH:mm) - Reading the local spec [ $LocalPath ]"

$LocalBytes = [System.IO.File]::ReadAllBytes((Resolve-Path -Path $LocalPath).ProviderPath)

Write-Verbose " - (2/4) - $(Get-Date -Format MM-dd-HH:mm) - Reading the reference spec"

if ($PSCmdlet.ParameterSetName -eq 'File') {

    if (-not (Test-Path -Path $ReferencePath -PathType Leaf)) { throw "The reference spec was not found at [ $ReferencePath ]" }

    $Source      = $ReferencePath
    $OnlineBytes = [System.IO.File]::ReadAllBytes((Resolve-Path -Path $ReferencePath).ProviderPath)

}
else {

    $Source = $Uri

    # Windows PowerShell does not always negotiate TLS 1.2 by default
    if ($PSEdition -eq 'Desktop') {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    }

    $Request = @{ Uri = $Uri; Method = 'GET'; UseBasicParsing = $true; ErrorAction = 'Stop' }

    try { $Response = Invoke-WebRequest @Request }
    catch { throw "Unable to download the online spec from [ $Uri ] - $($_.Exception.Message)" }

    $OnlineBytes = $Response.RawContentStream.ToArray()

}

$OnlineText = [System.Text.Encoding]::UTF8.GetString($OnlineBytes).TrimStart([char]0xFEFF)
if ($OnlineText.TrimStart() -notmatch '^\{') { throw "The spec from [ $Source ] is not valid JSON" }

#EndRegion  [ Get Specs ]

#Region     [ Compare ]

$Sha        = [System.Security.Cryptography.SHA256]::Create()
$LocalHash  = [System.BitConverter]::ToString($Sha.ComputeHash($LocalBytes)) -replace '-', ''
$OnlineHash = [System.BitConverter]::ToString($Sha.ComputeHash($OnlineBytes)) -replace '-', ''
$Sha.Dispose()

$Result = [PSCustomObject]@{
    Identical           = ($LocalHash -eq $OnlineHash)
    LocalPath           = $LocalPath
    Source              = $Source
    LocalVersion        = $null
    OnlineVersion       = $null
    AddedEndpoints      = @()
    RemovedEndpoints    = @()
    ChangedEndpoints    = @()
    AddedSchemas        = @()
    RemovedSchemas      = @()
    ChangedSchemas      = @()
    Updated             = $false
    ArchivePath         = $null
}

# Identical files do not need to be parsed, a spec that only differs in formatting is also reported as identical after parsing
if ($Result.Identical) {
    Write-Verbose " - (3/4) - $(Get-Date -Format MM-dd-HH:mm) - The files are identical, nothing to compare"
}
else {

    Write-Verbose " - (3/4) - $(Get-Date -Format MM-dd-HH:mm) - Comparing the endpoints & schemas"

    $LocalSpec  = [System.Text.Encoding]::UTF8.GetString($LocalBytes).TrimStart([char]0xFEFF) | ConvertFrom-Json
    try { $OnlineSpec = $OnlineText | ConvertFrom-Json -ErrorAction Stop }
    catch { throw "The spec from [ $Source ] is not valid JSON - $($_.Exception.Message)" }

    $Result.LocalVersion    = "$($LocalSpec.info.version)"
    $Result.OnlineVersion   = "$($OnlineSpec.info.version)"

    $LocalIndex     = Get-SpecIndex -Spec $LocalSpec
    $OnlineIndex    = Get-SpecIndex -Spec $OnlineSpec

    $Endpoints  = Compare-Index -Local $LocalIndex.Endpoints -Online $OnlineIndex.Endpoints
    $Schemas    = Compare-Index -Local $LocalIndex.Schemas -Online $OnlineIndex.Schemas

    $Result.AddedEndpoints      = $Endpoints.Added
    $Result.RemovedEndpoints    = $Endpoints.Removed
    $Result.ChangedEndpoints    = @(foreach ($Key in $Endpoints.Changed) {
        [PSCustomObject]@{
            Endpoint    = $Key
            Changes     = @(Get-ChangedProperty -Local $LocalIndex.Endpoints[$Key].Operation -Online $OnlineIndex.Endpoints[$Key].Operation)
        }
    })
    $Result.AddedSchemas        = $Schemas.Added
    $Result.RemovedSchemas      = $Schemas.Removed
    $Result.ChangedSchemas      = $Schemas.Changed

    # The bytes are different but every endpoint & schema is the same, such as a different order or formatting
    $Result.Identical = (-not $Endpoints.Added.Count) -and (-not $Endpoints.Removed.Count) -and (-not $Endpoints.Changed.Count) -and
                        (-not $Schemas.Added.Count) -and (-not $Schemas.Removed.Count) -and (-not $Schemas.Changed.Count)

}

#EndRegion  [ Compare ]

#Region     [ Update Local ]

Write-Verbose " - (4/4) - $(Get-Date -Format MM-dd-HH:mm) - Updating the local spec"

if ($UpdateLocal -and -not $Result.Identical) {

    $ArchiveFolder  = Join-Path -Path (Join-Path -Path (Join-Path -Path $RootPath -ChildPath 'build') -ChildPath 'Archive') -ChildPath (Get-Date -Format 'yyyyMMdd-HHmmss')
    $ArchiveFile    = Join-Path -Path $ArchiveFolder -ChildPath (Split-Path -Path $LocalPath -Leaf)

    if ($PSCmdlet.ShouldProcess($LocalPath, "Replace with the online spec (the old spec is copied to [ $ArchiveFile ])")) {

        New-Item -Path $ArchiveFolder -ItemType Directory -Force > $null
        Copy-Item -Path $LocalPath -Destination $ArchiveFile -Force
        [System.IO.File]::WriteAllBytes((Resolve-Path -Path $LocalPath).ProviderPath, $OnlineBytes)

        $Result.Updated     = $true
        $Result.ArchivePath = $ArchiveFile

        Write-Verbose "The local spec was replaced. Run New-AutoTaskResourceMap.ps1 to regenerate the resource map"

    }

}

#EndRegion  [ Update Local ]

Write-Verbose ''
Write-Verbose "END - $(Get-Date -Format yyyy-MM-dd-HH:mm)"
Write-Verbose ''

$TimeToComplete = New-TimeSpan -Start $StartDate -End (Get-Date)
Write-Verbose 'Time to complete'
Write-Verbose ($TimeToComplete | Select-Object * -ExcludeProperty Ticks,Total*,Milli* | Out-String)

$Result

if ($FailOnDifference -and -not $Result.Identical) {
    throw "The local spec [ $LocalPath ] is different from [ $Source ]: $($Result.AddedEndpoints.Count) endpoints added, $($Result.RemovedEndpoints.Count) removed, $($Result.ChangedEndpoints.Count) changed"
}
