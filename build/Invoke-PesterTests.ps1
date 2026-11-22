<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: Invoke-PesterTests.ps1
    Type: PowerShell

        AUTHOR:  David Schulte
        DATE:    2023-04-1
        EMAIL:   celerium@Celerium.org
        Updated: 2026-11-21

    TODO:
    Add public function testing with secrets

.SYNOPSIS
    Invoke Pester tests against all functions in a module

.DESCRIPTION
    Invoke Pester tests against all functions in a module

.PARAMETER ModuleName
    The name of the local module to import

    Default value: Celerium.AutoTask

.PARAMETER Version
    The version of the local module to import

.PARAMETER IncludeTag
    Tags to run tests against

.PARAMETER ExcludeTag
    Tags associated to test to skip

    Default value: Live, Online

    The 'Live' tests make real read-only requests against the AutoTask API, the authenticated tests
    require the AUTOTASK_API_USERNAME, AUTOTASK_API_SECRET, & AUTOTASK_API_INTEGRATION_CODE environment variables
    The 'Online' tests require the GitHub pages documentation to be published

.PARAMETER BuildTarget
    Which version of the module to run tests against

    Allowed values:
        'built', 'notBuilt'

.PARAMETER Output
    How detailed should the pester output be

    Default value: Normal

    Allowed values:
        'Detailed', 'Diagnostic', 'Minimal', 'None', 'Normal'


.EXAMPLE
    .\Invoke-PesterTests -ModuleName Celerium.AutoTask -Version 1.2.3

    Runs various pester tests against all functions in the module
    and outputs the results to the console.

    An XML of the tests is also output to the build directory

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

#Region     [ Parameters ]

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$ModuleName = 'Celerium.AutoTask',

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Version,

    [Parameter(Mandatory=$false)]
    [string[]]$IncludeTag = @(),

    [Parameter(Mandatory=$false)]
    [string[]]$ExcludeTag = @('Live', 'Online'),

    [Parameter(Mandatory=$false)]
    [ValidateSet('built','notBuilt')]
    [string]$BuildTarget = 'notBuilt',

    [Parameter(Mandatory=$false)]
    [ValidateSet('Detailed', 'Diagnostic', 'Minimal', 'None', 'Normal')]
    [string]$Output = 'Normal'
)

#EndRegion  [ Parameters ]

#Region     [ Prerequisites ]

try {

    # Not a #Requires statement because that prevents the exit code from reaching the caller when run with -File
    Import-Module -Name Pester -MinimumVersion 6.2.0 -ErrorAction Stop

    $RootPath = Split-Path -Path $PSScriptRoot -Parent

    $TestPath = Join-Path -Path $RootPath -ChildPath "tests"

}
catch {
    Write-Error $_
    exit 1
}

#EndRegion  [ Prerequisites ]

#Region     [ Pester Configuration ]

$PesterContainerParams = @{
    'ModuleName'        = $ModuleName;
    'Version'           = $Version;
    'BuildTarget'       = $BuildTarget
}
    $PesterContainer = New-PesterContainer -Path $TestPath -Data $PesterContainerParams

$PesterOptions = @{

    Run = @{
        Container = $PesterContainer
        PassThru = $true
    }

    Filter = @{
        Tag = $IncludeTag
        ExcludeTag = $ExcludeTag
    }

    TestResult = @{
        Enabled = $true
        OutputFormat = 'NUnitXml'
        OutputPath = Join-Path -Path (Join-Path -Path $RootPath -ChildPath 'build') -ChildPath "$($ModuleName)_$($BuildTarget)_Results.xml"
        OutputEncoding = 'UTF8'
    }

    Should = @{
        ErrorAction = 'Continue'
    }

    Output = @{
        Verbosity = $Output
    }

}

    $PesterConfiguration = New-PesterConfiguration -Hashtable $PesterOptions

#EndRegion  [ Pester Configuration ]

#Region     [ Pester Invoke ]

$PesterResults = Invoke-Pester -Configuration $PesterConfiguration
    Set-Variable -Name Invoke_PesterResults -Value $PesterResults -Scope Global -Force

# Fail the calling process (CI) when any test or container fails
if ($PesterResults.FailedCount -gt 0 -or $PesterResults.FailedContainersCount -gt 0 -or $PesterResults.FailedBlocksCount -gt 0) {
    exit 1
}

#EndRegion  [ Pester Invoke ]

