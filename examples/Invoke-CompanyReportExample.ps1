<#
    .SYNOPSIS
        Creates a read-only report of the active companies using the Celerium.AutoTask module

    .DESCRIPTION
        The Invoke-CompanyReportExample script returns the active companies with their
        company type label & the number of their contacts

        Only read-only requests are made (GET requests & POST queries), no data is changed in AutoTask

        The API values can be passed in as parameters, stored with Export-AutoTaskModuleSettings,
        or set with the AUTOTASK_API_USERNAME, AUTOTASK_API_SECRET, & AUTOTASK_API_INTEGRATION_CODE
        environment variables

    .PARAMETER ApiUsername
        Defines the username of the AutoTask API user

    .PARAMETER ApiSecret
        Defines the secret of the AutoTask API user as a SecureString

    .PARAMETER ApiIntegrationCode
        Defines the API integration code (tracking identifier) of the AutoTask API user

    .PARAMETER MaxCompanies
        Defines the maximum number of companies to return

        Default value: 25

    .PARAMETER OutFile
        Defines the path of a CSV file to save the report to

    .EXAMPLE
        .\Invoke-CompanyReportExample.ps1

        Returns the first 25 active companies using the stored module settings

    .EXAMPLE
        .\Invoke-CompanyReportExample.ps1 -ApiUsername 'api@example.com' -ApiSecret (Read-Host -AsSecureString) -ApiIntegrationCode '12345' -MaxCompanies 100 -OutFile .\Companies.csv -Verbose

        Returns the first 100 active companies, saves them to a CSV file, & shows the progress

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/

    .LINK
        https://github.com/Celerium/Celerium.AutoTask
#>

<############################################################################################
                                        Code
############################################################################################>
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Celerium.AutoTask'; ModuleVersion='2.0.0' }

[CmdletBinding()]
param (
    [Parameter()]
    [string]$ApiUsername,

    [Parameter()]
    [securestring]$ApiSecret,

    [Parameter()]
    [string]$ApiIntegrationCode,

    [Parameter()]
    [ValidateRange(1, 500)]
    [int]$MaxCompanies = 25,

    [Parameter()]
    [string]$OutFile
)

Write-Verbose "START - $(Get-Date -Format yyyy-MM-dd-HH:mm)"

#Region     [ Prerequisites ]

Import-Module -Name Celerium.AutoTask -MinimumVersion 2.0.0 -Verbose:$false

if ($ApiUsername -and $ApiSecret -and $ApiIntegrationCode) {
    Add-AutoTaskAPIKey -ApiUsername $ApiUsername -ApiKeySecureString $ApiSecret -ApiIntegrationCode $ApiIntegrationCode
}

if (-not (Get-AutoTaskAPIKey -WarningAction SilentlyContinue)) {
    throw 'The AutoTask API values are not set. Use the parameters, Add-AutoTaskAPIKey, or the AUTOTASK_* environment variables'
}

if (-not (Get-AutoTaskBaseURI -WarningAction SilentlyContinue)) {
    # One unauthenticated request that detects the zone of the API user
    Add-AutoTaskBaseURI
}

#EndRegion  [ Prerequisites ]

#Region     [ Report ]

Write-Verbose " - (1/3) - Reading the company type labels"
$CompanyTypes = @{}
$Fields = Get-AutoTaskResource -Resource Companies -Operation QueryFieldDefinitions
foreach ($Value in ($Fields.fields | Where-Object { $_.name -eq 'companyType' }).picklistValues) {
    $CompanyTypes["$($Value.value)"] = $Value.label
}

Write-Verbose " - (2/3) - Querying the first [ $MaxCompanies ] active companies"
$Search     = '{"MaxRecords":' + $MaxCompanies + ',"IncludeFields":["id","companyName","companyType","phone"],"filter":[{"op":"eq","field":"isActive","value":true}]}'
$Companies  = @(Get-AutoTaskResource -Resource Companies -AdvancedSearch $Search)

Write-Verbose " - (3/3) - Counting the contacts of [ $($Companies.Count) ] companies"
$Report = foreach ($Company in $Companies) {

    $ContactSearch = '{"filter":[{"op":"eq","field":"companyID","value":' + $Company.id + '}]}'

    [PSCustomObject]@{
        Id          = $Company.id
        Company     = $Company.companyName
        CompanyType = $CompanyTypes["$($Company.companyType)"]
        Phone       = $Company.phone
        Contacts    = (Get-AutoTaskResource -Resource Contacts -AdvancedSearch $ContactSearch -Operation QueryCount).queryCount
    }

}

#EndRegion  [ Report ]

if ($OutFile) {
    $Report | Export-Csv -Path $OutFile -NoTypeInformation
    Write-Verbose "Saved the report to [ $OutFile ]"
}

Write-Verbose "END - $(Get-Date -Format yyyy-MM-dd-HH:mm)"

$Report
