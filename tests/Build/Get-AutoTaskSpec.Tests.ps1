<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: Get-AutoTaskSpec.Tests.ps1
    Type: PowerShell

.SYNOPSIS
    Pester tests for the build\Get-AutoTaskSpec.ps1 script

.DESCRIPTION
    Pester tests for the Get-AutoTaskSpec.ps1 script

    No online requests are made, small spec files are used with the -ReferencePath parameter. The tests run
    against a copy of the repository layout in the temp folder so the module folder of the repository is never changed

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

    $BuildPath = Join-Path -Path (Get-TestRootPath) -ChildPath 'build'

    $RepoPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "Celerium.AutoTask_GetSpecTest_$([guid]::NewGuid().ToString('N'))"
    New-Item -Path (Join-Path $RepoPath 'build'), (Join-Path $RepoPath 'Celerium.AutoTask') -ItemType Directory -Force > $null
    Copy-Item -Path (Join-Path $BuildPath 'Get-AutoTaskSpec.ps1'), (Join-Path $BuildPath 'Compare-AutoTaskSpec.ps1') -Destination (Join-Path $RepoPath 'build')

    $GetScript      = Join-Path -Path (Join-Path $RepoPath 'build') -ChildPath 'Get-AutoTaskSpec.ps1'
    $CompareScript  = Join-Path -Path (Join-Path $RepoPath 'build') -ChildPath 'Compare-AutoTaskSpec.ps1'
    $SpecFolder     = Join-Path -Path $RepoPath -ChildPath 'Celerium.AutoTask'

    function New-SpecFile {
        # Creates a small spec file & returns its path
        param ([string]$Name, [string]$Extra = '')

        $Json = '{ "swagger": "2.0", "info": { "version": "v1", "title": "Datto|Autotask PSA Rest API" }, "paths": { "/V1.0/Companies/{id}": { "get": { "tags": [ "Companies' + $Extra + '" ] } } } }'
        $Path = Join-Path -Path $RepoPath -ChildPath $Name
        [System.IO.File]::WriteAllText($Path, $Json)
        return $Path
    }

}

AfterAll {
    if ($RepoPath -and (Test-Path -Path $RepoPath)) { Remove-Item -Path $RepoPath -Recurse -Force -ErrorAction SilentlyContinue }
}

