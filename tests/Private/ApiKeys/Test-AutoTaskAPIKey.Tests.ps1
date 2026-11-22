<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: Test-AutoTaskAPIKey.Tests.ps1
    Type: PowerShell

.SYNOPSIS
    Pester tests for the Test-AutoTaskAPIKey function

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
Describe "Testing [ $CommandName ] function with [ $PesterTestName ]" -Tag @('apiKeys') {

    Context "[ $CommandName ] testing function" {

        BeforeEach {
            Add-AutoTaskBaseURI -BaseURI 'https://api.example.org/atservicesrest'
            Add-AutoTaskAPIKey -ApiUsername 'user@example.org' -ApiSecretKey 'secret' -ApiIntegrationCode 'code'
        }

        It "Writes an error when the base uri or API values are not set" {
            Remove-AutoTaskAPIKey -WarningAction SilentlyContinue
            Remove-AutoTaskBaseURI -WarningAction SilentlyContinue
            Test-AutoTaskAPIKey -ErrorVariable TestError -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            $TestError | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 0 -Exactly
        }

        It "Makes a single read-only GET query with the AutoTask headers & returns the status" {
            Mock Invoke-WebRequest -ModuleName $ModuleName { [PSCustomObject]@{ StatusCode = 200; StatusDescription = 'OK' } }

            $Result = Test-AutoTaskAPIKey
            $Result.StatusCode | Should -Be 200
            $Result.URI | Should -BeLike 'https://api.example.org/atservicesrest/V1.0/Companies/query?search=*'

            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'GET' -and "$Uri" -like 'https://api.example.org/atservicesrest/V1.0/Companies/query?search=*MaxRecords*' -and
                $Headers['UserName'] -eq 'user@example.org' -and $Headers['Secret'] -eq 'secret' -and $Headers['ApiIntegrationCode'] -eq 'code'
            }
        }

        It "Returns the status code when the credentials are rejected" {
            Mock Invoke-WebRequest -ModuleName $ModuleName {
                $Ex = [FakeHttpException]::new('Unauthorized')
                $Ex.Response = [PSCustomObject]@{ StatusCode = 401; StatusDescription = 'Unauthorized'; ReasonPhrase = 'Unauthorized' }
                throw $Ex
            }

            $Result = Test-AutoTaskAPIKey
            $Result.StatusCode | Should -Be 401
            $Result.Method | Should -Be 'GET'
        }

        It "Allows a custom base uri & removes a trailing API version" {
            Mock Invoke-WebRequest -ModuleName $ModuleName { [PSCustomObject]@{ StatusCode = 200; StatusDescription = 'OK' } }
            (Test-AutoTaskAPIKey -BaseURI 'https://custom.example.org/atservicesrest/V1.0/').URI | Should -BeLike 'https://custom.example.org/atservicesrest/V1.0/Companies/query?search=*'
        }

    }

}
