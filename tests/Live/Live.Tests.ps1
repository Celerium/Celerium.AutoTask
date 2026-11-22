<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: Live.Tests.ps1
    Type: PowerShell

.SYNOPSIS
    Optional read-only integration tests against the real AutoTask API

.DESCRIPTION
    Pester tests that make real read-only requests against the AutoTask API

    These tests are tagged with 'Live' and are excluded by default. They are skipped unless the
    following environment variables are set:

        AUTOTASK_API_USERNAME           The username of an AutoTask API user (zone detection, no secret is sent)
        AUTOTASK_API_SECRET             The secret of the API user          (authenticated tests)
        AUTOTASK_API_INTEGRATION_CODE   The API integration code            (authenticated tests)
        AUTOTASK_BASE_URI               Optional, by default the zone of the API user is detected

    Every request is a GET request or a POST query, no write function is ever called. The number of
    requests is kept small & the requests are spaced out to respect the AutoTask API rate limits

.PARAMETER ModuleName
    The name of the local module to import

.PARAMETER Version
    The version of the local module to import

.PARAMETER BuildTarget
    Which version of the module to run tests against

    Allowed values:
        'built', 'notBuilt'

.EXAMPLE
    .\build\Invoke-PesterTests.ps1 -Version 2.0.0 -IncludeTag Live -ExcludeTag Online

    Runs only the live tests

.LINK
    https://celerium.org

#>

#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='6.0.0' }

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$ModuleName = 'Celerium.AutoTask',

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Version,

    [Parameter(Mandatory=$true)]
    [ValidateSet('built','notBuilt')]
    [string]$BuildTarget
)

BeforeDiscovery {
    $PesterTestName     = (Get-Item -Path $PSCommandPath).Name
    $HasUsername        = [bool]$env:AUTOTASK_API_USERNAME
    $LiveConfigured     = [bool]($env:AUTOTASK_API_USERNAME -and $env:AUTOTASK_API_SECRET -and $env:AUTOTASK_API_INTEGRATION_CODE)
}

BeforeAll {

    $TestsPath = $PSScriptRoot
    while ($TestsPath -and -not (Test-Path -Path (Join-Path -Path $TestsPath -ChildPath 'TestHelper.ps1'))) { $TestsPath = Split-Path -Path $TestsPath -Parent }
    . (Join-Path -Path $TestsPath -ChildPath 'TestHelper.ps1')

    $LiveConfigured = [bool]($env:AUTOTASK_API_USERNAME -and $env:AUTOTASK_API_SECRET -and $env:AUTOTASK_API_INTEGRATION_CODE)

    if ($env:AUTOTASK_API_USERNAME) {
        Import-TestModule -ModuleName $ModuleName -Version $Version -BuildTarget $BuildTarget -KeepEnvironment
    }

    if ($LiveConfigured -and -not $env:AUTOTASK_BASE_URI) {
        # One unauthenticated GET request to the ZoneInformation endpoint
        Add-AutoTaskBaseURI
    }

}

AfterAll {
    Remove-TestModule -ModuleName $ModuleName
}

Describe "Testing the unauthenticated live requests of [ $ModuleName ] with [ $PesterTestName ]" -Tag @('Live') -Skip:(-not $HasUsername) {

    It "Add-AutoTaskBaseURI detects the zone of the API user" {
        $Saved = Get-AutoTaskBaseURI -WarningAction SilentlyContinue
        if (-not (Get-AutoTaskAPIKey -WarningAction SilentlyContinue)) {
            # Only the username is used by the zone detection
            Set-Variable -Name 'AutoTaskModuleApiUsername' -Value $env:AUTOTASK_API_USERNAME -Option ReadOnly -Scope Global -Force
        }
        try {
            Add-AutoTaskBaseURI
            Get-AutoTaskBaseURI | Should -Match '^https://[a-z0-9.-]+\.autotask\.net/atservicesrest$'
        }
        finally { if ($Saved) { Add-AutoTaskBaseURI -BaseURI $Saved } }
    }

}

Describe "Testing the authenticated live read-only requests of [ $ModuleName ] with [ $PesterTestName ]" -Tag @('Live') -Skip:(-not $LiveConfigured) {

    BeforeEach {
        # Spaces out the requests
        Start-Sleep -Milliseconds 750
    }

    It "Test-AutoTaskAPIKey returns a 200 status code" {
        (Test-AutoTaskAPIKey).StatusCode | Should -Be 200
    }

    It "Gets the owner company (ID 0) by ID" {
        (Get-AutoTaskResource -Resource Companies -ID 0).id | Should -Be 0
    }

    It "Queries one company with an advanced search" {
        $Result = @(Get-AutoTaskResource -Resource Companies -AdvancedSearch '{"MaxRecords":1,"IncludeFields":["id","companyName"],"filter":[{"op":"gte","field":"id","value":0}]}')
        $Result.Count | Should -Be 1
    }

    It "Counts the active companies with a POST query" {
        (Get-AutoTaskResource -Resource Companies -SimpleSearch 'isActive eq true' -Operation QueryCount).queryCount | Should -BeGreaterOrEqual 0
    }

    It "Gets the API usage threshold information" {
        Get-AutoTaskResource -Resource ThresholdApiIntegration | Should -Not -BeNullOrEmpty
    }

    It "New-AutoTaskBody reads the field definitions of a resource" {
        (New-AutoTaskBody -Resource Companies -Empty).PSObject.Properties.Name | Should -Contain 'companyName'
    }

}
