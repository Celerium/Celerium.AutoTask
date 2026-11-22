function Update-HelpContent {
<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: Update-HelpContent.ps1
    Type: PowerShell

        AUTHOR:  David Schulte
        DATE:    2022-11-26
        EMAIL:   celerium@celerium.org
        Updated: 2026-11-21

    TODO:

.SYNOPSIS
    Updates or creates markdown help files

.DESCRIPTION
    The Update-HelpContent script updates or creates markdown help files which are
    used by both GitHub pages and as external help.

    The markdown documents created contain metadata that GitHub pages directly use
    to build its entire documentation structure\site.

    The help files are created with the Microsoft.PowerShell.PlatyPS module (the successor of the
    legacy platyPS module) which works on Windows, Linux, & macOS

        - docs\<ModuleName>.md                  - Module page
        - docs\site\<Category>\<Function>.md    - One page per function
        - docs\site\<Category>\<METHOD>.md      - GitHub pages navigation pages
        - docs\site\<Category>\index.md         - Category page with the implemented endpoint counts
        - docs\en-US\<ModuleName>-Help.xml      - External (MAML) help

    Microsoft.PowerShell.PlatyPS does not create cab files, no cab files are created

.PARAMETER ModuleName
    The name of the module to generate help documents for

    Example: Celerium.AutoTask

.PARAMETER HelpDocsPath
    Location to store the markdown help docs

    All markdown help docs should be located outside the module folder.
    Reference:
        Yes - "Celerium.AutoTask\docs"
        NO  - "Celerium.AutoTask\Celerium.AutoTask\docs"

    Example: "C:\Celerium\Projects\Celerium.AutoTask\docs"

.PARAMETER CsvFilePath
    Location where the tracking CSV is located including the CSV file name

    The tracking CSV should be located in "Celerium.AutoTask\docs"
    Reference:
        Yes - "Celerium.AutoTask\docs\endpoints.csv"
        NO  - "Celerium.AutoTask\Celerium.AutoTask\docs\endpoints.csv"

    Example: "C:\Celerium\Projects\Celerium.AutoTask\docs\endpoints.csv"

.PARAMETER GithubPageUri
    Base url of the modules github pages

    Example: "https://celerium.github.io/Celerium.AutoTask"

.PARAMETER ShowHelpDocs
    Opens the directory with the HelpDocs when completed

.EXAMPLE
    Update-HelpContent -ModuleName Celerium.AutoTask -HelpDocsPath "C:\Celerium\Projects\Celerium.AutoTask\docs" -CsvFilePath "C:\Celerium\Projects\Celerium.AutoTask\docs\endpoints.csv" -GithubPageUri "https://celerium.github.io/Celerium.AutoTask"

    Updates markdown docs and external help files

.EXAMPLE
    Update-HelpContent -ModuleName Celerium.AutoTask -HelpDocsPath "C:\Celerium\Projects\Celerium.AutoTask\docs" -CsvFilePath "C:\Celerium\Projects\Celerium.AutoTask\docs\endpoints.csv" -GithubPageUri "https://celerium.github.io/Celerium.AutoTask" -Verbose

    Updates markdown docs and external help files

    Progress information is sent to the console while the script is running.

.INPUTS
    N/A

.OUTPUTS
    N/A

.LINK
    https://celerium.org

#>

#Region  [ Parameters ]

[CmdletBinding()]
param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$HelpDocsPath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$CsvFilePath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$GithubPageUri,

        [Parameter(Mandatory=$false)]
        [switch]$ShowHelpDocs
    )

#EndRegion  [ Parameters ]

Write-Verbose ''
Write-Verbose "START - $(Get-Date -Format yyyy-MM-dd-HH:mm) - [ $($PSCmdlet.ParameterSetName) ]"
Write-Verbose ''

Write-Verbose " - (1/4) - $(Get-Date -Format MM-dd-HH:mm) - Configuring prerequisites"

#Region     [ Prerequisites ]

$StartDate = Get-Date

