<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: Celerium.AutoTask.Tests.ps1
    Type: PowerShell

        AUTHOR:  David Schulte
        DATE:    2023-04-1
        EMAIL:   celerium@Celerium.org

.SYNOPSIS
    Pester tests for the Celerium.AutoTask module manifest file

.DESCRIPTION
    Pester tests for the Celerium.AutoTask module manifest file

.PARAMETER ModuleName
    The name of the local module to import

    Default value: Celerium.AutoTask

.PARAMETER Version
    The version of the local module to import

    If the 'buildTarget' is set to 'built' this parameter is also used to find the built module

.PARAMETER BuildTarget
    Which version of the module to run tests against

    Allowed values:
        'built', 'notBuilt'

.EXAMPLE
    Invoke-Pester -Path .\Celerium.AutoTask.Tests.ps1

    Runs the tests against the manifest file

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
#Can be used in [ It ] with [ -TestCases @{ VariableName = $VariableName } ]
    BeforeDiscovery{
        $PesterTestName = (Get-Item -Path $PSCommandPath).Name
    }

#Available inside It but NOT Describe or Context
    BeforeAll {

        $TestsPath = $PSScriptRoot
        while ($TestsPath -and -not (Test-Path -Path (Join-Path -Path $TestsPath -ChildPath 'TestHelper.ps1'))) { $TestsPath = Split-Path -Path $TestsPath -Parent }
        . (Join-Path -Path $TestsPath -ChildPath 'TestHelper.ps1')

        $RootPath       = Get-TestRootPath
        $ModulePath     = Get-TestModulePath -ModuleName $ModuleName -Version $Version -BuildTarget $BuildTarget
        $SourcePath     = Join-Path -Path $RootPath -ChildPath $ModuleName

        $ModulePsd1     = Join-Path -Path $ModulePath -ChildPath "$ModuleName.psd1"
        $ModulePsm1     = Join-Path -Path $ModulePath -ChildPath "$ModuleName.psm1"

        Import-TestModule -ModuleName $ModuleName -Version $Version -BuildTarget $BuildTarget

        $Module         = Get-Module -Name $ModuleName | Select-Object * -ExcludeProperty Definition
        $ModuleFiles    = Get-ChildItem -Path $ModulePath -File -Recurse

        # Every function in the source folders is expected to be exposed when the module is imported
        $SourceFiles        = @(Get-ChildItem -Path (Join-Path -Path $SourcePath -ChildPath 'Private'), (Join-Path -Path $SourcePath -ChildPath 'Public') -Filter '*.ps1' -Recurse)
        $SourceFunctions    = foreach ($File in $SourceFiles) {
                                $Ast = [System.Management.Automation.Language.Parser]::ParseFile($File.FullName, [ref]$null, [ref]$null)
                                $Ast.EndBlock.Statements | Where-Object { $_ -is [System.Management.Automation.Language.FunctionDefinitionAst] } | ForEach-Object { $_.Name }
                            }

    }

    AfterAll{
        Remove-TestModule -ModuleName $ModuleName
    }

#EndRegion  [ Prerequisites ]

