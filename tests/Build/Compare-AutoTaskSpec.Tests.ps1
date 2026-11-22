<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: Compare-AutoTaskSpec.Tests.ps1
    Type: PowerShell

.SYNOPSIS
    Pester tests for the build\Compare-AutoTaskSpec.ps1 script

.DESCRIPTION
    Pester tests for the Compare-AutoTaskSpec.ps1 script

    No online requests are made, small spec files are compared with the -ReferencePath parameter in a
    copy of the repository layout so the spec of the module is never changed

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

    $ScriptPath = Join-Path -Path (Join-Path -Path (Get-TestRootPath) -ChildPath 'build') -ChildPath 'Compare-AutoTaskSpec.ps1'

    # A copy of the repository layout so that -UpdateLocal never touches the real spec
    $RepoPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "Celerium.AutoTask_SpecTest_$([guid]::NewGuid().ToString('N'))"
    New-Item -Path (Join-Path $RepoPath 'build'), (Join-Path $RepoPath 'Celerium.AutoTask') -ItemType Directory -Force > $null
    Copy-Item -Path $ScriptPath -Destination (Join-Path $RepoPath 'build')
    $TestScript = Join-Path -Path (Join-Path $RepoPath 'build') -ChildPath 'Compare-AutoTaskSpec.ps1'

    $BaseSpec = @'
{
  "swagger": "2.0",
  "info": { "version": "v1", "title": "Datto|Autotask PSA Rest API" },
  "paths": {
    "/V1.0/Companies/query": {
      "get": { "tags": [ "Companies" ], "operationId": "Companies_UrlParameterQuery", "parameters": [ { "name": "search", "in": "query", "type": "string" } ], "responses": { "200": { "description": "OK" } } },
      "post": { "tags": [ "Companies" ], "operationId": "Companies_Query", "responses": { "200": { "description": "OK" } } }
    },
    "/V1.0/Companies/{id}": {
      "get": { "tags": [ "Companies" ], "operationId": "Companies_QueryItem", "responses": { "200": { "description": "OK" } } }
    }
  },
  "definitions": { "CompanyModel": { "type": "object", "properties": { "id": { "type": "integer" } } } }
}
'@

    $LocalPath = Join-Path -Path (Join-Path -Path $RepoPath -ChildPath 'Celerium.AutoTask') -ChildPath 'AutoTaskAPI-2023.6.json'
    [System.IO.File]::WriteAllText($LocalPath, $BaseSpec)

    function New-ReferenceSpec {
        # Creates a changed copy of the base spec & returns its path
        param ([string]$Name, [scriptblock]$Change)

        $Spec = $BaseSpec | ConvertFrom-Json
        & $Change $Spec
        $Path = Join-Path -Path $RepoPath -ChildPath $Name
        [System.IO.File]::WriteAllText($Path, ($Spec | ConvertTo-Json -Depth 20))
        return $Path
    }

}

AfterAll {
    if ($RepoPath -and (Test-Path -Path $RepoPath)) { Remove-Item -Path $RepoPath -Recurse -Force -ErrorAction SilentlyContinue }
}

