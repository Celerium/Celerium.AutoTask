<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: Remove-AutoTaskModuleSettings.Tests.ps1
    Type: PowerShell

.SYNOPSIS
    Pester tests for the Remove-AutoTaskModuleSettings function

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

    $ExportPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "Celerium.AutoTask_Test_$([guid]::NewGuid().ToString('N'))"

    function Set-TestSettings {
        Add-AutoTaskBaseURI -BaseURI 'https://api.example.org/atservicesrest'
        Add-AutoTaskAPIKey -ApiUsername 'user@example.org' -ApiSecretKey 'plain-text-token' -ApiIntegrationCode 'plain-code'
    }

    function Set-TestSecureStringMock {
        # The SecureString encryption cmdlets are mocked so that the tests behave the same on Windows, Linux, & macOS
        Mock ConvertFrom-SecureString -ModuleName $ModuleName { 'ENCRYPTEDVALUE' }
        Mock ConvertTo-SecureString -ModuleName $ModuleName { Microsoft.PowerShell.Security\ConvertTo-SecureString @PesterBoundParameters }
        Mock ConvertTo-SecureString -ModuleName $ModuleName -ParameterFilter { -not $AsPlainText } {
            Microsoft.PowerShell.Security\ConvertTo-SecureString -String 'restored-token' -AsPlainText -Force
        }
    }
}

AfterAll {
    if (Test-Path -Path $ExportPath) { Remove-Item -Path $ExportPath -Recurse -Force }
    Remove-TestModule -ModuleName $ModuleName
}

BeforeDiscovery {
    $PesterTestName = (Get-Item -Path $PSCommandPath).Name
    $CommandName = $PesterTestName -replace '.Tests.ps1',''
    $IsWindowsPlatform = ($PSEdition -eq 'Desktop' -or $IsWindows)
}
Describe "Testing [ $CommandName ] function with [ $PesterTestName ]" -Tag @('moduleSettings') {

    BeforeEach {
        Remove-AutoTaskAPIKey -WarningAction SilentlyContinue
        Remove-AutoTaskBaseURI -WarningAction SilentlyContinue
        if (Test-Path -Path $ExportPath) { Remove-Item -Path $ExportPath -Recurse -Force }
        Set-TestSecureStringMock
    }
    Context "[ $CommandName ] testing function" {

        It "No configuration should throw a warning" {
            Remove-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath -WarningVariable RemoveWarning -WarningAction SilentlyContinue
            $RemoveWarning | Should -Not -BeNullOrEmpty
        }

        It "Honors -WhatIf" {
            New-Item -Path $ExportPath -ItemType Directory -Force > $null
            Remove-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath -WhatIf
            Test-Path -Path $ExportPath | Should -BeTrue
        }

        It "Saved configuration should be removed" {
            Set-TestSettings
            Export-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath -WarningAction SilentlyContinue
            Remove-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath | Out-Null
            Test-Path -Path $ExportPath | Should -BeFalse
        }

        It "Saved configuration & variables should be removed" {
            Set-TestSettings
            Export-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath -WarningAction SilentlyContinue

            Remove-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath -AndVariables | Out-Null

            Test-Path -Path $ExportPath | Should -BeFalse
            Get-AutoTaskBaseURI -WarningAction SilentlyContinue | Should -BeNullOrEmpty
            Get-AutoTaskAPIKey -WarningAction SilentlyContinue | Should -BeNullOrEmpty
        }

    }

}
