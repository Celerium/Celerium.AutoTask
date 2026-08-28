function Add-AutoTaskBaseURI {
<#
    .SYNOPSIS
        Sets the base URI for the AutoTask API connection

    .DESCRIPTION
        The Add-AutoTaskBaseURI cmdlet sets the base URI which is used
        to construct the full URI for all API calls

    .PARAMETER AutoDetect
        Attempts to automatically detect the base URI for the AutoTask API connection

    .PARAMETER Version
        Defines the API version to use when constructing the full URI for all API calls

    .PARAMETER BaseUri
        Sets the base URI for the AutoTask API connection. Helpful
        if using a custom API gateway or an undocumented AutoTask API endpoint

    .PARAMETER DataCenter
        Defines the data center (platform) to use which in turn defines which
        base API URL is used

        https://ww24.autotask.net/DeveloperHelp/Content/APIs/General/API_Zones.htm

        Allowed values are:
        America East                    https://webservices3.autotask.net/atservicesrest
        America East 2                  https://webservices14.autotask.net/atservicesrest
        America East 3                  https://webservices22.autotask.net/atservicesrest
        America West                    https://webservices5.autotask.net/atservicesrest
        America West 2                  https://webservices15.autotask.net/atservicesrest
        America West 3                  https://webservices24.autotask.net/atservicesrest
        America West 4                  https://webservices25.autotask.net/atservicesrest
        Australia / New Zealand         https://webservices6.autotask.net/atservicesrest
        Australia 2                     https://webservices26.autotask.net/atservicesrest
        Australia 3                     https://webservices29.autotask.net/atservicesrest
        Deutsch German                  https://webservices18.autotask.net/atservicesrest
        Deutsch Pre-Release             https://prde.autotask.net/atservicesrest
        Español Pre-Release             https://pres.autotask.net/atservicesrest
        Español Spanish                 https://webservices12.autotask.net/atservicesrest
        EU1 (English Europe and Asia)   https://webservices19.autotask.net/atservicesrest
        Limited Release                 https://webservices1.autotask.net/atservicesrest
        Pre-release                     https://webservices2.autotask.net/atservicesrest
        UK                              https://webservices4.autotask.net/atservicesrest
        UK Limited Release              https://webservices17.autotask.net/atservicesrest
        UK Pre-release                  https://webservices11.autotask.net/atservicesrest
        UK2                             https://webservices16.autotask.net/atservicesrest
        UK3                             https://webservices28.autotask.net/atservicesrest

    .EXAMPLE
        Add-AutoTaskBaseURI

        Attempts to automatically detect the base URI for the AutoTask API connection

    .EXAMPLE
        Add-AutoTaskBaseURI -BaseUri 'https://gateway.celerium.org'

        The base URI will use https://gateway.celerium.org

    .EXAMPLE
        Add-AutoTaskBaseURI -DataCenter 'America West 3'

        The base URI will use https://webservices24.autotask.net/atservicesrest/v1.0

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Add-AutoTaskBaseURI.html
#>

    [CmdletBinding(DefaultParameterSetName = 'AutoDetect')]
    [Alias('Set-AutoTaskBaseURI')]
    Param (
        [Parameter(Mandatory = $false, ParameterSetName = 'AutoDetect')]
        [switch]$AutoDetect,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Version = $((Invoke-RestMethod -Uri "https://webservices2.autotask.net/atservicesrest/VersionInformation").apiVersions | Select-Object -Last 1),

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'CustomUri')]
        [ValidateNotNullOrEmpty()]
        [string]$BaseUri,

        [Parameter(Mandatory = $false, ParameterSetName = 'Datacenter')]
        [ValidateSet(
            'America East',
            'America East 2',
            'America East 3',
            'America West',
            'America West 2',
            'America West 3',
            'America West 4',
            'Australia / New Zealand',
            'Australia 2',
            'Australia 3',
            'Deutsch German',
            'Deutsch Pre-Release',
            'Español Pre-Release',
            'Español Spanish',
            'EU1 (English Europe and Asia)',
            'Limited Release',
            'Pre-release',
            'UK',
            'UK Limited Release',
            'UK Pre-release',
            'UK2',
            'UK3'
        )]
        [Alias('Platform')]
        [string]$DataCenter
    )

    begin {}

    process{

        if ($AutoDetect) {

            try {
                $ValidationUri  = 'https://webservices2.autotask.net/atservicesrest'
                $BaseUri        = (Invoke-RestMethod -Uri "$ValidationUri/$Version/ZoneInformation?user=$AutoTaskModuleApiUsername").url

            }
            catch {
                $ErrorMessage = $_ | Out-String
                Write-Error "Could not retrieve AutoTask BaseURI. $($ErrorMessage.Trim())"
                throw
            }

        }

        if ($DataCenter) {

            switch ($DataCenter) {
                'America East'                  {$BaseUri = 'https://webservices3.autotask.net/atservicesrest'}
                'America East 2'                {$BaseUri = 'https://webservices14.autotask.net/atservicesrest'}
                'America East 3'                {$BaseUri = 'https://webservices22.autotask.net/atservicesrest'}
                'America West'                  {$BaseUri = 'https://webservices5.autotask.net/atservicesrest'}
                'America West 2'                {$BaseUri = 'https://webservices15.autotask.net/atservicesrest'}
                'America West 3'                {$BaseUri = 'https://webservices24.autotask.net/atservicesrest'}
                'America West 4'                {$BaseUri = 'https://webservices25.autotask.net/atservicesrest'}
                'Australia / New Zealand'       {$BaseUri = 'https://webservices6.autotask.net/atservicesrest'}
                'Australia 2'                   {$BaseUri = 'https://webservices26.autotask.net/atservicesrest'}
                'Australia 3'                   {$BaseUri = 'https://webservices29.autotask.net/atservicesrest'}
                'Deutsch German'                {$BaseUri = 'https://webservices18.autotask.net/atservicesrest'}
                'Deutsch Pre-Release'           {$BaseUri = 'https://prde.autotask.net/atservicesrest'}
                'Español Pre-Release'           {$BaseUri = 'https://pres.autotask.net/atservicesrest'}
                'Español Spanish'               {$BaseUri = 'https://webservices12.autotask.net/atservicesrest'}
                'EU1 (English Europe and Asia)' {$BaseUri = 'https://webservices19.autotask.net/atservicesrest'}
                'Limited Release'               {$BaseUri = 'https://webservices1.autotask.net/atservicesrest'}
                'Pre-release'                   {$BaseUri = 'https://webservices2.autotask.net/atservicesrest'}
                'UK'                            {$BaseUri = 'https://webservices4.autotask.net/atservicesrest'}
                'UK Limited Release'            {$BaseUri = 'https://webservices17.autotask.net/atservicesrest'}
                'UK Pre-release'                {$BaseUri = 'https://webservices11.autotask.net/atservicesrest'}
                'UK2'                           {$BaseUri = 'https://webservices16.autotask.net/atservicesrest'}
                'UK3'                           {$BaseUri = 'https://webservices28.autotask.net/atservicesrest'}
            }

        }

        if($BaseUri[$BaseUri.Length-1] -eq "/") {
            $BaseUri = $BaseUri.Substring(0,$BaseUri.Length-1)
        }

        Write-Verbose "Using URI: [ $($BaseURI + "/$Version") ]"

        Set-Variable -Name "AutoTaskModuleBaseUri"              -Value $BaseURI -Option ReadOnly -Scope Global -Force
        Set-Variable -Name "AutoTaskModuleBaseUriApiVersion"    -Value $Version -Option ReadOnly -Scope Global -Force
        Set-Variable -Name "AutoTaskModuleBaseUriComplete"      -Value ($BaseURI + "/$Version") -Option ReadOnly -Scope Global -Force

    }

    end {}

}