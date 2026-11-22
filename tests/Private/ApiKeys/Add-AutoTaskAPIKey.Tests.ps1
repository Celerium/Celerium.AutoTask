<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: Add-AutoTaskAPIKey.Tests.ps1
    Type: PowerShell

.SYNOPSIS
    Pester tests for the Add-AutoTaskAPIKey function

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
}

AfterAll {
    Remove-TestModule -ModuleName $ModuleName
}

BeforeDiscovery {
    $PesterTestName = (Get-Item -Path $PSCommandPath).Name
    $CommandName = $PesterTestName -replace '.Tests.ps1',''
}

Describe "Testing [ $CommandName ] function with [ $PesterTestName ]" -Tag @('apiKeys') {

    BeforeEach {
        Remove-AutoTaskAPIKey -WarningAction SilentlyContinue
    }

    Context "[ $CommandName ] testing function" {

        It "Should have an alias of [ Set-AutoTaskAPIKey ]" {
            (Get-Alias -Name Set-AutoTaskAPIKey).ReferencedCommand.Name | Should -Be 'Add-AutoTaskAPIKey'
        }

        It "Stores the username & integration code as plain text & the secret as a SecureString" {
            Add-AutoTaskAPIKey -ApiUsername 'user@example.org' -ApiSecretKey 'secret123' -ApiIntegrationCode 'code123'
            $Key = Get-AutoTaskAPIKey
            $Key.Username | Should -BeExactly 'user@example.org'
            $Key.ApiIntegrationCode | Should -BeExactly 'code123'
            $Key.Password | Should -BeOfType [System.Security.SecureString]
        }

        It "Should accept the secret from the pipeline" {
            'secret123' | Add-AutoTaskAPIKey -ApiUsername 'user@example.org' -ApiIntegrationCode 'code123'
            (Get-AutoTaskAPIKey -AsPlainText).Password | Should -Be 'secret123'
        }

        It "Should accept a SecureString secret" {
            $Secure = ConvertTo-SecureString 'secure123' -AsPlainText -Force
            Add-AutoTaskAPIKey -ApiUsername 'user@example.org' -ApiKeySecureString $Secure -ApiIntegrationCode 'code123'
            (Get-AutoTaskAPIKey -AsPlainText).Password | Should -Be 'secure123'
        }

        It "Prompts for the secret when none is provided" {
            Mock Read-Host -ModuleName $ModuleName { ConvertTo-SecureString 'prompted' -AsPlainText -Force }
            Add-AutoTaskAPIKey -ApiUsername 'user@example.org' -ApiIntegrationCode 'code123'
            (Get-AutoTaskAPIKey -AsPlainText).Password | Should -Be 'prompted'
            Should -Invoke Read-Host -ModuleName $ModuleName -Times 1 -Exactly
        }

        It "Does not write the prompt text to the output" {
            Mock Read-Host -ModuleName $ModuleName { ConvertTo-SecureString 'prompted' -AsPlainText -Force }
            Add-AutoTaskAPIKey -ApiUsername 'user@example.org' -ApiIntegrationCode 'code123' | Should -BeNullOrEmpty
        }

        It "Requires the [ <_> ] parameter" -ForEach 'ApiUsername', 'ApiIntegrationCode' {
            (Get-Command -Name Add-AutoTaskAPIKey).Parameters[$_].Attributes.Mandatory | Should -Contain $true
        }

        It "Replaces existing values" {
            Add-AutoTaskAPIKey -ApiUsername 'user1' -ApiSecretKey 'first' -ApiIntegrationCode 'code1'
            Add-AutoTaskAPIKey -ApiUsername 'user2' -ApiSecretKey 'second' -ApiIntegrationCode 'code2'
            $Key = Get-AutoTaskAPIKey -AsPlainText
            $Key.Username | Should -Be 'user2'
            $Key.Password | Should -Be 'second'
            $Key.ApiIntegrationCode | Should -Be 'code2'
        }

    }

}
