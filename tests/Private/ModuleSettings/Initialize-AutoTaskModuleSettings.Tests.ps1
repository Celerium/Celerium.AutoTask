<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: Initialize-AutoTaskModuleSettings.Tests.ps1
    Type: PowerShell

.SYNOPSIS
    Pester tests for the Initialize-AutoTaskModuleSettings script that runs when the module is imported

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
Describe "Testing [ $CommandName ] script with [ $PesterTestName ]" -Tag @('moduleSettings') {

    Context "[ $CommandName ] testing script" {

        It "When imported WITHOUT a saved configuration baseline variables should exist" {
            Import-TestModule -ModuleName $ModuleName -Version $Version -BuildTarget $BuildTarget
            $AutoTaskModuleUserAgent | Should -Match '^Celerium.AutoTask/'
            $AutoTaskModuleJSONConversionDepth | Should -Be 100
        }

        It "When imported WITH the environment variables the module is configured" {
            $Saved = @{}
            foreach ($Name in 'AUTOTASK_BASE_URI', 'AUTOTASK_API_USERNAME', 'AUTOTASK_API_SECRET', 'AUTOTASK_API_INTEGRATION_CODE') { $Saved[$Name] = [Environment]::GetEnvironmentVariable($Name) }
            try {
                $env:AUTOTASK_BASE_URI              = 'https://env.example.org/atservicesrest'
                $env:AUTOTASK_API_USERNAME          = 'env-user'
                $env:AUTOTASK_API_SECRET            = 'env-secret'
                $env:AUTOTASK_API_INTEGRATION_CODE  = 'env-code'
                Import-TestModule -ModuleName $ModuleName -Version $Version -BuildTarget $BuildTarget -KeepEnvironment

                Get-AutoTaskBaseURI | Should -Be 'https://env.example.org/atservicesrest'
                (Get-AutoTaskAPIKey -AsPlainText).Username | Should -Be 'env-user'
            }
            finally {
                foreach ($Name in $Saved.Keys) { [Environment]::SetEnvironmentVariable($Name, $Saved[$Name]) }
                Remove-AutoTaskAPIKey -WarningAction SilentlyContinue
                Remove-AutoTaskBaseURI -WarningAction SilentlyContinue
            }
        }

        It "Does not convert the OpenAPI spec or create global variables when imported" {
            Import-TestModule -ModuleName $ModuleName -Version $Version -BuildTarget $BuildTarget
            Get-Variable -Name 'AutoTaskModuleSwagger', 'AutoTaskModuleQueries', 'AutoTaskModulePostPatchParameter' -Scope Global -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

    }

}