Describe "Testing the [ $BuildTarget ] version of [ $ModuleName ] with [ $PesterTestName ]" {

    Context "[ $ModuleName.psd1 ] general manifest data" {

        It "Manifest [ RootModule ] has valid data" {
            $Module.RootModule | Should -Be 'Celerium.AutoTask.psm1'
        }

        It "Manifest [ ModuleVersion ] has valid data" {
            $Module.Version | Should -BeGreaterOrEqual $Version
        }

        It "Manifest [ GUID ] has valid data" {
            $Module.GUID | Should -Be 'c12a74ed-2a5a-4ae3-9b41-991f996e15d6'
            $Module.GUID.ToString() | Should -Match '^c12'
        }

        It "Manifest [ Author ] has valid data" {
            $Module.Author | Should -Be 'David Schulte'
        }

        It "Manifest [ CompanyName ] has valid data" {
            $Module.CompanyName | Should -Be 'Celerium'
        }

        It "Manifest [ Copyright ] has valid data" {
            $Module.Copyright | Should -Be 'https://github.com/Celerium/Celerium.AutoTask/blob/main/LICENSE'
        }

        It "Manifest [ Description ] is not empty" {
            $Module.Description | Should -Not -BeNullOrEmpty
        }

        It "Manifest [ PowerShellVersion ] has valid data" {
            $Module.PowerShellVersion | Should -BeGreaterOrEqual '5.1'
        }

        It "Manifest [ NestedModules ] has valid data" {
            switch ($BuildTarget) {
                'built'     { ($Module.NestedModules.Name | Measure-Object).Count | Should -Be 0 }
                'notBuilt'  { ($Module.NestedModules.Name | Measure-Object).Count | Should -Be $SourceFiles.Count }
            }
        }

        It "Manifest [ FunctionsToExport ] exposes every private & public function" {
            $Module.ExportedFunctions.Count | Should -Be $SourceFunctions.Count
            $Module.ExportedFunctions.Keys | Should -Not -Contain $null
            foreach ($Function in $SourceFunctions) {
                $Module.ExportedFunctions.Keys | Should -Contain $Function
            }
        }

        It "Manifest [ FunctionsToExport ] does not use a wildcard" {
            $Manifest = Import-PowerShellDataFile -Path $ModulePsd1
            $Manifest.FunctionsToExport | Should -Not -Contain '*'
            $Manifest.AliasesToExport | Should -Not -Contain '*'
        }

        It "Manifest [ CmdletsToExport ] is empty" {
            ($Module.ExportedCmdlets).Count |  Should -Be 0
        }

        It "Manifest [ VariablesToExport ] is empty" {
            ($Module.ExportedVariables).Count |  Should -Be 0
        }

        It "Manifest [ AliasesToExport ] has valid data" {
            $Module.ExportedAliases.Keys | Should -Contain 'Set-AutoTaskAPIKey'
            $Module.ExportedAliases.Keys | Should -Contain 'Set-AutoTaskBaseURI'
        }

        It "Every alias resolves to an exported function" {
            foreach ($Alias in $Module.ExportedAliases.Values) {
                $Module.ExportedFunctions.Keys | Should -Contain $Alias.ReferencedCommand.Name
            }
        }

        It "Does not export the removed dynamic parameter helpers or global variables" {
            $Module.ExportedFunctions.Keys | Should -Not -Contain New-AutoTaskResourceDynamicParameter
            $Module.ExportedFunctions.Keys | Should -Not -Contain Set-AutoTaskResourceDynamicParameter
            Get-Variable -Name AutoTaskModuleSwagger, AutoTaskModuleQueries, AutoTaskModuleGetParameter -Scope Global -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It "Manifest [ Tags ] has valid data" {
            $Module.PrivateData.PSData.Tags | Should -Contain 'Celerium'
            $Module.PrivateData.PSData.Tags | Should -Contain 'AutoTask'
            ($Module.PrivateData.PSData.Tags).Count | Should -BeGreaterOrEqual 10
        }

        It "Manifest [ LicenseUri ] has valid data" {
            $Module.LicenseUri | Should -Be 'https://github.com/Celerium/Celerium.AutoTask/blob/main/LICENSE'
        }

        It "Manifest [ ProjectUri ] has valid data" {
            $Module.ProjectUri  | Should -Be 'https://github.com/Celerium/Celerium.AutoTask'
        }

        It "Manifest [ IconUri ] has valid data" {
            $Module.IconUri  | Should -Be 'https://raw.githubusercontent.com/Celerium/Celerium.AutoTask/refs/heads/main/.github/images/PoSHGallery_Celerium.AutoTask.png'
        }

        It "Manifest [ ReleaseNotes ] has valid data" {
            $Module.ReleaseNotes  | Should -Be 'https://github.com/Celerium/Celerium.AutoTask/blob/main/README.md'
        }

        It "Manifest [ HelpInfoUri ] is empty" {
            $Module.HelpInfoUri | Should -BeNullOrEmpty
        }

    }

    Context "[ $ModuleName.psd1 ] module import test" {

        It "Module contains only PowerShell files & the OpenAPI spec" {
            # AutoTask is the exception that stores the spec in the module folder, it is copied into the built module
            $Allowed = @('.ps1', '.psm1', '.psd1', '.json')
            ($ModuleFiles | Group-Object Extension).Name | ForEach-Object { $_ | Should -BeIn $Allowed }
        }

        It "Module contains the OpenAPI spec" {
            $SpecFiles = @($ModuleFiles | Where-Object { $_.Extension -eq '.json' })
            $SpecFiles.Count | Should -BeGreaterOrEqual 1
            $SpecFiles | ForEach-Object { $_.Name | Should -BeLike 'AutoTaskAPI-*.json' }
            if ($BuildTarget -eq 'built') {
                $SpecFiles.Count | Should -Be 1
                (Get-FileHash -Path $SpecFiles[0].FullName).Hash | Should -Be (Get-FileHash -Path (Get-TestSpecPath)).Hash
            }
        }

        It "Module files exist" {
            $ModulePsd1 | Should -Exist
            $ModulePsm1 | Should -Exist
        }

        It "Should pass Test-ModuleManifest" {
            $ModulePsd1 | Test-ModuleManifest -ErrorAction SilentlyContinue -ErrorVariable ErrorModuleManifest
            [bool]$ErrorModuleManifest | Should -Be $false
        }

        It "Should import successfully" {
            Import-Module $ModulePsd1 -Force -ErrorAction SilentlyContinue -ErrorVariable ErrorModuleImport
            [bool]$ErrorModuleImport | Should -Be $false
        }

    }

}
