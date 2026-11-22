<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: New-AutoTaskResourceMap.ps1
    Type: PowerShell

        AUTHOR:  David Schulte
        DATE:    2026-11-21
        EMAIL:   celerium@Celerium.org

    TODO:

.SYNOPSIS
    Creates the resource map of the module from the AutoTask OpenAPI spec

.DESCRIPTION
    The New-AutoTaskResourceMap.ps1 script reads the AutoTask OpenAPI (swagger) spec that is stored
    in the module folder (Celerium.AutoTask\AutoTaskAPI-<version>.json) and creates the private
    Get-AutoTaskResourceMap function (Celerium.AutoTask\Private\ApiCalls\Get-AutoTaskResourceMap.ps1)

    The resource map lists every operation (resource, operation, HTTP method, & path) of the spec. The
    generic public functions (Get, New, Set, & Remove-AutoTaskResource) use it to validate & tab-complete
    resource names and to build the request uri, so the large spec does not have to be converted from
    JSON when the module is imported

    The output is identical every time the script runs with the same spec (UTF-8 without a BOM, LF line
    endings, ordinal sorting), so the CI workflow can check that the committed file is up to date

    Run this script after the spec is updated with Get-AutoTaskSpec.ps1 or Compare-AutoTaskSpec.ps1 -UpdateLocal

.PARAMETER ModuleName
    The name of the module

    Default value: Celerium.AutoTask

.PARAMETER JsonSpec
    Path to the OpenAPI spec to use

    Default value: the newest (highest version) AutoTaskAPI-<version>.json file in the module folder

.EXAMPLE
    .\New-AutoTaskResourceMap.ps1

    Creates the resource map from the newest spec in the module folder

.EXAMPLE
    .\New-AutoTaskResourceMap.ps1 -WhatIf

    Shows what would be written without changing any files

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

[CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName = 'Celerium.AutoTask',

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$JsonSpec
    )

#EndRegion  [ Parameters ]

Write-Verbose ''
Write-Verbose "START - $(Get-Date -Format yyyy-MM-dd-HH:mm)"
Write-Verbose ''

$StartDate = Get-Date

#Region     [ Prerequisites ]

$RootPath   = Split-Path -Path $PSScriptRoot -Parent
$ModulePath = Join-Path -Path $RootPath -ChildPath $ModuleName
$OutputPath = Join-Path -Path (Join-Path -Path (Join-Path -Path $ModulePath -ChildPath 'Private') -ChildPath 'ApiCalls') -ChildPath 'Get-AutoTaskResourceMap.ps1'

if (-not $JsonSpec) {

    # The newest (highest version) AutoTaskAPI-<version>.json file in the module folder is used
    $SpecFile = Get-ChildItem -Path $ModulePath -Filter 'AutoTaskAPI-*.json' -File -ErrorAction SilentlyContinue |
                    Sort-Object -Property @{ Expression = { $Text = $_.BaseName -replace '^AutoTaskAPI-v?', ''; if ($Text -match '^\d+$') { $Text += '.0' }; $Parsed = $null; if ([System.Version]::TryParse($Text, [ref]$Parsed)) { $Parsed } else { [System.Version]'0.0' } } }, Name -Descending |
                        Select-Object -First 1

    if (-not $SpecFile) { throw "No AutoTaskAPI-<version>.json spec was found in [ $ModulePath ]" }
    $JsonSpec = $SpecFile.FullName

}

if (-not (Test-Path -Path $JsonSpec -PathType Leaf)) { throw "The OpenAPI spec was not found at [ $JsonSpec ]" }

# The same function that the module uses to read a spec
. (Join-Path -Path (Join-Path -Path (Join-Path -Path $ModulePath -ChildPath 'Private') -ChildPath 'ApiCalls') -ChildPath 'Get-AutoTaskSpecOperation.ps1')

$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)

#EndRegion  [ Prerequisites ]

#Region     [ Read Spec ]

