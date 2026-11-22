<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: Invoke-HelpContent.ps1
    Type: PowerShell

        AUTHOR:  David Schulte
        DATE:    2022-11-26
        EMAIL:   celerium@celerium.org
        Updated: 2026-11-21

    TODO:

.SYNOPSIS
    Calls the Update-HelpContent function to update module markdown help files

.DESCRIPTION
    The Invoke-HelpContent script calls the Update-HelpContent function to
    update module markdown help files

    The help files are created with the Microsoft.PowerShell.PlatyPS module

.PARAMETER ModuleName
    The name of the module to update help docs for

.PARAMETER GithubPageUri
    The github project url to inject into help docs

.EXAMPLE
    .\Invoke-HelpContent.ps1

    Updates the markdown docs (docs\site), the module page, & the external help (docs\en-US)

.EXAMPLE
    .\Invoke-HelpContent.ps1 -Verbose

    Updates the markdown docs & shows the progress

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
#Requires -Modules @{ ModuleName="Microsoft.PowerShell.PlatyPS"; ModuleVersion="1.0.0" }

#Region  [ Parameters ]

[CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName = 'Celerium.AutoTask',

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$GithubPageUri = "https://celerium.github.io/Celerium.AutoTask"
    )

#EndRegion  [ Parameters ]

Write-Verbose ''
Write-Verbose "START - $(Get-Date -Format yyyy-MM-dd-HH:mm) - [ $($PSCmdlet.ParameterSetName) ]"
Write-Verbose ''

#Region     [ Prerequisites ]

$StartDate = Get-Date

#EndRegion  [ Prerequisites ]

#Region  [ Update Help ]

try {

    $RootPath = Split-Path -Path $PSScriptRoot -Parent

    . (Join-Path -Path $PSScriptRoot -ChildPath 'Update-HelpContent.ps1')

    $Parameters = @{
        ModuleName      = $ModuleName
        HelpDocsPath    = Join-Path -Path $RootPath -ChildPath 'docs'
        CsvFilePath     = Join-Path -Path (Join-Path -Path $RootPath -ChildPath 'docs') -ChildPath 'endpoints.csv'
        GithubPageUri   = $GithubPageUri
        Verbose         = $true
    }

    Update-HelpContent @Parameters

}
catch {
    Write-Error $_
    exit 1
}

#EndRegion  [ Update Help ]

Write-Verbose ''
Write-Verbose "END - $(Get-Date -Format yyyy-MM-dd-HH:mm)"
Write-Verbose ''

$TimeToComplete = New-TimeSpan -Start $StartDate -End (Get-Date)
Write-Verbose 'Time to complete'
Write-Verbose ($TimeToComplete | Select-Object * -ExcludeProperty Ticks,Total*,Milli* | Out-String)