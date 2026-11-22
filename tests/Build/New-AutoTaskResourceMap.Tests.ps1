<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: New-AutoTaskResourceMap.Tests.ps1
    Type: PowerShell

.SYNOPSIS
    Pester tests for the build\New-AutoTaskResourceMap.ps1 script

.DESCRIPTION
    Pester tests for the New-AutoTaskResourceMap.ps1 script

    The tests run against a copy of the repository layout in the temp folder so the module folder of the
    repository is never changed

.PARAMETER ModuleName
    The name of the local module to import

    Not used by these tests, the parameter exists because every test file receives the same data

.PARAMETER Version
    The version of the local module to import

    Not used by these tests

.PARAMETER BuildTarget
    Which version of the module to run tests against

    Not used by these tests

.LINK
    https://celerium.org

#>

#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='6.0.0' }

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ModuleName = 'Celerium.AutoTask',

    [Parameter(Mandatory = $false)]
    [string]$Version,

    [Parameter(Mandatory = $false)]
    [string]$BuildTarget
)

BeforeDiscovery {
    $PesterTestName = (Get-Item -Path $PSCommandPath).Name
}

BeforeAll {

    $TestsPath = $PSScriptRoot
    while ($TestsPath -and -not (Test-Path -Path (Join-Path -Path $TestsPath -ChildPath 'TestHelper.ps1'))) { $TestsPath = Split-Path -Path $TestsPath -Parent }
    . (Join-Path -Path $TestsPath -ChildPath 'TestHelper.ps1')

    $RootPath   = Get-TestRootPath
    $RepoPath   = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "Celerium.AutoTask_MapTest_$([guid]::NewGuid().ToString('N'))"
    $ApiCalls   = Join-Path -Path (Join-Path -Path (Join-Path -Path $RepoPath -ChildPath 'Celerium.AutoTask') -ChildPath 'Private') -ChildPath 'ApiCalls'

    New-Item -Path (Join-Path $RepoPath 'build'), $ApiCalls -ItemType Directory -Force > $null
    Copy-Item -Path (Join-Path (Join-Path $RootPath 'build') 'New-AutoTaskResourceMap.ps1') -Destination (Join-Path $RepoPath 'build')
    Copy-Item -Path (Join-Path (Join-Path (Join-Path (Join-Path $RootPath 'Celerium.AutoTask') 'Private') 'ApiCalls') 'Get-AutoTaskSpecOperation.ps1') -Destination $ApiCalls

    $TestScript = Join-Path -Path (Join-Path $RepoPath 'build') -ChildPath 'New-AutoTaskResourceMap.ps1'
    $OutputPath = Join-Path -Path $ApiCalls -ChildPath 'Get-AutoTaskResourceMap.ps1'

    function New-SpecFile {
        param ([string]$Name, [string]$Paths)
        $Path = Join-Path -Path (Join-Path $RepoPath 'Celerium.AutoTask') -ChildPath $Name
        [System.IO.File]::WriteAllText($Path, '{ "swagger": "2.0", "info": { "version": "v1" }, "paths": { ' + $Paths + ' } }')
        return $Path
    }

    New-SpecFile -Name 'AutoTaskAPI-2023.6.json' -Paths '"/V1.0/Things/{id}": { "get": { "tags": [ "Things" ], "operationId": "Things_QueryItem" } }' > $null
    New-SpecFile -Name 'AutoTaskAPI-2023.10.json' -Paths '"/V1.0/Things/{id}": { "get": { "tags": [ "Things" ], "operationId": "Things_QueryItem" }, "delete": { "tags": [ "Things" ], "operationId": "Things_DeleteEntity" } }, "/V1.0/Things/{parentId}/Notes": { "get": { "tags": [ "ThingNotesChild" ], "operationId": "ThingNotesChild_Query" } }' > $null

}

AfterAll {
    if ($RepoPath -and (Test-Path -Path $RepoPath)) { Remove-Item -Path $RepoPath -Recurse -Force -ErrorAction SilentlyContinue }
}

Describe "Testing the [ New-AutoTaskResourceMap ] script with [ $PesterTestName ]" -Tag @('build') {

    It "Creates the resource map from the newest spec in the module folder" {
        $Result = & $TestScript
        $Result.Status | Should -Be 'Created'
        (Split-Path -Path $Result.Spec -Leaf) | Should -Be 'AutoTaskAPI-2023.10.json'
        $Result.Operations | Should -Be 3
        $Result.Resources | Should -Be 2
    }

    It "The resource map function returns every operation" {
        . $OutputPath
        $Script:AutoTaskModuleResourceMap = $null
        $Map = @(Get-AutoTaskResourceMap)
        $Map.Count | Should -Be 3
        $Map[0].Resource | Should -Be 'ThingNotesChild'
        ($Map | Where-Object { $_.Operation -eq 'DeleteEntity' }).Method | Should -Be 'DELETE'
        ($Map | Where-Object { $_.Operation -eq 'DeleteEntity' }).Path | Should -Be '/V1.0/Things/{id}'
    }

    It "Writes UTF-8 without a BOM & with LF line endings" {
        $Bytes = [System.IO.File]::ReadAllBytes($OutputPath)
        $Bytes[0] | Should -Not -Be 0xEF
        [System.Text.Encoding]::UTF8.GetString($Bytes) | Should -Not -Match "`r"
    }

    It "Creates an identical file when it runs again" {
        $Before = (Get-FileHash -Path $OutputPath).Hash
        (& $TestScript).Status | Should -Be 'Unchanged'
        (Get-FileHash -Path $OutputPath).Hash | Should -Be $Before
    }

    It "Does not write anything with -WhatIf" {
        $Before = (Get-FileHash -Path $OutputPath).Hash
        & $TestScript -JsonSpec (Join-Path (Join-Path $RepoPath 'Celerium.AutoTask') 'AutoTaskAPI-2023.6.json') -WhatIf > $null
        (Get-FileHash -Path $OutputPath).Hash | Should -Be $Before
    }

    It "Throws when two operations have the same resource & operation name" {
        $Path = New-SpecFile -Name 'duplicate.json' -Paths '"/V1.0/A": { "get": { "tags": [ "A" ], "operationId": "A_Query" } }, "/V1.0/B": { "get": { "tags": [ "A" ], "operationId": "A_Query" } }'
        { & $TestScript -JsonSpec $Path -WhatIf } | Should -Throw '*same name*'
    }

    It "The committed resource map of the repository is up to date" {
        $Committed  = Join-Path -Path (Join-Path -Path (Join-Path -Path (Join-Path -Path $RootPath -ChildPath 'Celerium.AutoTask') -ChildPath 'Private') -ChildPath 'ApiCalls') -ChildPath 'Get-AutoTaskResourceMap.ps1'
        $Result     = & (Join-Path (Join-Path $RootPath 'build') 'New-AutoTaskResourceMap.ps1') -WhatIf
        $Result.Status | Should -Be 'Unchanged' -Because 'build\New-AutoTaskResourceMap.ps1 must be run after the spec changes'
        $Committed | Should -Exist
    }

}
