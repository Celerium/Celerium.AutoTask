function Test-AutoTaskAPIKey {
<#
    .SYNOPSIS
        Test the AutoTask API username, secret, & integration code

    .DESCRIPTION
        The Test-AutoTaskAPIKey cmdlet tests the base URI & API values that
        are defined by the Add-AutoTaskBaseURI & Add-AutoTaskAPIKey cmdlets

        Helpful when needing to validate general functionality or when using
        RMM deployment tools

        The test makes a single read-only GET query that only asks for the ID of one company

        A 200 status code means the base URI & API values are valid. A 401 status code means
        the API values were not accepted & a 403 status code means the API user is not
        allowed to read companies

    .PARAMETER BaseURI
        Define the base URI for the AutoTask API connection
        using AutoTask's URI or a custom URI

        By default the value used is the one defined by the
        Add-AutoTaskBaseURI function

    .EXAMPLE
        Test-AutoTaskAPIKey

        Tests the base URI & API values that are defined by the
        Add-AutoTaskBaseURI & Add-AutoTaskAPIKey cmdlets

    .EXAMPLE
        Test-AutoTaskAPIKey -BaseURI https://myapi.gateway.celerium.org

        Tests the defined base URI & the API values that were defined by
        the Add-AutoTaskAPIKey cmdlet

        The full test uri in this example is:
            https://myapi.gateway.celerium.org/V1.0/Companies/query?search=...

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Test-AutoTaskAPIKey.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Test')]
    Param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$BaseURI = $AutoTaskModuleBaseUri
    )

    begin {
        $Search         = '{"MaxRecords":1,"IncludeFields":["id"],"filter":[{"op":"gte","field":"id","value":0}]}'
        $ResourceUri    = '/V1.0/Companies/query?search=' + [System.Uri]::EscapeDataString($Search)
    }

    process {

        $ApiKey = Get-AutoTaskAPIKey -AsPlainText -WarningAction SilentlyContinue

        if ([bool]$BaseURI -eq $false -or [bool]$ApiKey -eq $false) {
            Write-Error "The BaseURI and or API values are not set. Please run the Add-AutoTaskAPIKey & Add-AutoTaskBaseURI cmdlets before running this function"
            return
        }

        $TargetUri = ($BaseURI.TrimEnd('/') -replace '(?i)/v\d+(\.\d+)?$', '') + $ResourceUri
        Write-Verbose "Testing API values against [ $TargetUri ]"

        # Windows PowerShell does not always negotiate TLS 1.2 by default
        if ($PSEdition -eq 'Desktop') {
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        }

        try {

            $Headers = @{
                'ApiIntegrationCode'    = $ApiKey.ApiIntegrationCode
                'UserName'              = $ApiKey.Username
                'Secret'                = $ApiKey.Password
                'Accept'                = 'application/json'
            }

            $Parameters = @{
                'Method'            = 'GET'
                'Uri'               = $TargetUri
                'Headers'           = $Headers
                'UserAgent'         = $AutoTaskModuleUserAgent
                'UseBasicParsing'   = $true
            }

            $RestOutput = Invoke-WebRequest @Parameters -ErrorAction Stop

        }
        catch {

            # Windows PowerShell exposes StatusDescription, PowerShell Core exposes ReasonPhrase
            $Description = if ($PSEdition -eq 'Desktop') { $_.Exception.Response.StatusDescription } else { $_.Exception.Response.ReasonPhrase }

            [PSCustomObject]@{
                Method              = 'GET'
                StatusCode          = [int]$_.Exception.Response.StatusCode
                StatusDescription   = $Description
                Message             = $_.Exception.Message
                URI                 = $TargetUri
            }

        }
        finally {
            $Headers    = $null
            $ApiKey     = $null
        }

        if ($RestOutput) {

            [PSCustomObject]@{
                StatusCode          = [int]$RestOutput.StatusCode
                StatusDescription   = $RestOutput.StatusDescription
                URI                 = $TargetUri
            }

        }

    }

    end {}

}
