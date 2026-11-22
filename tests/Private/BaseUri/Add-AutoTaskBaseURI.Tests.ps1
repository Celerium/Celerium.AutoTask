<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: Add-AutoTaskBaseURI.Tests.ps1
    Type: PowerShell

.SYNOPSIS
    Pester tests for the Add-AutoTaskBaseURI function

.PARAMETER ModuleName
    The name of the local module to import

.PARAMETER Version
    The version of the local module to import

.PARAMETER BuildTarget
    Which version of the module to run tests against

    Allowed values:
        'built', 'notBuilt'

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

BeforeAll {
    $TestsPath = $PSScriptRoot
    while ($TestsPath -and -not (Test-Path -Path (Join-Path -Path $TestsPath -ChildPath 'TestHelper.ps1'))) { $TestsPath = Split-Path -Path $TestsPath -Parent }
    . (Join-Path -Path $TestsPath -ChildPath 'TestHelper.ps1')

    Import-TestModule -ModuleName $ModuleName -Version $Version -BuildTarget $BuildTarget
    Add-FakeHttpException

    # Safety net so that a test can never make a real request
    Mock Invoke-WebRequest -ModuleName $ModuleName { throw 'Unexpected un-mocked request' }
    Mock Invoke-RestMethod -ModuleName $ModuleName { throw 'Unexpected un-mocked request' }
}

AfterAll {
    Remove-TestModule -ModuleName $ModuleName
}

BeforeDiscovery {
    $PesterTestName = (Get-Item -Path $PSCommandPath).Name
    $CommandName = $PesterTestName -replace '.Tests.ps1',''
    $IsWindowsPlatform = ($PSEdition -eq 'Desktop' -or $IsWindows)
}
Describe "Testing [ $CommandName ] function with [ $PesterTestName ]" -Tag @('baseUri') {

    BeforeEach {
        Remove-AutoTaskBaseURI -WarningAction SilentlyContinue
        Remove-AutoTaskAPIKey -WarningAction SilentlyContinue
    }

    Context "[ $CommandName ] testing function" {

        It "Should have an alias of [ Set-AutoTaskBaseURI ]" {
            (Get-Alias -Name Set-AutoTaskBaseURI).ReferencedCommand.Name | Should -Be 'Add-AutoTaskBaseURI'
        }

        It "Should accept a value from the pipeline" {
            'https://api.example.org/atservicesrest' | Add-AutoTaskBaseURI
            Get-AutoTaskBaseURI | Should -Be 'https://api.example.org/atservicesrest'
        }

        It "With parameter -BaseURI <value> should return what was inputted" {
            Add-AutoTaskBaseURI -BaseURI 'https://api.example.org/atservicesrest'
            Get-AutoTaskBaseURI | Should -Be 'https://api.example.org/atservicesrest'
        }

        It "With parameter -DataCenter America West 3 should return the zone URI" {
            Add-AutoTaskBaseURI -DataCenter 'America West 3'
            Get-AutoTaskBaseURI | Should -Be 'https://webservices24.autotask.net/atservicesrest'
            Get-AutoTaskBaseURI -AndApiUri | Should -Be 'https://webservices24.autotask.net/atservicesrest/V1.0'
        }

        It "Accepts the -Platform alias of -DataCenter" {
            Add-AutoTaskBaseURI -Platform 'UK'
            Get-AutoTaskBaseURI | Should -Be 'https://webservices4.autotask.net/atservicesrest'
        }

        It "With invalid parameter value -DataCenter Space should return an error" {
            { Add-AutoTaskBaseURI -DataCenter 'Space' } | Should -Throw
        }

        It "A custom URI should NOT contain a trailing forward slash or API version" {
            Add-AutoTaskBaseURI -BaseURI 'https://api.example.org/atservicesrest/V1.0/'
            Get-AutoTaskBaseURI | Should -Be 'https://api.example.org/atservicesrest'
        }

        It "Stores the API version" {
            Add-AutoTaskBaseURI -BaseURI 'https://api.example.org/atservicesrest' -Version 'V2.0'
            Get-AutoTaskBaseURI -AndApiUri | Should -Be 'https://api.example.org/atservicesrest/V2.0'
        }

        It "Rejects an invalid uri <_>" -ForEach 'http://api.example.org', 'api.example.org', 'not a uri' {
            { Add-AutoTaskBaseURI -BaseURI $_ } | Should -Throw '*not valid*'
            Get-AutoTaskBaseURI -WarningAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It "Does not make a web request with -BaseURI or -DataCenter" {
            Add-AutoTaskBaseURI -BaseURI 'https://api.example.org/atservicesrest'
            Add-AutoTaskBaseURI -DataCenter 'UK2'
            Should -Invoke Invoke-RestMethod -ModuleName $ModuleName -Times 0 -Exactly
        }

        It "Detects the zone of the API user with one unauthenticated GET request" {
            Add-AutoTaskAPIKey -ApiUsername 'user@example.org' -ApiSecretKey 'secret' -ApiIntegrationCode 'code'
            Mock Invoke-RestMethod -ModuleName $ModuleName { [PSCustomObject]@{ zoneName = 'America West 3'; url = 'https://webservices24.autotask.net/ATServicesRest/' } }

            Add-AutoTaskBaseURI

            Get-AutoTaskBaseURI | Should -Be 'https://webservices24.autotask.net/ATServicesRest'
            Should -Invoke Invoke-RestMethod -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'GET' -and $Uri -eq 'https://webservices2.autotask.net/atservicesrest/V1.0/ZoneInformation?user=user%40example.org' -and $null -eq $Headers
            }
        }

        It "Throws when the zone is detected without an API username" {
            { Add-AutoTaskBaseURI } | Should -Throw '*username*'
        }

    }

}
