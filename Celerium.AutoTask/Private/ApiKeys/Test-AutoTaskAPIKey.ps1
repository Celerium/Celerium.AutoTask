function Test-AutoTaskAPIKey {
<#
    .SYNOPSIS
        Test the AutoTask API key

    .DESCRIPTION
        The Test-AutoTaskAPIKey cmdlet tests the base URI & API key that
        are defined in the Get-AutoTaskBaseURI & Get-AutoTaskAPIKey cmdlets

        Helpful when needing to validate general functionality or when using
        RMM deployment tools

    .PARAMETER BaseUri
        Define the base URI for the AutoTask API connection
        using AutoTask's URI or a custom URI

        By default the value used is the one defined by the
        Get-AutoTaskBaseURI function

    .EXAMPLE
        Test-AutoTaskAPIKey

        Tests the base URI & API key that are defined in the
        Get-AutoTaskBaseURI & Get-AutoTaskAPIKey cmdlets

    .EXAMPLE
        Test-AutoTaskAPIKey -BaseUri http://myapi.gateway.celerium.org

        Tests the defined base URI & API key that was defined in
        the Get-AutoTaskAPIKey cmdlet

        The full base uri test path in this example is:
            http://myapi.gateway.celerium.org/Companies/query

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Test-AutoTaskAPIKey.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Test')]
    Param (
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$BaseUri = $AutoTaskModuleBaseUriComplete
    )

    begin { $ResourceUri = "/Companies/query?Search" }

    process {

        if ([bool]$BaseUri -eq $false -or [bool](Get-AutoTaskAPIKey -ErrorAction Stop) -eq $false) {
            Write-Error "The BaseUri and or ApiKeys are not set. Please run the Get-AutoTaskApiKey & Get-AutoTaskBaseURI cmdlets before running this function"
            return
        }

        Write-Verbose "Testing API key against [ $($BaseUri + $ResourceUri) ]"

        try {

            $ApiSecret  = Get-AutoTaskAPIKey -AsPlainText
            $Headers    = @{
                'ApiIntegrationCode'    = $ApiSecret.ApiIntegrationCode
                'UserName'              = $ApiSecret.Username
                'Secret'                = $ApiSecret.Password
                'Content-Type'          = "application/json"
            }

            $Body = @{
                MaxRecords = 1
                filter = @(
                    @{
                        op    = "gte"
                        field = "id"
                        value = 0
                    }
                )
            } | ConvertTo-Json -Depth 5

            $Parameters = @{
                'Method'        = 'POST'
                'Uri'           = $BaseUri + $ResourceUri
                'Headers'       = $Headers
                'Body'          = $Body
                'UserAgent'     = $AutoTaskModuleUserAgent
                UseBasicParsing = $true
            }

            $RestOutput = Invoke-WebRequest @Parameters -ErrorAction Stop

        }
        catch {

            [PSCustomObject]@{
                Method              = $_.Exception.Response.Method
                StatusCode          = $_.Exception.Response.StatusCode.value__
                StatusDescription   = $_.Exception.Response.StatusDescription
                Message             = $_.Exception.Message
                URI                 = $($BaseUri + $ResourceUri)
            }

        } finally {
            [void] ($Headers)
        }

        if ($RestOutput) {
            $Data = @{}
            $Data = $RestOutput

            [PSCustomObject]@{
                StatusCode          = $Data.StatusCode
                StatusDescription   = $Data.StatusDescription
                URI                 = $($BaseUri + $ResourceUri)
            }
        }

    }

    end {}

}