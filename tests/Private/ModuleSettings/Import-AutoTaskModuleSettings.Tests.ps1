<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: Import-AutoTaskModuleSettings.Tests.ps1
    Type: PowerShell

.SYNOPSIS
    Pester tests for the Import-AutoTaskModuleSettings function

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

        It "No configuration should populate baseline variables" {
            Import-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath
            $AutoTaskModuleUserAgent | Should -Match '^Celerium.AutoTask/'
            $AutoTaskModuleJSONConversionDepth | Should -Be 100
        }

        It "Saved configuration session should contain required variables" {
            Set-TestSettings
            Export-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath -WarningAction SilentlyContinue
            Remove-AutoTaskAPIKey
            Remove-AutoTaskBaseURI

            Import-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath

            Get-AutoTaskBaseURI | Should -Be 'https://api.example.org/atservicesrest'
            Get-AutoTaskBaseURI -AndApiUri | Should -Be 'https://api.example.org/atservicesrest/V1.0'
            $Key = Get-AutoTaskAPIKey -AsPlainText
            $Key.Username | Should -Be 'user@example.org'
            $Key.Password | Should -Be 'restored-token'
            $Key.ApiIntegrationCode | Should -Be 'restored-token'
        }

        It "Saved configuration session should NOT contain temp variables" {
            Set-TestSettings
            Export-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath -WarningAction SilentlyContinue
            Import-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath
            Get-Variable -Name 'TempConfig' -Scope Global -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It "Reads the plain text integration code of a version 1.x configuration file" {
            Mock ConvertTo-SecureString -ModuleName $ModuleName -ParameterFilter { -not $AsPlainText -and $String -eq 'legacy-code' } { throw 'not encrypted' }
            New-Item -Path $ExportPath -ItemType Directory -Force > $null
            Set-Content -Path (Join-Path -Path $ExportPath -ChildPath 'config.psd1') -Value "@{ AutoTaskModuleBaseUri = 'https://api.example.org/atservicesrest'; AutoTaskModuleApiUsername = 'user'; AutoTaskModuleApiSecretKey = 'ENCRYPTED'; AutoTaskModuleApiIntegrationCode = 'legacy-code'; AutoTaskModuleUserAgent = 'old'; AutoTaskModuleJSONConversionDepth = '100' }"

            Import-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath

            (Get-AutoTaskAPIKey -AsPlainText).ApiIntegrationCode | Should -Be 'legacy-code'
            $AutoTaskModuleUserAgent | Should -Match '^Celerium.AutoTask/'
        }

        It "Warns instead of failing when the configuration file is corrupt" {
            New-Item -Path $ExportPath -ItemType Directory -Force > $null
            Set-Content -Path (Join-Path -Path $ExportPath -ChildPath 'config.psd1') -Value 'this is not a data file'
            Import-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath -WarningVariable ImportWarning -WarningAction SilentlyContinue
            $ImportWarning | Should -Not -BeNullOrEmpty
        }

        It "Uses the environment variables" {
            $Saved = @{}
            foreach ($Name in 'AUTOTASK_BASE_URI', 'AUTOTASK_API_USERNAME', 'AUTOTASK_API_SECRET', 'AUTOTASK_API_INTEGRATION_CODE') { $Saved[$Name] = [Environment]::GetEnvironmentVariable($Name) }
            try {
                $env:AUTOTASK_BASE_URI              = 'https://env.example.org/atservicesrest/'
                $env:AUTOTASK_API_USERNAME          = 'env-user'
                $env:AUTOTASK_API_SECRET            = 'env-secret'
                $env:AUTOTASK_API_INTEGRATION_CODE  = 'env-code'
                Import-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath

                Get-AutoTaskBaseURI | Should -Be 'https://env.example.org/atservicesrest'
                $Key = Get-AutoTaskAPIKey -AsPlainText
                $Key.Username | Should -Be 'env-user'
                $Key.Password | Should -Be 'env-secret'
                $Key.ApiIntegrationCode | Should -Be 'env-code'
            }
            finally { foreach ($Name in $Saved.Keys) { [Environment]::SetEnvironmentVariable($Name, $Saved[$Name]) } }
        }

        It "Warns & does not load the API values when an API environment variable is missing" {
            $Saved = @{}
            foreach ($Name in 'AUTOTASK_API_USERNAME', 'AUTOTASK_API_SECRET', 'AUTOTASK_API_INTEGRATION_CODE') { $Saved[$Name] = [Environment]::GetEnvironmentVariable($Name) }
            try {
                $env:AUTOTASK_API_USERNAME          = 'env-user'
                $env:AUTOTASK_API_SECRET            = 'env-secret'
                $env:AUTOTASK_API_INTEGRATION_CODE  = $null
                Import-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath -WarningVariable KeyWarning -WarningAction SilentlyContinue

                $KeyWarning | Should -Not -BeNullOrEmpty
                Get-AutoTaskAPIKey -WarningAction SilentlyContinue | Should -BeNullOrEmpty
            }
            finally { foreach ($Name in $Saved.Keys) { [Environment]::SetEnvironmentVariable($Name, $Saved[$Name]) } }
        }

        It "Warns when the base uri environment variable is not valid" {
            $Saved = $env:AUTOTASK_BASE_URI
            try {
                $env:AUTOTASK_BASE_URI = 'http://insecure.example.org'
                Import-AutoTaskModuleSettings -AutoTaskConfigPath $ExportPath -WarningVariable EnvWarning -WarningAction SilentlyContinue
                $EnvWarning | Should -Not -BeNullOrEmpty
                Get-AutoTaskBaseURI -WarningAction SilentlyContinue | Should -BeNullOrEmpty
            }
            finally { $env:AUTOTASK_BASE_URI = $Saved }
        }

    }

}