Describe "Testing the [ Get-AutoTaskSpec ] script with [ $PesterTestName ]" -Tag @('build') {

    Context "File name" {

        It "Saves the spec as {product}-{version}.json in the module folder" {
            $Result = & $GetScript -ReferencePath (New-SpecFile -Name 'ref1.json') -SpecVersion '2026.1'
            $Result.Status | Should -Be 'Created'
            $Result.Path | Should -Be (Join-Path -Path $SpecFolder -ChildPath 'AutoTaskAPI-2026.1.json')
            $Result.Path | Should -Exist
            $Result.Endpoints | Should -Be 1
        }

        It "Uses the year & month as the default version" {
            $Result = & $GetScript -ReferencePath (New-SpecFile -Name 'ref2.json') -WhatIf
            (Split-Path -Path $Result.Path -Leaf) | Should -Be "AutoTaskAPI-$(Get-Date -Format 'yyyy.M').json"
        }

        It "Uses a custom product name" {
            $Result = & $GetScript -ReferencePath (New-SpecFile -Name 'ref3.json') -Product 'Example' -SpecVersion '1.0'
            (Split-Path -Path $Result.Path -Leaf) | Should -Be 'Example-1.0.json'
        }

        It "Rejects a version that is not safe in a file name" {
            { & $GetScript -ReferencePath (New-SpecFile -Name 'ref4.json') -SpecVersion '3.0/beta?' } | Should -Throw
        }

        It "Saves the spec exactly as it was downloaded" {
            $Reference = New-SpecFile -Name 'ref5.json'
            $Result = & $GetScript -ReferencePath $Reference -SpecVersion '2026.5'
            (Get-FileHash -Path $Result.Path).Hash | Should -Be (Get-FileHash -Path $Reference).Hash
        }

    }

    Context "Existing files" {

        It "Does not change a file that is identical" {
            $Reference = New-SpecFile -Name 'ref6.json'
            & $GetScript -ReferencePath $Reference -SpecVersion '2026.6' > $null
            $Before = (Get-Item -Path (Join-Path $SpecFolder 'AutoTaskAPI-2026.6.json')).LastWriteTimeUtc

            $Result = & $GetScript -ReferencePath $Reference -SpecVersion '2026.6'

            $Result.Status | Should -Be 'Unchanged'
            $Result.ArchivePath | Should -BeNullOrEmpty
            (Get-Item -Path $Result.Path).LastWriteTimeUtc | Should -Be $Before
        }

        It "Copies a different file with the same name to the archive before it is replaced" {
            & $GetScript -ReferencePath (New-SpecFile -Name 'ref7a.json') -SpecVersion '2026.7' > $null
            $Original = (Get-FileHash -Path (Join-Path $SpecFolder 'AutoTaskAPI-2026.7.json')).Hash

            $New    = New-SpecFile -Name 'ref7b.json' -Extra 'Changed'
            $Result = & $GetScript -ReferencePath $New -SpecVersion '2026.7'

            $Result.Status | Should -Be 'Replaced'
            (Get-FileHash -Path $Result.Path).Hash | Should -Be (Get-FileHash -Path $New).Hash
            $Result.ArchivePath | Should -Exist
            (Get-FileHash -Path $Result.ArchivePath).Hash | Should -Be $Original
        }

        It "Does not write anything with -WhatIf" {
            & $GetScript -ReferencePath (New-SpecFile -Name 'ref8.json') -SpecVersion '2026.8' -WhatIf > $null
            (Join-Path $SpecFolder 'AutoTaskAPI-2026.8.json') | Should -Not -Exist
        }

    }

    Context "Validation" {

        It "Throws when the reference file does not exist" {
            { & $GetScript -ReferencePath (Join-Path $RepoPath 'missing.json') } | Should -Throw '*not found*'
        }

        It "Throws when the file is not valid JSON" {
            $Path = Join-Path -Path $RepoPath -ChildPath 'bad.json'
            [System.IO.File]::WriteAllText($Path, '{ "swagger": "2.0", ')
            { & $GetScript -ReferencePath $Path } | Should -Throw '*not valid JSON*'
        }

        It "Throws when an HTML page is returned instead of a spec" {
            $Path = Join-Path -Path $RepoPath -ChildPath 'page.html'
            [System.IO.File]::WriteAllText($Path, '<html>not a spec</html>')
            { & $GetScript -ReferencePath $Path } | Should -Throw '*not valid JSON*'
        }

        It "Throws when the file is not an OpenAPI spec" {
            $Path = Join-Path -Path $RepoPath -ChildPath 'notspec.json'
            [System.IO.File]::WriteAllText($Path, '{ "hello": "world" }')
            { & $GetScript -ReferencePath $Path } | Should -Throw '*not an OpenAPI spec*'
        }

        It "Throws when the spec does not have paths" {
            $Path = Join-Path -Path $RepoPath -ChildPath 'nopaths.json'
            [System.IO.File]::WriteAllText($Path, '{ "swagger": "2.0", "info": { "title": "x", "version": "v1" }, "paths": {} }')
            { & $GetScript -ReferencePath $Path } | Should -Throw '*any paths*'
        }

    }

    Context "Newest spec" {

        It "Is used by Compare-AutoTaskSpec.ps1 when more than one spec is in the module folder" {
            # The module folder now has the 1.0 (Example), 2026.1, 2026.5, 2026.6, & 2026.7 files, 2026.7 is the newest
            $Newest = Join-Path -Path $SpecFolder -ChildPath 'AutoTaskAPI-2026.7.json'
            $Result = & $CompareScript -ReferencePath $Newest
            $Result.LocalPath | Should -Be $Newest
            $Result.Identical | Should -BeTrue
        }

    }

}