Describe "Testing the [ Compare-AutoTaskSpec ] script with [ $PesterTestName ]" -Tag @('build') {

    Context "Identical specs" {

        It "Uses the newest spec in the module folder" {
            $Copy = Join-Path -Path $RepoPath -ChildPath 'copy.json'
            Copy-Item -Path $LocalPath -Destination $Copy
            $Result = & $TestScript -ReferencePath $Copy
            $Result.LocalPath | Should -Be $LocalPath
            $Result.Identical | Should -BeTrue
            @($Result.AddedEndpoints).Count | Should -Be 0
        }

        It "Reports a spec that only has different formatting as identical" {
            $Reformatted = New-ReferenceSpec -Name 'reformatted.json' -Change { param($S) }
            (Get-FileHash -Path $Reformatted).Hash | Should -Not -Be (Get-FileHash -Path $LocalPath).Hash
            $Result = & $TestScript -ReferencePath $Reformatted
            $Result.Identical | Should -BeTrue
        }

    }

    Context "Different specs" {

        It "Finds an added endpoint" {
            $Path = New-ReferenceSpec -Name 'added.json' -Change { param($S) $S.paths | Add-Member -NotePropertyName '/V2.0/Companies/{id}' -NotePropertyValue ([PSCustomObject]@{ get = [PSCustomObject]@{ tags = @('CompaniesRevised') } }) }
            $Result = & $TestScript -ReferencePath $Path
            $Result.Identical | Should -BeFalse
            $Result.AddedEndpoints | Should -Be @('GET /V2.0/Companies/{id}')
        }

        It "Finds a removed endpoint" {
            $Path = New-ReferenceSpec -Name 'removed.json' -Change { param($S) $S.paths.PSObject.Properties.Remove('/V1.0/Companies/{id}') }
            $Result = & $TestScript -ReferencePath $Path
            $Result.RemovedEndpoints | Should -Be @('GET /V1.0/Companies/{id}')
        }

        It "Finds a changed endpoint & which part changed" {
            $Path = New-ReferenceSpec -Name 'changed.json' -Change { param($S) $S.paths.'/V1.0/Companies/query'.get.parameters[0].name = 'where' }
            $Result = & $TestScript -ReferencePath $Path
            @($Result.ChangedEndpoints).Count | Should -Be 1
            $Result.ChangedEndpoints[0].Endpoint | Should -Be 'GET /V1.0/Companies/query'
            $Result.ChangedEndpoints[0].Changes | Should -Contain 'parameters'
        }

        It "Finds a change of only the case of a tag" {
            $Path = New-ReferenceSpec -Name 'case.json' -Change { param($S) $S.paths.'/V1.0/Companies/{id}'.get.tags = @('companies') }
            $Result = & $TestScript -ReferencePath $Path
            $Result.ChangedEndpoints[0].Changes | Should -Contain 'tags'
        }

        It "Finds a changed swagger definition" {
            $Path = New-ReferenceSpec -Name 'schema.json' -Change { param($S) $S.definitions.CompanyModel.properties | Add-Member -NotePropertyName 'name' -NotePropertyValue ([PSCustomObject]@{ type = 'string' }) }
            $Result = & $TestScript -ReferencePath $Path
            $Result.ChangedSchemas | Should -Be @('definitions/CompanyModel')
        }

        It "Throws with -FailOnDifference" {
            $Path = New-ReferenceSpec -Name 'fail.json' -Change { param($S) $S.paths.PSObject.Properties.Remove('/V1.0/Companies/{id}') }
            { & $TestScript -ReferencePath $Path -FailOnDifference } | Should -Throw '*different*'
        }

        It "Throws when the reference spec does not exist" {
            { & $TestScript -ReferencePath (Join-Path $RepoPath 'missing.json') } | Should -Throw '*not found*'
        }

        It "Throws when the reference is not JSON" {
            $Path = Join-Path -Path $RepoPath -ChildPath 'page.html'
            [System.IO.File]::WriteAllText($Path, '<html>not a spec</html>')
            { & $TestScript -ReferencePath $Path } | Should -Throw '*not valid JSON*'
        }

    }

    Context "Updating the local spec" {

        It "Does not change anything with -WhatIf" {
            $Before = (Get-FileHash -Path $LocalPath).Hash
            $Path = New-ReferenceSpec -Name 'whatif.json' -Change { param($S) $S.paths.PSObject.Properties.Remove('/V1.0/Companies/{id}') }
            & $TestScript -ReferencePath $Path -UpdateLocal -WhatIf > $null
            (Get-FileHash -Path $LocalPath).Hash | Should -Be $Before
        }

        It "Replaces the local spec & copies the old spec to the archive" {
            $Before = (Get-FileHash -Path $LocalPath).Hash
            $Path = New-ReferenceSpec -Name 'update.json' -Change { param($S) $S.paths.PSObject.Properties.Remove('/V1.0/Companies/{id}') }

            $Result = & $TestScript -ReferencePath $Path -UpdateLocal

            $Result.Updated | Should -BeTrue
            (Get-FileHash -Path $LocalPath).Hash | Should -Be (Get-FileHash -Path $Path).Hash
            $Result.ArchivePath | Should -Exist
            (Get-FileHash -Path $Result.ArchivePath).Hash | Should -Be $Before
        }

        It "Does not touch the spec of the repository" {
            $RealSpec = Get-TestSpecPath
            $RealSpec | Should -Exist
            (Get-Item -Path $RealSpec).Length | Should -BeGreaterThan 1000000
        }

    }

}
