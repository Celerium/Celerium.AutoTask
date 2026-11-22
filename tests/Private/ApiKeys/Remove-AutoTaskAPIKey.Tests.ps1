<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: Remove-AutoTaskAPIKey.Tests.ps1
    Type: PowerShell

.SYNOPSIS
    Pester tests for the Remove-AutoTaskAPIKey function

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

        It "Removes all API variables" {
            Add-AutoTaskAPIKey -ApiUsername 'user@example.org' -ApiSecretKey 'secret123' -ApiIntegrationCode 'code123'
            Remove-AutoTaskAPIKey
            Get-AutoTaskAPIKey -WarningAction SilentlyContinue | Should -BeNullOrEmpty
            foreach ($Name in 'AutoTaskModuleApiUsername', 'AutoTaskModuleApiSecretKey', 'AutoTaskModuleApiIntegrationCode') {
                Get-Variable -Name $Name -Scope Global -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            }
        }

        It "Warns when there is nothing to remove" {
            Remove-AutoTaskAPIKey -WarningVariable RemoveWarning -WarningAction SilentlyContinue
            $RemoveWarning | Should -Not -BeNullOrEmpty
        }

        It "Honors -WhatIf" {
            Add-AutoTaskAPIKey -ApiUsername 'user@example.org' -ApiSecretKey 'secret123' -ApiIntegrationCode 'code123'
            Remove-AutoTaskAPIKey -WhatIf
            (Get-AutoTaskAPIKey -AsPlainText).Password | Should -Be 'secret123'
        }

    }

}
