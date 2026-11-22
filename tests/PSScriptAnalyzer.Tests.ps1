<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: PSScriptAnalyzer.Tests.ps1
    Type: PowerShell

        AUTHOR:  David Schulte
        EMAIL:   celerium@Celerium.org

.SYNOPSIS
    Pester tests for PSScriptAnalyzer rules against the module files

.DESCRIPTION
    Pester tests that run PSScriptAnalyzer once against the module folder
    and then verify that every file has no warnings or errors

.PARAMETER ModuleName
    The name of the local module to import

    Default value: Celerium.AutoTask

.PARAMETER Version
    The version of the local module to import

.PARAMETER BuildTarget
    Which version of the module to run tests against

    Allowed values:
        'built', 'notBuilt'

.EXAMPLE
    Invoke-Pester -Path .\PSScriptAnalyzer.Tests.ps1

.INPUTS
    N/A

.OUTPUTS
    N/A

.LINK
    https://celerium.org

#>

<############################################################################################
                                        Code
############################################################################################>
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='6.0.0' }

#Region     [ Parameters ]

#Available in Discovery & Run
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

#EndRegion  [ Parameters ]

#Region     [ Prerequisites ]

    BeforeDiscovery{

        $TestsPath = $PSScriptRoot
        while ($TestsPath -and -not (Test-Path -Path (Join-Path -Path $TestsPath -ChildPath 'TestHelper.ps1'))) { $TestsPath = Split-Path -Path $TestsPath -Parent }
        . (Join-Path -Path $TestsPath -ChildPath 'TestHelper.ps1')

        $PesterTestName = (Get-Item -Path $PSCommandPath).Name
        $ModulePath = Get-TestModulePath -ModuleName $ModuleName -Version $Version -BuildTarget $BuildTarget

        $ModuleFiles = @(Get-ChildItem -Path $ModulePath -Include *.ps1, *.psm1, *.psd1 -Recurse | ForEach-Object {
            # Pester only exposes the keys of hashtables as variables in -ForEach tests
            @{ Name = $_.Name; FullName = $_.FullName }
        })

    }

    BeforeAll {

        $TestsPath = $PSScriptRoot
        while ($TestsPath -and -not (Test-Path -Path (Join-Path -Path $TestsPath -ChildPath 'TestHelper.ps1'))) { $TestsPath = Split-Path -Path $TestsPath -Parent }
        . (Join-Path -Path $TestsPath -ChildPath 'TestHelper.ps1')

        $ModulePath = Get-TestModulePath -ModuleName $ModuleName -Version $Version -BuildTarget $BuildTarget

        $AnalyzerParams = @{
            Path        = $ModulePath
            Recurse     = $true
            ExcludeRule = 'PSUseSingularNouns', 'PSAvoidUsingConvertToSecureStringWithPlainText', 'PSAvoidUsingPlainTextForPassword', 'PSAvoidUsingUsernameAndPasswordParams'
            Severity    = 'Warning', 'Error'
        }
        $AnalyzerResults = @(Invoke-ScriptAnalyzer @AnalyzerParams)

    }

#EndRegion  [ Prerequisites ]

Describe "Testing the [ $BuildTarget ] version of [ $ModuleName ] with [ $PesterTestName ]" {

    Context "[ $ModuleName ] module PSScriptAnalyzer tests" {

        It "Should have no findings in [ <Name> ]" -ForEach $ModuleFiles {

            $FileResults = @($AnalyzerResults | Where-Object { $_.ScriptPath -eq $FullName })

            $Summary = ($FileResults | ForEach-Object { "$($_.RuleName) (line $($_.Line)): $($_.Message)" }) -join "`n"
            $FileResults.Count | Should -Be 0 -Because "PSScriptAnalyzer found:`n$Summary"

        }

    }

}
