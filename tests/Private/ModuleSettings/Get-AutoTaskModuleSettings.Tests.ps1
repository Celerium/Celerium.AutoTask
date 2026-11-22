<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: Get-AutoTaskModuleSettings.Tests.ps1
    Type: PowerShell

.SYNOPSIS
    Pester tests for the Get-AutoTaskModuleSettings function

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

        It "Returns nothing when there is no configuration file" {
            Get-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath | Should -BeNullOrEmpty
        }

        It "Returns the stored configuration with the required values" {
            Set-TestSettings
            Export-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath -WarningAction SilentlyContinue

            $Settings = Get-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath
            $Settings.AutoTaskModuleBaseUri | Should -Be 'https://api.example.org/atservicesrest'
            $Settings.AutoTaskModuleApiUsername | Should -Be 'user@example.org'
        }

        It "Opens the configuration file with -OpenConfigFile" {
            Set-TestSettings
            Export-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath -WarningAction SilentlyContinue
            Mock Invoke-Item -ModuleName $ModuleName {}
            Get-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath -OpenConfigFile
            Should -Invoke Invoke-Item -ModuleName $ModuleName -Times 1 -Exactly
        }

    }

}
