<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: HelpComment.Tests.ps1
    Type: PowerShell

        AUTHOR:  David Schulte
        EMAIL:   celerium@Celerium.org

.SYNOPSIS
    Pester tests for the comment based help of every function in the module

.DESCRIPTION
    Pester tests for the comment based help of every function in the module

    The link tests make web requests & are tagged with 'Online' so they are
    excluded unless the GitHub pages site has been published

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
    Invoke-Pester -Path .\HelpComment.Tests.ps1

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

#Available in Describe and Context but NOT It
    BeforeDiscovery{

        $TestsPath = $PSScriptRoot
        while ($TestsPath -and -not (Test-Path -Path (Join-Path -Path $TestsPath -ChildPath 'TestHelper.ps1'))) { $TestsPath = Split-Path -Path $TestsPath -Parent }
        . (Join-Path -Path $TestsPath -ChildPath 'TestHelper.ps1')

        $PesterTestName = (Get-Item -Path $PSCommandPath).Name

        Import-TestModule -ModuleName $ModuleName -Version $Version -BuildTarget $BuildTarget

        $ModuleFunctions = @( (Get-Module -Name $ModuleName).ExportedFunctions.Keys | Sort-Object )

    }

    BeforeAll {

        $TestsPath = $PSScriptRoot
        while ($TestsPath -and -not (Test-Path -Path (Join-Path -Path $TestsPath -ChildPath 'TestHelper.ps1'))) { $TestsPath = Split-Path -Path $TestsPath -Parent }
        . (Join-Path -Path $TestsPath -ChildPath 'TestHelper.ps1')

    }

    AfterAll{
        Remove-TestModule -ModuleName $ModuleName
    }

#EndRegion  [ Prerequisites ]

Describe "Testing the [ $BuildTarget ] version of [ $ModuleName ] with [ $PesterTestName ]" {

    Describe "[ $ModuleName ] module help tests" -ForEach $ModuleFunctions {

        BeforeDiscovery {

            $FunctionName   = $_
            $HelpFunction  = Get-Help -Name $FunctionName -Full

            $ShouldProcessParameters = 'WhatIf', 'Confirm'

            $HelpParameters = [System.Collections.Generic.List[object]]::new()
            $HelpFunction.parameters.parameter |
                Where-Object { $_.Name -and $_.Name -notin $ShouldProcessParameters } |
                    ForEach-Object {
                        $HelpParameters.Add([PSCustomObject]@{
                            name            = $_.name
                            description     = ($_.description.Text -join '').Trim()
                        }) > $null
                    }

            $HelpExamples = [System.Collections.Generic.List[object]]::new()
            $HelpFunction.Examples.Example |
                ForEach-Object {
                    $HelpExamples.Add([PSCustomObject]@{
                        code    = $_.code
                        remarks = ($_.remarks.Text -join '').Trim()
                        title   = ($_.title -replace '-','')
                    }) > $null
                }

            $HelpLinks = @($HelpFunction.relatedLinks.navigationLink.uri | Where-Object { $_ })

        }

        Context "[ $FunctionName ]" -ForEach @{ FunctionName = $FunctionName; HelpFunction = $HelpFunction; HelpParameters = $HelpParameters; HelpExamples = $HelpExamples; HelpLinks = $HelpLinks } {

            It "[ $FunctionName ] contains comment based help" {
                $HelpFunction | Should -Not -BeNullOrEmpty
            }

            It "[ $FunctionName ] contains a synopsis" {
                $HelpFunction.Synopsis | Should -Not -BeNullOrEmpty
            }

            It "[ $FunctionName ] contains a description" {
                $HelpFunction.Description | Should -Not -BeNullOrEmpty
            }

            It "[ $FunctionName ] contains at least one usage example" {
                $HelpFunction.Examples | Should -Not -BeNullOrEmpty
                ($HelpFunction.Examples.Example | Measure-Object).Count | Should -BeGreaterOrEqual 1
            }

            It "[ $FunctionName ] contains a note" {
                $HelpFunction.alertSet.alert.text -split '\n' | Should -Not -BeNullOrEmpty
            }

            It "[ $FunctionName ] contains a link" {
                $HelpLinks | Should -Not -BeNullOrEmpty
            }

            It "[ $FunctionName ] link should return 200" -Tag 'Online' {
                foreach ($Uri in $HelpLinks) {
                    $Status = try { (Invoke-WebRequest -Uri $Uri -UseBasicParsing -ErrorAction Stop).StatusCode } catch { [int]$_.Exception.Response.StatusCode }
                    $Status | Should -Be 200 -Because "[ $Uri ] should be reachable"
                }
            }

            It "[ $FunctionName ] - All parameters have a description" {
                if ($HelpParameters.Count -eq 0) { Set-ItResult -Skipped -Because "there are no parameters in this function"; return }
                $Missing = @($HelpParameters | Where-Object { -not $_.description } | ForEach-Object { $_.name })
                $Missing | Should -BeNullOrEmpty -Because "[ $($Missing -join ', ') ] should have a description"
            }

            It "[ $FunctionName ] - All examples have example code & a description" {
                $Missing = @($HelpExamples | Where-Object { -not $_.code -or -not $_.remarks } | ForEach-Object { $_.title })
                $Missing | Should -BeNullOrEmpty -Because "[ $($Missing -join ', ') ] should have example code & a description"
            }

        }

    }

}
