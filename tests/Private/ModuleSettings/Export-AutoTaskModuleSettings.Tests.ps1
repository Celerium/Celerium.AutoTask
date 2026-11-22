<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: Export-AutoTaskModuleSettings.Tests.ps1
    Type: PowerShell

.SYNOPSIS
    Pester tests for the Export-AutoTaskModuleSettings function

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

        It "Throws when the required settings are not set" {
            { Export-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath -WarningAction SilentlyContinue } | Should -Throw '*not set*'
            Test-Path -Path $ExportPath | Should -BeFalse
        }

        It "Should export successfully" {
            Set-TestSettings
            Export-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath -WarningAction SilentlyContinue
            Join-Path -Path $ExportPath -ChildPath 'config.psd1' | Should -Exist
        }

        It "Configuration directory should be hidden on Windows" -Skip:(-not $IsWindowsPlatform) {
            Set-TestSettings
            Export-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath -WarningAction SilentlyContinue
            (Get-Item -Path $ExportPath -Force).Attributes | Should -BeLike '*Hidden*'
        }

        It "Configuration file should contain required values & no plain text secret or integration code" {
            Set-TestSettings
            Export-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath -WarningAction SilentlyContinue

            $ConfigFile = Import-PowerShellDataFile -Path (Join-Path -Path $ExportPath -ChildPath 'config.psd1')
            $ConfigFile.AutoTaskModuleBaseUri               | Should -Be 'https://api.example.org/atservicesrest'
            $ConfigFile.AutoTaskModuleBaseUriApiVersion     | Should -Be 'V1.0'
            $ConfigFile.AutoTaskModuleBaseUriComplete       | Should -Be 'https://api.example.org/atservicesrest/V1.0'
            $ConfigFile.AutoTaskModuleApiUsername           | Should -Be 'user@example.org'
            $ConfigFile.AutoTaskModuleApiSecretKey          | Should -Be 'ENCRYPTEDVALUE'
            $ConfigFile.AutoTaskModuleApiIntegrationCode    | Should -Be 'ENCRYPTEDVALUE'
            $ConfigFile.AutoTaskModuleJSONConversionDepth   | Should -Not -BeNullOrEmpty

            $Content = Get-Content -Path (Join-Path -Path $ExportPath -ChildPath 'config.psd1') -Raw
            $Content | Should -Not -Match 'plain-text-token'
            $Content | Should -Not -Match 'plain-code'
        }

        It "Uses a custom configuration file name" {
            Set-TestSettings
            Export-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath -AutoTaskConfigFile 'MyConfig.psd1' -WarningAction SilentlyContinue
            Join-Path -Path $ExportPath -ChildPath 'MyConfig.psd1' | Should -Exist
        }

    }

}

Describe "Testing the module settings round trip using the Windows Data Protection API with [ $PesterTestName ]" -Tag @('moduleSettings') -Skip:(-not $IsWindowsPlatform) {

    BeforeEach {
        Remove-AutoTaskAPIKey -WarningAction SilentlyContinue
        Remove-AutoTaskBaseURI -WarningAction SilentlyContinue
        if (Test-Path -Path $ExportPath) { Remove-Item -Path $ExportPath -Recurse -Force }
    }

    It "Encrypts & restores the API secret & integration code without mocks" {
        Set-TestSettings
        Export-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath -WarningAction SilentlyContinue
        Get-Content -Path (Join-Path -Path $ExportPath -ChildPath 'config.psd1') -Raw | Should -Not -Match 'plain-text-token|plain-code'

        Remove-AutoTaskAPIKey
        Remove-AutoTaskBaseURI
        Import-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath

        $Key = Get-AutoTaskAPIKey -AsPlainText
        $Key.Password | Should -Be 'plain-text-token'
        $Key.ApiIntegrationCode | Should -Be 'plain-code'
        Get-AutoTaskBaseURI | Should -Be 'https://api.example.org/atservicesrest'
    }

}
