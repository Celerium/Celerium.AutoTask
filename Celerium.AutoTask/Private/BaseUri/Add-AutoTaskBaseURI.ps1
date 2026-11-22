function Add-AutoTaskBaseURI {
<#
    .SYNOPSIS
        Sets the base URI for the AutoTask API connection

    .DESCRIPTION
        The Add-AutoTaskBaseURI cmdlet sets the base URI which is used
        to construct the full URI for all API calls

        The base URI is the zone url of the AutoTask API without the API version,
        such as https://webservices24.autotask.net/atservicesrest

        The API version such as /V1.0 is part of each resource path, a base URI
        that ends with an API version is accepted & the version is removed

    .PARAMETER AutoDetect
        Automatically detects the base URI (zone) of the AutoTask API user

        The username set by Add-AutoTaskAPIKey is used to make a single unauthenticated
        GET request to the AutoTask ZoneInformation endpoint

        This is the default when no other parameter is used

    .PARAMETER Version
        Defines the API version that is stored with the base URI & used by -AutoDetect

        Default value: V1.0

    .PARAMETER BaseURI
        Sets the base URI for the AutoTask API connection. Helpful
        if using a custom API gateway or an undocumented AutoTask API endpoint

        The URL must use https

    .PARAMETER DataCenter
        Defines the data center (zone) to use which in turn defines which
        base API URL is used

        https://www.autotask.net/help/developerhelp/Content/APIs/General/API_Zones.htm

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

        Detects the base URI of the API user that was set by Add-AutoTaskAPIKey

    .EXAMPLE
        Add-AutoTaskBaseURI -BaseURI 'https://gateway.celerium.org'

        The base URI will use https://gateway.celerium.org

    .EXAMPLE
        Add-AutoTaskBaseURI -DataCenter 'America West 3'

        The base URI will use https://webservices24.autotask.net/atservicesrest

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
        [ValidatePattern('^[Vv]\d+(\.\d+)?$')]
        [string]$Version = 'V1.0',

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, ParameterSetName = 'CustomUri')]
        [ValidateNotNullOrEmpty()]
        [string]$BaseURI,

        [Parameter(Mandatory = $true, ParameterSetName = 'DataCenter')]
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

    process {

        switch ($PSCmdlet.ParameterSetName) {

            'AutoDetect' {

                if (-not $AutoTaskModuleApiUsername) {
                    throw "The AutoTask API username is not set. Run Add-AutoTaskAPIKey first or use the -DataCenter or -BaseURI parameter"
                }

                # Windows PowerShell does not always negotiate TLS 1.2 by default
                if ($PSEdition -eq 'Desktop') {
                    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
                }

                Write-Verbose "Detecting the base URI of the API user (AutoDetect: $([bool]$AutoDetect))"

                try {
                    $ValidationUri  ="https://webservices2.autotask.net/atservicesrest/$Version/ZoneInformation?user=$([System.Uri]::EscapeDataString($AutoTaskModuleApiUsername))"
                    $BaseURI        = (Invoke-RestMethod -Uri $ValidationUri -Method GET -UserAgent $AutoTaskModuleUserAgent -ErrorAction Stop).url
                }
                catch {
                    throw "Could not detect the AutoTask base URI, use the -DataCenter or -BaseURI parameter - $($_.Exception.Message)"
                }

                if (-not $BaseURI) { throw 'Could not detect the AutoTask base URI, use the -DataCenter or -BaseURI parameter' }

            }

            'DataCenter' {

                $BaseURI = switch ($DataCenter) {
                    'America East'                  { 'https://webservices3.autotask.net/atservicesrest' }
                    'America East 2'                { 'https://webservices14.autotask.net/atservicesrest' }
                    'America East 3'                { 'https://webservices22.autotask.net/atservicesrest' }
                    'America West'                  { 'https://webservices5.autotask.net/atservicesrest' }
                    'America West 2'                { 'https://webservices15.autotask.net/atservicesrest' }
                    'America West 3'                { 'https://webservices24.autotask.net/atservicesrest' }
                    'America West 4'                { 'https://webservices25.autotask.net/atservicesrest' }
                    'Australia / New Zealand'       { 'https://webservices6.autotask.net/atservicesrest' }
                    'Australia 2'                   { 'https://webservices26.autotask.net/atservicesrest' }
                    'Australia 3'                   { 'https://webservices29.autotask.net/atservicesrest' }
                    'Deutsch German'                { 'https://webservices18.autotask.net/atservicesrest' }
                    'Deutsch Pre-Release'           { 'https://prde.autotask.net/atservicesrest' }
                    'Español Pre-Release'           { 'https://pres.autotask.net/atservicesrest' }
                    'Español Spanish'               { 'https://webservices12.autotask.net/atservicesrest' }
                    'EU1 (English Europe and Asia)' { 'https://webservices19.autotask.net/atservicesrest' }
                    'Limited Release'               { 'https://webservices1.autotask.net/atservicesrest' }
                    'Pre-release'                   { 'https://webservices2.autotask.net/atservicesrest' }
                    'UK'                            { 'https://webservices4.autotask.net/atservicesrest' }
                    'UK Limited Release'            { 'https://webservices17.autotask.net/atservicesrest' }
                    'UK Pre-release'                { 'https://webservices11.autotask.net/atservicesrest' }
                    'UK2'                           { 'https://webservices16.autotask.net/atservicesrest' }
                    'UK3'                           { 'https://webservices28.autotask.net/atservicesrest' }
                }

            }

        }

        $ParsedUri = $null
        if (-not [System.Uri]::TryCreate($BaseURI.Trim(), [System.UriKind]::Absolute, [ref]$ParsedUri) -or $ParsedUri.Scheme -ne 'https') {
            throw "The base URI [ $BaseURI ] is not valid, it must be an absolute https url such as https://webservices24.autotask.net/atservicesrest"
        }

        # The query string, a trailing slash, & a trailing API version are removed
        $NormalizedUri = ($ParsedUri.GetLeftPart([System.UriPartial]::Path)).TrimEnd('/') -replace '(?i)/v\d+(\.\d+)?$', ''

        Write-Verbose "Using URI: [ $NormalizedUri ]"

        Set-Variable -Name 'AutoTaskModuleBaseUri'              -Value $NormalizedUri               -Option ReadOnly -Scope Global -Force
        Set-Variable -Name 'AutoTaskModuleBaseUriApiVersion'    -Value $Version                     -Option ReadOnly -Scope Global -Force
        Set-Variable -Name 'AutoTaskModuleBaseUriComplete'      -Value "$NormalizedUri/$Version"    -Option ReadOnly -Scope Global -Force

    }

    end {}

}
