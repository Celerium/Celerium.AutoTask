# Shared helpers for the Celerium.AutoTask Pester tests
# This file is dot-sourced by each test file & is not a test file itself

$script:AutoTaskEnvironmentVariables = 'AUTOTASK_BASE_URI', 'AUTOTASK_API_USERNAME', 'AUTOTASK_API_SECRET', 'AUTOTASK_API_INTEGRATION_CODE'

function Get-TestRootPath {
    # The tests folder lives directly under the repository root
    $Path = $PSScriptRoot
    while ($Path -and -not (Test-Path -Path (Join-Path -Path $Path -ChildPath 'TestHelper.ps1'))) { $Path = Split-Path -Path $Path -Parent }
    return (Split-Path -Path $Path -Parent)
}

function Get-TestModulePath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Parameter(Mandatory = $true)]
        [ValidateSet('built', 'notBuilt')]
        [string]$BuildTarget
    )

    $RootPath = Get-TestRootPath

    switch ($BuildTarget) {
        'built'     { return Join-Path -Path (Join-Path -Path (Join-Path -Path $RootPath -ChildPath 'build') -ChildPath $ModuleName) -ChildPath $Version }
        'notBuilt'  { return Join-Path -Path $RootPath -ChildPath $ModuleName }
    }
}

function Import-TestModule {
    <#
        Imports the module that is being tested

        Environment variables used to auto configure the module are removed during the import so that
        unit tests always start from a clean state, unless -KeepEnvironment is used (live tests)
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Parameter(Mandatory = $true)]
        [ValidateSet('built', 'notBuilt')]
        [string]$BuildTarget,

        [switch]$KeepEnvironment
    )

    $ModulePath = Get-TestModulePath -ModuleName $ModuleName -Version $Version -BuildTarget $BuildTarget
    $ModulePsd1 = Join-Path -Path $ModulePath -ChildPath "$ModuleName.psd1"

    if (Get-Module -Name $ModuleName) { Remove-Module -Name $ModuleName -Force }

    $Saved = @{}
    if (-not $KeepEnvironment) {
        foreach ($Name in $script:AutoTaskEnvironmentVariables) {
            $Saved[$Name] = [Environment]::GetEnvironmentVariable($Name)
            [Environment]::SetEnvironmentVariable($Name, $null)
        }
    }

    try     { Import-Module -Name $ModulePsd1 -Force -ErrorAction Stop *> $null }
    finally { foreach ($Name in $Saved.Keys) { [Environment]::SetEnvironmentVariable($Name, $Saved[$Name]) } }
}

function Remove-TestModule {
    param ([string]$ModuleName)

    foreach ($Name in 'AutoTaskModuleApiUsername', 'AutoTaskModuleApiSecretKey', 'AutoTaskModuleApiIntegrationCode', 'AutoTaskModuleBaseUri', 'AutoTaskModuleBaseUriApiVersion', 'AutoTaskModuleBaseUriComplete') {
        Remove-Variable -Name $Name -Scope Global -Force -ErrorAction SilentlyContinue
    }

    if (Get-Module -Name $ModuleName) { Remove-Module -Name $ModuleName -Force }
}

function Add-FakeHttpException {
    # Windows PowerShell & PowerShell Core use different exception types, this type works for both
    if (-not ('FakeHttpException' -as [type])) {
        Add-Type -TypeDefinition @'
public class FakeHttpException : System.Exception
{
    public object Response { get; set; }
    public FakeHttpException(string message) : base(message) { }
}
'@
    }
}

function New-FakeResponse {
    # Creates an object that looks like the response of Invoke-WebRequest
    param ([string]$Content, [string]$ContentType = 'application/json; charset=utf-8', [byte[]]$Bytes)

    if (-not $Bytes) { $Bytes = [System.Text.Encoding]::UTF8.GetBytes($Content) }
    [PSCustomObject]@{
        StatusCode          = 200
        Headers             = @{ 'Content-Type' = $ContentType }
        RawContentStream    = [System.IO.MemoryStream]::new($Bytes)
    }
}

function Get-TestSpecPath {
    # The newest (highest version) AutoTaskAPI-<version>.json file in the module folder, which is the spec the resource map is created from
    $Files = @(Get-ChildItem -Path (Join-Path -Path (Get-TestRootPath) -ChildPath 'Celerium.AutoTask') -Filter 'AutoTaskAPI-*.json' -File -ErrorAction SilentlyContinue | ForEach-Object {
        $Text = $_.BaseName -replace '^AutoTaskAPI-v?', ''
        if ($Text -match '^\d+$') { $Text += '.0' }
        $Parsed = $null
        [PSCustomObject]@{ File = $_; Version = if ([System.Version]::TryParse($Text, [ref]$Parsed)) { $Parsed } else { [System.Version]'0.0' } }
    })

    if ($Files.Count -eq 0) { return $null }
    return ($Files | Sort-Object -Property Version, @{ Expression = { $_.File.Name } } -Descending | Select-Object -First 1).File.FullName
}

function Test-IsWindowsPlatform {
    return ($PSEdition -eq 'Desktop' -or $IsWindows)
}
