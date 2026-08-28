function Invoke-AutoTaskRequest {
<#
    .SYNOPSIS
        Makes an API request to AutoTask

    .DESCRIPTION
        The Invoke-AutoTaskRequest cmdlet invokes an API request to the AutoTask API

        This is an internal function that is used by all public functions

    .PARAMETER Method
        Defines the type of API method to use

        Allowed values:
        'GET', 'PUT', 'POST', 'PATCH', 'DELETE'

    .PARAMETER ResourceURI
        Defines the resource uri (url) to use when creating the API call

    .PARAMETER Data
        Object containing supported AutoTask method schemas

    .PARAMETER AllResults
        Returns all items from an endpoint

    .EXAMPLE
        Invoke-AutoTaskRequest -Method GET -ResourceURI '/passwords' -UriFilter $UriFilter

        Invoke a rest method against the defined resource using the provided parameters

        Example HashTable:
            $UriParameters = @{
                'filter[id]']               = 123456789
                'filter[organization_id]']  = 12345
            }

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Invoke-AutoTaskRequest.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Invoke', SupportsShouldProcess)]
    param (
        [Parameter()]
        [ValidateSet('GET', 'PUT', 'POST', 'PATCH', 'DELETE')]
        [string]$Method = 'GET',

        [Parameter(Mandatory = $true)]
        [string]$ResourceURI,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        $Data,

        [Parameter()]
        [switch]$AllResults
    )

    begin {

        # Load Web assembly when needed as PowerShell Core has the assembly preloaded
        if ( !("System.Web.HttpUtility" -as [Type]) ) { Add-Type -Assembly System.Web }

        $FunctionName   = $MyInvocation.InvocationName
        $ParameterName  = $FunctionName + '_Parameters' -replace '-','_'

        $ApiSecret = Get-AutoTaskAPIKey -AsPlainText -WarningAction SilentlyContinue -WarningVariable 'Get_AutoTaskAPIKey_Warning'
        if ( $Get_AutoTaskAPIKey_Warning -or !$(Get-AutoTaskBaseURI -WarningAction SilentlyContinue)) {
            throw "No authentication method or base uri found, please run Add-AutoTaskAPIKey & Add-AutoTaskBaseURI to continue"
        }

        $Headers = @{
            'ApiIntegrationCode'    = $ApiSecret.ApiIntegrationCode
            'UserName'              = $ApiSecret.Username
            'Secret'                = $ApiSecret.Password
            'Content-Type'          = "application/json; charset=utf-8"
        }

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $AllResponseData = [System.Collections.Generic.List[object]]::new()

        $Page       = 1
        $RetryCount = 0
        $RetryMax   = 3

        Set-Variable -Name TEST_BASEURI -Value $AutoTaskModuleBaseUri -Scope Global -Force -Confirm:$false
        Set-Variable -Name TEST_RESOURCEURI -Value $ResourceURI -Scope Global -Force -Confirm:$false

        #POST ResourceURI have double // in the path
        $ResourceURI    = $ResourceURI -replace '(?<!:)/{2,}', '/'
        $TargetUri      = $AutoTaskModuleBaseUri + $ResourceURI

        $InvokeParams = @{
            Method      = $Method
            Headers     = $Headers
            URI         = $TargetUri
            UserAgent   = $AutoTaskModuleUserAgent
        }

        if ($Method -ne 'GET') {
            if ($Data -is [string]) { $SendingBody = $Data }
            else { $SendingBody = $Data | ConvertTo-Json -Depth $AutoTaskModuleJSONConversionDepth }

            $InvokeParams.Body  = $SendingBody
        }

        Set-Variable -Name $ParameterName -Value $InvokeParams -Scope Global -Force -Confirm:$false

        try{
            do {
                try{
                    $ApiResponse = Invoke-RestMethod @InvokeParams

                    if ($AllResults) {
                        $InvokeParams['Uri'] = $ApiResponse.pageDetails.nextPageUrl
                    }

                    # Returns blank unless $Items itself is returned for InvoicePDF function
                    if ($ResourceTarget -eq "InvoicePDF") {
                        Write-Verbose "Processing [ $(($ApiResponse | Measure-Object).Count) ] items from page [ $Page ]"
                        $AllResponseData.Add($ApiResponse)
                    }

                    if ($ApiResponse.fields) {
                        $AllResponseData.Add($ApiResponse)
                    }

                    if ($ApiResponse.items)   {
                        Write-Verbose "Processing [ $($ApiResponse.pageDetails.count) ] items from page [ $Page ]"
                        $AllResponseData.AddRange(@($ApiResponse.items))
                    }

                    if ($ApiResponse.item)    {
                        Write-Verbose "Processing [ $(($ApiResponse.item | Measure-Object).Count) ] items from page [ $Page ]"
                        $AllResponseData.AddRange(@($ApiResponse.item))
                    }

                    $Page++
                }
                catch {
                    $ExceptionError = $_.Exception.Message
                    Write-Warning 'The [ Invoke_AutoTaskRequest_Parameters, Invoke_AutoTaskRequest_ParametersQuery, & CmdletName_Parameters ] variables can provide extra details'

                    $RandomWaitTime = [Math]::Min( [Math]::Pow(2,$RetryCount) + (Get-Random -Minimum 0 -Maximum 30),120)

                    switch -Wildcard ($ExceptionError) {
                        '*400*' {   throw }
                        '*404*' {   throw "Invoke-AutoTaskRequest : URI not found - [ $TargetUri ]"}
                        '*429*' {
                                    $RetryAfter = $_.Exception.Response.Headers['Retry-After']
                                    if ($RetryAfter) { $RandomWaitTime = [int]$RetryAfter }

                                    Write-Error "Invoke-AutoTaskRequest : API rate limited  - Sleeping for [ $RandomWaitTime ] seconds"

                                    if ($RetryAfter) { Start-Sleep -Seconds [int]$RetryAfter }
                                    else { Start-Sleep -Seconds $RandomWaitTime }
                                }
                        '*504*' {   Write-Error "Invoke-AutoTaskRequest : Gateway Timeout  - Sleeping for [ $RandomWaitTime ] seconds"
                                    Start-Sleep -Seconds $RandomWaitTime
                                }
                        default { Write-Error $_ }
                    }

                    $RetryCount++
                    if ($RetryCount -lt $RetryMax) {
                        Write-Warning "Invoke-AutoTaskRequest : Retrying request [ $ResourceURI ] - Attempt [ $RetryCount/$RetryMax ]"
                    }
                    else{
                        throw "Invoke-AutoTaskRequest : Maximum retry attempts reached [ $RetryCount/$RetryMax ]"
                    }

                }
            }
            while ($AllResults -and $InvokeParams.Uri)
        }
        catch {
            Write-Error $_
            throw
        }
        finally {
            if ($Invoke_AutoTaskRequest_Parameters) {
                $Auth = $Invoke_AutoTaskRequest_Parameters['headers']['Secret']
                if ($Auth) {
                    $Invoke_AutoTaskRequest_Parameters['headers']['Secret'] = $Auth.Substring(0,[Math]::Min($Auth.Length,9)) + '*******'
                }
            }
        }

        return $AllResponseData

    }

    end {}

}