Write-Verbose " - (1/3) - $(Get-Date -Format MM-dd-HH:mm) - Reading [ $JsonSpec ]"

$Operations = @(Get-AutoTaskSpecOperation -JsonSpec $JsonSpec)

$Duplicates = @($Operations | Group-Object -Property Resource, Operation | Where-Object { $_.Count -gt 1 })
if ($Duplicates.Count) {
    throw "The spec has more than one [ resource & operation ] pair with the same name: $(($Duplicates | ForEach-Object { $_.Name }) -join '; ')"
}

$Invalid = @($Operations | Where-Object { $_.Resource -notmatch '^[A-Za-z0-9]+$' -or $_.Operation -notmatch '^[A-Za-z0-9]+$' -or $_.Path -notmatch '^/[A-Za-z0-9/{}._-]+$' })
if ($Invalid.Count) {
    throw "The spec has resource names, operation names, or paths that cannot be stored in the resource map: $(($Invalid | ForEach-Object { "$($_.Method) $($_.Path)" }) -join '; ')"
}

#EndRegion  [ Read Spec ]

#Region     [ Create Function ]

Write-Verbose " - (2/3) - $(Get-Date -Format MM-dd-HH:mm) - Creating the resource map with [ $($Operations.Count) ] operations"

$SpecName   = Split-Path -Path $JsonSpec -Leaf
$Resources  = @($Operations | ForEach-Object { $_.Resource } | Select-Object -Unique).Count
$Rows       = foreach ($Operation in $Operations) { '{0},{1},{2},{3}' -f $Operation.Resource, $Operation.Operation, $Operation.Method, $Operation.Path }

$Content = @"
function Get-AutoTaskResourceMap {
<#
    .SYNOPSIS
        Gets the resource map of the AutoTask API

    .DESCRIPTION
        The Get-AutoTaskResourceMap cmdlet returns every operation of the AutoTask API that
        the module supports, one object per resource & operation with the HTTP method & path

        The generic public functions use the resource map to validate & tab-complete resource
        names and to build the request uri

        This file is generated by build\New-AutoTaskResourceMap.ps1 from the OpenAPI spec
        [ $SpecName ] ( $Resources resources, $($Operations.Count) operations ), do not edit it by hand

    .EXAMPLE
        Get-AutoTaskResourceMap

        Returns every resource & operation

    .EXAMPLE
        Get-AutoTaskResourceMap | Where-Object { `$_.Resource -eq 'Companies' }

        Returns the operations of the Companies resource

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskResourceMap.html
#>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    Param ()

    begin {}

    process {

        # The map is converted once per session
        if (-not `$script:AutoTaskModuleResourceMap) {

            `$ResourceData = @'
Resource,Operation,Method,Path
$($Rows -join "`n")
'@

            `$script:AutoTaskModuleResourceMap = @(`$ResourceData | ConvertFrom-Csv)

        }

        `$script:AutoTaskModuleResourceMap

    }

    end {}

}
"@

$Content = ($Content -replace "`r`n", "`n").TrimEnd("`n") + "`n"

#EndRegion  [ Create Function ]

#Region     [ Save ]

Write-Verbose " - (3/3) - $(Get-Date -Format MM-dd-HH:mm) - Saving [ $OutputPath ]"

$Existing   = if (Test-Path -Path $OutputPath -PathType Leaf) { [System.IO.File]::ReadAllText($OutputPath) } else { $null }
$Status     = if ($null -eq $Existing) { 'Created' } elseif ($Existing -ceq $Content) { 'Unchanged' } else { 'Updated' }

if ($Status -ne 'Unchanged' -and $PSCmdlet.ShouldProcess($OutputPath, 'Write the resource map')) {
    [System.IO.File]::WriteAllText($OutputPath, $Content, $Utf8NoBom)
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
    Path        = $OutputPath
    Spec        = $JsonSpec
    Resources   = $Resources
    Operations  = $Operations.Count
}
