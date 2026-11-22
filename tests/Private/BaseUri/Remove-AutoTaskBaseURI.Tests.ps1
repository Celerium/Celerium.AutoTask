<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: Remove-AutoTaskBaseURI.Tests.ps1
    Type: PowerShell

.SYNOPSIS
    Pester tests for the Remove-AutoTaskBaseURI function

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
    }

    Context "[ $CommandName ] testing function" {

        It "The base URI variables should no longer exist" {
            Add-AutoTaskBaseURI -BaseURI 'https://api.example.org/atservicesrest'
            Remove-AutoTaskBaseURI
            foreach ($Name in 'AutoTaskModuleBaseUri', 'AutoTaskModuleBaseUriApiVersion', 'AutoTaskModuleBaseUriComplete') {
                Get-Variable -Name $Name -Scope Global -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            }
        }

        It "If the base URI is already gone a warning should be thrown" {
            Remove-AutoTaskBaseURI -WarningVariable RemoveWarning -WarningAction SilentlyContinue
            $RemoveWarning | Should -Not -BeNullOrEmpty
        }

        It "Honors -WhatIf" {
            Add-AutoTaskBaseURI -BaseURI 'https://api.example.org/atservicesrest'
            Remove-AutoTaskBaseURI -WhatIf
            Get-AutoTaskBaseURI | Should -Be 'https://api.example.org/atservicesrest'
        }

    }

}
