function Invoke-AutoTaskRequest {
<#
    .SYNOPSIS
        Makes an API request to the AutoTask API

    .DESCRIPTION
        The Invoke-AutoTaskRequest cmdlet invokes an API request to the AutoTask API

        This is an internal function that is used by all public functions

        GET requests & the POST query requests (/query & /query/count) are read requests.
        Any other request is a write request. Write requests are never retried

        By default only the data of a response is returned, such as the items of a query
        or the item of a single resource. Use -Raw to return the full response

    .PARAMETER Method
        Defines the type of API method to use

        Allowed values:
        'GET', 'POST', 'PUT', 'PATCH', 'DELETE'

    .PARAMETER ResourceURI
        Defines the resource uri (url) path to use when creating the API call, such as /V1.0/Companies/query

        The path is appended to the base URI defined by Add-AutoTaskBaseURI

    .PARAMETER UriFilter
        Hashtable of query string parameters to append to the resource uri, such as @{ search = '{...}' }

        The values are url encoded

    .PARAMETER Data
        Optional object to send as the JSON request body

        A string is sent as is and must already be JSON, any other object is converted to JSON

    .PARAMETER AllResults
        Returns all items from an endpoint by following the next page url of every page of a query

        Ignored for write requests

    .PARAMETER Raw
        Returns the full API response object instead of only the data

    .PARAMETER WriteRequest
        Marks the request as a write request so that it is never retried, even when it uses the GET method

        Every request that is not a GET request or a POST query request is always a write request

    .EXAMPLE
        Invoke-AutoTaskRequest -Method GET -ResourceURI '/V1.0/Companies/0'

        Gets the company with the ID 0

    .EXAMPLE
        Invoke-AutoTaskRequest -Method POST -ResourceURI '/V1.0/Companies/query' -Data '{"filter":[{"op":"eq","field":"isActive","value":true}]}' -AllResults

        Returns every active company by requesting every page of the query

    .EXAMPLE
        Invoke-AutoTaskRequest -Method PATCH -ResourceURI '/V1.0/Companies' -Data @{ id = 12345; phone = '555-555-5555' }

        Sends a write request with a JSON body

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Invoke-AutoTaskRequest.html
#>

    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet('GET', 'POST', 'PUT', 'PATCH', 'DELETE')]
        [string]$Method = 'GET',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceURI,

        [Parameter()]
        [hashtable]$UriFilter,

        [Parameter()]
        $Data,

        [Parameter()]
        [switch]$AllResults,

        [Parameter()]
        [switch]$Raw,

        [Parameter()]
        [switch]$WriteRequest
    )

    begin {

        $FunctionName   = $MyInvocation.MyCommand.Name
        $ParameterName  = $FunctionName + '_Parameters' -replace '-','_'

        $BaseUri = Get-AutoTaskBaseURI -WarningAction SilentlyContinue
        $ApiKey  = Get-AutoTaskAPIKey -AsPlainText -WarningAction SilentlyContinue
        if (-not $BaseUri -or -not $ApiKey -or -not $ApiKey.Username -or -not $ApiKey.Password -or -not $ApiKey.ApiIntegrationCode) {
            throw "No authentication method or base uri found, please run Add-AutoTaskAPIKey & Add-AutoTaskBaseURI to continue"
        }

        # Windows PowerShell does not always negotiate TLS 1.2 by default
        if ($PSEdition -eq 'Desktop') {
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        }

        $RequestHeaders = @{
            'ApiIntegrationCode'    = $ApiKey.ApiIntegrationCode
            'UserName'              = $ApiKey.Username
            'Secret'                = $ApiKey.Password
            'Accept'                = 'application/json'
        }
        $ApiKey = $null

        # Only the path is cleaned up, a double slash in the query string can be part of a search value
        $PathPart, $QueryPart = $ResourceURI -split '\?', 2
        $ResourceURI = '/' + ($PathPart.TrimStart('/') -replace '/{2,}', '/')
        if ($QueryPart) { $ResourceURI = $ResourceURI + '?' + $QueryPart }

        # GET requests & POST queries do not change any data
        $IsWrite        = $WriteRequest -or ( $Method -ne 'GET' -and $PathPart -notmatch '/query(/count)?/?$' )
        $PageResults    = $AllResults -and -not $IsWrite

        $BaseAuthority  = ([System.Uri]$BaseUri).GetLeftPart([System.UriPartial]::Authority)

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $AllResponseData    = [System.Collections.Generic.List[object]]::new()
        $LastResponse       = $null
        $Page               = 1

        $QueryString = ''
        if ($UriFilter) {
            $Keys = [string[]]@($UriFilter.Keys)
            [System.Array]::Sort($Keys, [System.StringComparer]::Ordinal)
            $QueryString = (@(foreach ($Key in $Keys) {
                $Value = $UriFilter[$Key]
                if ($Value -is [bool]) { $Value = $Value.ToString().ToLowerInvariant() }
                [System.Uri]::EscapeDataString($Key) + '=' + [System.Uri]::EscapeDataString("$Value")
            })) -join '&'
        }

        $TargetUri = $BaseUri + $ResourceURI
        if ($QueryString) { $TargetUri = $TargetUri + $(if ($TargetUri.Contains('?')) { '&' } else { '?' }) + $QueryString }

        do {

            $InvokeParams = @{
                Method          = $Method
                Uri             = $TargetUri
                Headers         = $RequestHeaders
                UserAgent       = $AutoTaskModuleUserAgent
                UseBasicParsing = $true
                ErrorAction     = 'Stop'
            }

            if ($PSBoundParameters.ContainsKey('Data')) {
                $InvokeParams.Body          = if ($Data -is [string]) { $Data } else { ConvertTo-Json -InputObject $Data -Depth $AutoTaskModuleJSONConversionDepth -Compress }
                $InvokeParams.ContentType   = 'application/json; charset=utf-8'
            }

            # Keeps the API secret & integration code out of the debug variable
            $DebugParams = @{} + $InvokeParams
            $DebugParams.Headers = @{} + $RequestHeaders
            $DebugParams.Headers['Secret']              = '*******'
            $DebugParams.Headers['ApiIntegrationCode']  = '*******'
            Set-Variable -Name $ParameterName -Value $DebugParams -Scope Global -Force -Confirm:$false

            $RetryCount = 0
            $RetryMax   = 3
            $Response   = $null

            while ($null -eq $Response) {

                try {
                    $WebResponse    = Invoke-WebRequest @InvokeParams
                    $Bytes          = $WebResponse.RawContentStream.ToArray()
                    $ContentType    = "$($WebResponse.Headers['Content-Type'])"

                    if ($ContentType -and $ContentType -notmatch 'json|text|xml|html') {
                        # Binary data is returned as a byte array
                        $Response = $Bytes
                    }
                    else {
                        # Windows PowerShell decodes responses without a charset as ISO-8859-1
                        $Content = [System.Text.Encoding]::UTF8.GetString($Bytes)

                        if ($ContentType -match 'json' -or $Content.TrimStart() -match '^[\{\[]') {
                            if ($Content.Trim()) { $Response = $Content | ConvertFrom-Json }

                            # An array with zero or one item is not returned as an array when it is converted from JSON
                            if ($Content.TrimStart().StartsWith('[')) { $Response = @($Response | Where-Object { $null -ne $_ }) }
                        }
                        else { $Response = $Content }
                    }

                    if ($null -eq $Response -or ($Response -is [string] -and -not $Response.Trim())) { $Response = [PSCustomObject]@{} }
                }
                catch {

                    $ErrorRecord    = $_
                    $StatusCode     = $null
                    $RetryAfter     = $null

                    if ($ErrorRecord.Exception.Response) {
                        $StatusCode = [int]$ErrorRecord.Exception.Response.StatusCode
                        try {
                            $ResponseHeaders = $ErrorRecord.Exception.Response.Headers
                            if ($ResponseHeaders.GetType().Name -eq 'HttpResponseHeaders') {
                                if ($ResponseHeaders.RetryAfter.Delta) { $RetryAfter = [int]$ResponseHeaders.RetryAfter.Delta.TotalSeconds }
                            }
                            elseif ($ResponseHeaders['Retry-After']) { $RetryAfter = [int]$ResponseHeaders['Retry-After'] }
                        }
                        catch { Write-Verbose "[ $FunctionName ] - Unable to read the Retry-After header" }
                    }

                    # Prefer the error detail returned by the API, AutoTask returns { "errors": [ "..." ] }
                    $Detail = $ErrorRecord.Exception.Message
                    if ($ErrorRecord.ErrorDetails.Message) {
                        try {
                            $ApiError = $ErrorRecord.ErrorDetails.Message | ConvertFrom-Json -ErrorAction Stop
                            if ($ApiError.errors)           { $Detail = (@($ApiError.errors) | ForEach-Object { "$_" }) -join '; ' }
                            elseif ($ApiError.message)      { $Detail = "$($ApiError.message)" }
                            elseif ($ApiError.Message)      { $Detail = "$($ApiError.Message)" }
                            else                            { $Detail = $ErrorRecord.ErrorDetails.Message }
                        }
                        catch { $Detail = $ErrorRecord.ErrorDetails.Message }
                    }

                    # A write request is never sent again because it could be applied twice
                    $Retryable = (-not $IsWrite) -and ( ( $null -eq $StatusCode ) -or ( $StatusCode -in 429, 502, 503, 504 ) )

                    if (-not $Retryable) {
                        Write-Warning 'The [ Invoke_AutoTaskRequest_Parameters & CmdletName_Parameters ] variables can provide extra details'
                        switch ($StatusCode) {
                            401     { throw "Invoke-AutoTaskRequest : [ 401 ] Unauthorized, verify the API username, secret, & integration code - [ $ResourceURI ]" }
                            403     { throw "Invoke-AutoTaskRequest : [ 403 ] Forbidden, the API user is not allowed to access this resource - [ $ResourceURI ]" }
                            404     { throw "Invoke-AutoTaskRequest : [ 404 ] URI not found - [ $ResourceURI ]" }
                            default { throw "Invoke-AutoTaskRequest : [ $StatusCode ] $Detail - [ $ResourceURI ]" }
                        }
                    }

                    $RetryCount++
                    if ($RetryCount -ge $RetryMax) {
                        throw "Invoke-AutoTaskRequest : Maximum retry attempts reached [ $RetryCount/$RetryMax ] - [ $StatusCode ] $Detail - [ $ResourceURI ]"
                    }

                    $WaitTime = [Math]::Min( [Math]::Pow(2, $RetryCount) + (Get-Random -Minimum 0 -Maximum 5), 60 )
                    if ($RetryAfter) { $WaitTime = [Math]::Min($RetryAfter, 120) }

                    Write-Warning "Invoke-AutoTaskRequest : [ $StatusCode ] Retrying request [ $ResourceURI ] in [ $WaitTime ] seconds - Attempt [ $RetryCount/$RetryMax ]"
                    Start-Sleep -Seconds $WaitTime

                }

            }

            $LastResponse   = $Response
            $TargetUri      = $null

            $HasItems = $Response -is [System.Management.Automation.PSCustomObject] -and $Response.PSObject.Properties['items']

            if ($HasItems) {

                foreach ($Item in @($Response.items)) { if ($null -ne $Item) { $AllResponseData.Add($Item) } }
                Write-Verbose "[ $FunctionName ] - Processing [ $(@($Response.items).Count) ] items from page [ $Page ]"

                $NextPageUrl = if ($Response.PSObject.Properties['pageDetails']) { "$($Response.pageDetails.nextPageUrl)" } else { '' }

                if ($PageResults -and $NextPageUrl) {

                    # The credentials are only sent to the AutoTask base uri
                    $ParsedNext = $null
                    if ([System.Uri]::TryCreate($NextPageUrl, [System.UriKind]::Absolute, [ref]$ParsedNext) -and $ParsedNext.GetLeftPart([System.UriPartial]::Authority) -eq $BaseAuthority) {
                        $TargetUri = $NextPageUrl
                        $Page++
                    }
                    else { Write-Warning "Invoke-AutoTaskRequest : The next page url is not on the base uri [ $BaseAuthority ], no more pages are requested" }

                }

            }

        } while ($TargetUri)

        $IsItems = $LastResponse -is [System.Management.Automation.PSCustomObject] -and $LastResponse.PSObject.Properties['items']

        if ($Raw) {
            if ($PageResults -and $IsItems -and $Page -gt 1) {
                return [PSCustomObject]@{
                    items       = $AllResponseData.ToArray()
                    pageDetails = $LastResponse.pageDetails
                }
            }
            return $LastResponse
        }

        if ($IsItems) { return $AllResponseData.ToArray() }

        if ($LastResponse -is [System.Management.Automation.PSCustomObject] -and $LastResponse.PSObject.Properties['item'] -and @($LastResponse.PSObject.Properties).Count -eq 1) {
            return $LastResponse.item
        }

        if ($LastResponse -is [byte[]]) { return ,$LastResponse }

        return $LastResponse

    }

    end {}

}
