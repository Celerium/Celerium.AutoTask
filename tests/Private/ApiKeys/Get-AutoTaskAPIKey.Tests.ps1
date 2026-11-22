<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: Get-AutoTaskAPIKey.Tests.ps1
    Type: PowerShell

.SYNOPSIS
    Pester tests for the Get-AutoTaskAPIKey function

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

    BeforeEach {
        Remove-AutoTaskAPIKey -WarningAction SilentlyContinue
    }

    Context "[ $CommandName ] testing function" {

        It "Returns the API values when they are set" {
            Add-AutoTaskAPIKey -ApiUsername 'user@example.org' -ApiSecretKey 'secret123' -ApiIntegrationCode 'code123'
            Get-AutoTaskAPIKey | Should -Not -BeNullOrEmpty
        }

        It "Returns the secret as a SecureString by default" {
            Add-AutoTaskAPIKey -ApiUsername 'user@example.org' -ApiSecretKey 'secret123' -ApiIntegrationCode 'code123'
            (Get-AutoTaskAPIKey).Password | Should -BeOfType [System.Security.SecureString]
        }

        It "Returns the secret as a SecureString when it was passed in from the pipeline" {
            'secret123' | Add-AutoTaskAPIKey -ApiUsername 'user@example.org' -ApiIntegrationCode 'code123'
            (Get-AutoTaskAPIKey).Password | Should -BeOfType [System.Security.SecureString]
        }

        It "Returns plain text with -AsPlainText" {
            Add-AutoTaskAPIKey -ApiUsername 'user@example.org' -ApiSecretKey 'secret123' -ApiIntegrationCode 'code123'
            $Key = Get-AutoTaskAPIKey -AsPlainText
            $Key.Password | Should -BeOfType [string]
            $Key.Password | Should -BeExactly 'secret123'
            $Key.Username | Should -BeExactly 'user@example.org'
            $Key.ApiIntegrationCode | Should -BeExactly 'code123'
        }

        It "Warns when no values are set" {
            Get-AutoTaskAPIKey -WarningVariable KeyWarning -WarningAction SilentlyContinue | Should -BeNullOrEmpty
            $KeyWarning | Should -Not -BeNullOrEmpty
        }

    }

}