$HelpDocsPath   = $HelpDocsPath.TrimEnd('/', '\')
$GithubPageUri  = $GithubPageUri.TrimEnd('/', '\')

$ModulePage         = Join-Path -Path $HelpDocsPath -ChildPath "$ModuleName.md"
$TempFolder         = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "$ModuleName-help-$([guid]::NewGuid().ToString('N'))"
$SiteStructureFolder= Join-Path -Path $HelpDocsPath -ChildPath 'site'
$ExternalHelp       = Join-Path -Path $HelpDocsPath -ChildPath 'en-US'

$DocFolders = $HelpDocsPath, $TempFolder, $SiteStructureFolder, $ExternalHelp

$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Write-DocFile {
    # Help files are written without a BOM & with LF line endings so that Jekyll can read the front matter
    # and the files are identical on Windows, Linux, & macOS
    param ([string]$Path, [string]$Content)

    $Content = ($Content -replace "`r`n", "`n").TrimEnd("`n") + "`n"
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

function Format-CommandPage {
    # Cleans up a markdown page that was created by Microsoft.PowerShell.PlatyPS
    param ([string]$Content, [string[]]$Aliases)

    $Content = $Content -replace "`r`n", "`n"

    # The date changes with every run, it is removed so that only real changes show up in a diff
    $Content = $Content -replace '(?m)^ms\.date: .*\n', ''

    # The aliases of the command replace the placeholder
    $AliasText = if ($Aliases.Count) { ($Aliases | ForEach-Object { "  - $_" }) -join "`n" } else { '  - None' }
    $Content = $Content.Replace('  {{Insert list of aliases}}', $AliasText)

    # The first line of each example is the code of the example
    $Content = [regex]::Replace($Content, '(?m)^(### EXAMPLE \d+\n\n)(?!```)(.+)$', "`$1``````powershell`n`$2`n``````")

    return $Content
}

Try{

    if (Get-Module -Name Microsoft.PowerShell.PlatyPS -ListAvailable -Verbose:$false) {
        Import-Module -Name Microsoft.PowerShell.PlatyPS -Verbose:$false
    }
    else{
        throw "The Microsoft.PowerShell.PlatyPS module was not found, run build\Install-Prerequisites.ps1"
    }

    $RootPath = Split-Path -Path $PSScriptRoot -Parent
    $ModulePath = Join-Path -Path $RootPath -ChildPath $ModuleName
    $ModulePsd1 = Join-Path -Path $ModulePath -ChildPath "$ModuleName.psd1"

        if (Test-Path -Path $ModulePsd1 ) {
            Import-Module -Name $ModulePsd1 -Force -Verbose:$false
            $Commands = Get-Command -Module $ModuleName -ErrorAction Stop | Where-Object {$_.CommandType -eq 'Function'} | Sort-Object Name
        }
        else{
            throw "The [ $ModuleName ] module was not found"
        }

    ForEach ($Folder in $DocFolders) {

        # Nothing is deleted, existing documentation is overwritten. The temp folder only holds files created by this script
        if ( (Test-Path -Path $Folder -PathType Container) -eq $false ) {
            New-Item -Path $Folder -ItemType Directory > $null
        }

    }

    if ( (Test-Path -Path $CsvFilePath -PathType Leaf) -eq $false ) {
        throw "The required CSV file was not found at [ $CsvFilePath ]"
    }
    else{
        $CSV = Import-Csv -Path $CsvFilePath
    }

}
Catch{
    Write-Error $_
    exit 1
}

#EndRegion     [ Prerequisites ]

Write-Verbose " - (2/4) - $(Get-Date -Format MM-dd-HH:mm) - Regenerating [ $( ($Commands | Measure-Object).Count) ] help documents"

#Region     [ Command Help ]

$CategoryMethods    = @{}
$CommandCategory    = @{}
$CommandPages       = [System.Collections.Generic.List[string]]::new()

ForEach ( $Cmdlet in $Commands ) {

    $CsvData = $CSV | Where-Object {$_.Function -eq $Cmdlet.Name}

    $Category = [string]($CsvData.Category | Select-Object -Unique -First 1)
        if (-not $Category) {
            $Category = '_Unique'
        }

    $Method = [string]($CsvData.Method | Select-Object -Unique -First 1)
        if (-not $Method) {
            $Method = 'Special'
            Write-Warning " -       - $(Get-Date -Format MM-dd-HH:mm) - Unique command found, manually adjust the CSV file & metadata for [ $($Cmdlet.Name) ]"
        }

    $CategoryPath = Join-Path -Path $SiteStructureFolder -ChildPath $Category
        if ( (Test-Path -Path $CategoryPath -PathType Container) -eq $false ) {
            New-Item -Path $CategoryPath -ItemType Directory > $null
        }

    if (-not $CategoryMethods.ContainsKey($Category)) { $CategoryMethods[$Category] = [System.Collections.Generic.HashSet[string]]::new() }
    [void]$CategoryMethods[$Category].Add($Method)
    $CommandCategory[$Cmdlet.Name] = $Category

    # The values are cast to strings, a PSObject wrapped string is written to the front matter as an object
    $NewMetadata = @{
        'title'         = [string]$Cmdlet.Name
        'parent'        = [string]$Method
        'grand_parent'  = [string]$Category
    }

    $Params = @{
        CommandInfo     = $Cmdlet
        OutputFolder    = $TempFolder
        Metadata        = $NewMetadata
        HelpUri         = "$GithubPageUri/site/$Category/$($Cmdlet.Name).html"
        Force           = $true
    }
    $TempPage = New-MarkdownCommandHelp @Params

    $Aliases = @(Get-Alias -Definition $Cmdlet.Name -ErrorAction SilentlyContinue | Where-Object { $_.ModuleName -eq $ModuleName } | Sort-Object Name | ForEach-Object { $_.Name })

    $PagePath = Join-Path -Path $CategoryPath -ChildPath "$($Cmdlet.Name).md"
    Write-DocFile -Path $PagePath -Content (Format-CommandPage -Content ([System.IO.File]::ReadAllText($TempPage.FullName)) -Aliases $Aliases)
    $CommandPages.Add($PagePath)

}

#EndRegion  [ Command Help ]

Write-Verbose " - (3/4) - $(Get-Date -Format MM-dd-HH:mm) - Regenerating module document & GitHub pages structure"

#Region     [ Module help ]

$CommandHelp    = $CommandPages | Import-MarkdownCommandHelp
$TempModulePage = New-MarkdownModuleFile -CommandHelp $CommandHelp -OutputFolder (Join-Path -Path $TempFolder -ChildPath 'module') -HelpInfoUri $GithubPageUri -Force

$Content = [System.IO.File]::ReadAllText($TempModulePage.FullName) -replace "`r`n", "`n"
$Content = $Content -replace '(?m)^ms\.date: .*\n', ''
$Content = $Content -replace '(?m)^(title: .*)$', "`$1`nparent: Home"

# Links point to the function pages in the site folder
ForEach ($Name in $CommandCategory.Keys) {
    $Content = $Content.Replace("]($Name.md)", "](site/$($CommandCategory[$Name])/$Name.md)")
}

Write-DocFile -Path $ModulePage -Content $Content

    #Sync the GitHub pages home page with the README
    $ReadmePath = Join-Path -Path $RootPath -ChildPath 'README.md'
    if (Test-Path -Path $ReadmePath -PathType Leaf) {

        $HomeFrontMatter = @"
---
Module Name: $ModuleName
online version: https://github.com/Celerium/$ModuleName
title: Home
has_children: true
layout: default
nav_order: 1
---


"@
        Write-DocFile -Path (Join-Path -Path $HelpDocsPath -ChildPath 'index.md') -Content ($HomeFrontMatter + [System.IO.File]::ReadAllText($ReadmePath))

    }

    #Sync the tracking page table with the CSV
    $TrackingPath = Join-Path -Path $HelpDocsPath -ChildPath 'TrackingCSV.md'
    if (Test-Path -Path $TrackingPath -PathType Leaf) {

        $TrackingContent    = [System.IO.File]::ReadAllText($TrackingPath) -replace "`r`n", "`n"
        $TableMarker        = '## CSV markdown table'

        if ($TrackingContent.Contains($TableMarker)) {

            $TableRows = foreach ($Row in $CSV) {
                '|' + (($Row.Category, $Row.EndpointUri, $Row.Method, $Row.Function, $Row.Example, $Row.Complete, $Row.Notes | ForEach-Object { "$_" -replace '\|', '\|' }) -join '|') + '|'
            }

            $TrackingTable = @('|Category|EndpointUri|Method|Function|Example|Complete|Notes|', '|--------|-----------|------|--------|-------|--------|-----|') + $TableRows
            $TrackingHead  = $TrackingContent.Substring(0, $TrackingContent.IndexOf($TableMarker))

            Write-DocFile -Path $TrackingPath -Content ($TrackingHead + $TableMarker + "`n`n" + ($TrackingTable -join "`n"))

        }

    }

#Region     [ Template Code ]

# Only the HTTP methods that have functions get a method page, the index page lists every endpoint tracked in the CSV
ForEach ($Category in $CategoryMethods.Keys) {

    $CategoryPath = Join-Path -Path $SiteStructureFolder -ChildPath $Category

    ForEach ($Method in $CategoryMethods[$Category]) {

        $MethodContents = @"
---
title: $($Method.ToUpper())
parent: $Category
has_children: true
---
"@
        Write-DocFile -Path (Join-Path -Path $CategoryPath -ChildPath "$($Method.ToUpper()).md") -Content $MethodContents

    }

    $CategoryCsv    = $CSV | Where-Object { $_.Category -eq $Category }
    $CountRows      = ForEach ($HttpMethod in 'GET','POST','PUT','PATCH','DELETE') {
        if ($Category -eq 'Resource') {
            # The generic Resource functions support every operation of the resource map (OpenAPI spec)
            $Total          = (Get-AutoTaskResourceMap | Where-Object { $_.Method -eq $HttpMethod } | Measure-Object).Count
            $Implemented    = $Total
        }
        else {
            $Total          = ($CategoryCsv | Where-Object { $_.Method -eq $HttpMethod } | Measure-Object).Count
            $Implemented    = ($CategoryCsv | Where-Object { $_.Method -eq $HttpMethod -and $_.Complete -eq 'Yes' } | Measure-Object).Count
        }
        "| $($HttpMethod.PadRight(10)) | $($Implemented.ToString().PadRight(11)) | $($Total.ToString().PadRight(7)) |"
    }

    $IndexContents = @"
---
title: $Category
has_children: true
---

## $Category - endpoint help & documentation

{: .highlight }
The generic functions handle every endpoint of the AutoTask OpenAPI spec and the numbers below show the total endpoints **not** the total functions. Write endpoints (POST, PUT, PATCH, DELETE) change data in AutoTask, use ``-WhatIf`` to preview a request

| **Method** | **Implemented** | **Total** |
|------------|-----------------|-----------|
$($CountRows -join "`n")

Have a look around and if you would like to contribute please read over the [Contributing guide](https://github.com/Celerium/$ModuleName/blob/main/.github/CONTRIBUTING.md)
"@
    Write-DocFile -Path (Join-Path -Path $CategoryPath -ChildPath 'index.md') -Content $IndexContents

}

#EndRegion  [ Template Code ]

#EndRegion  [ Module help ]

Write-Verbose " - (4/4) - $(Get-Date -Format MM-dd-HH:mm) - Regenerating external help"

#Region     [ External Help ]

$TempMaml = Export-MamlCommandHelp -CommandHelp $CommandHelp -OutputFolder (Join-Path -Path $TempFolder -ChildPath 'maml') -Force
ForEach ($File in @($TempMaml)) {
    $Content = [System.IO.File]::ReadAllText($File.FullName)
    Write-DocFile -Path (Join-Path -Path $ExternalHelp -ChildPath $File.Name) -Content $Content
}

#EndRegion  [ External Help ]

Remove-Item -Path $TempFolder -Recurse -Force

if (Get-Module -Name $ModuleName) {
    Remove-Module -Name $ModuleName -Force -Verbose:$false
}

#Open File Explorer to show doc output
if ($ShowHelpDocs) {
    Invoke-Item $HelpDocsPath
}

Write-Verbose ''
Write-Verbose "END - $(Get-Date -Format yyyy-MM-dd-HH:mm)"
Write-Verbose ''

$TimeToComplete = New-TimeSpan -Start $StartDate -End (Get-Date)
Write-Verbose 'Time to complete'
Write-Verbose ($TimeToComplete | Select-Object * -ExcludeProperty Ticks,Total*,Milli* | Out-String)

}
