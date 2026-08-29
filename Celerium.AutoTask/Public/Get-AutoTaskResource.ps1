function Get-AutoTaskResource {
<#
    .SYNOPSIS
        Gets a resource

    .DESCRIPTION
        The Get-AutoTaskResource cmdlet gets a resource from the AutoTask API
        by ID or by using a simple or advanced search query

    .PARAMETER ID
        Defines the ID of the resource to get

    .PARAMETER ChildID
        Defines the ID of the child resource to get

    .PARAMETER SimpleSearch
        Defines a simple search query to use when getting the resource

        Limited to a single filter such as
        "isActive eq true" or "id eq 8765309"

    .PARAMETER AdvancedSearch
        Defines an advanced search query to use when getting the resource

        '{
            "MaxRecords":100,
            "filter":[
                {"op":"eq","field":"IsActive","value":true},
                {"op":"and","items":[
                    {"op":"beginsWith","field":"companyName","value":"D"}
                ]}
            ]
        }'

    .PARAMETER Method
        Defines the type of API method to use

        Allowed values:
        'GET', 'POST'

    .PARAMETER AllResults
        Returns all items from an endpoint

        By default only the first 500 items are returned

    .EXAMPLE
        Get-AutoTaskResource -Resource Companies -ID 8765309

        Get the company with ID 8765309

    .EXAMPLE
        Get-AutoTaskResource -Resource Companies -SimpleSearch "isActive eq true"

        Gets the first 500 active companies

    .EXAMPLE
        Get-AutoTaskResource -Resource Companies -AdvancedSearch '{"MaxRecords":100,"filter":[{"op":"eq","field":"IsActive","value":true},{"op":"and","items":[{"op":"beginsWith","field":"companyName","value":"D"}]}]}'

        Gets the first 100 active companies with a name starting with "D"

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Resource/Get-AutoTaskResource.html
#>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ID')]
        [int64]$ID,

        [Parameter(Mandatory = $false, ParameterSetName = 'ID')]
        [int64]$ChildID,

        [Parameter(Mandatory = $true, ParameterSetName = 'SimpleSearch')]
        [String]$SimpleSearch,

        [Parameter(Mandatory = $true, ParameterSetName = 'AdvancedSearch')]
        [String]$AdvancedSearch,

        [Parameter(Mandatory = $false, ParameterSetName = 'AdvancedSearch')]
        [ValidateSet('GET', 'POST')]
        [String]$Method,

        [Parameter(ParameterSetName = 'SimpleSearch')]
        [Parameter(ParameterSetName = 'AdvancedSearch')]
        [switch]$AllResults
    )

    DynamicParam {
        $AutoTaskModuleGetParameter
    }

    begin {

        $FunctionName       = $MyInvocation.InvocationName
        $ParameterName      = $functionName + '_Parameters'      -replace '-','_'

        $ResourceTarget     = $PSBoundParameters.Resource
        $ResourceIndex      = $AutoTaskModuleQueries | Group-Object Index -AsHashTable -AsString
        $ResourceEntry      = @(($ResourceIndex[$ResourceTarget] | Where-Object { $_.Get -eq $ResourceTarget }))[0]
        $ResourceUriName    = $ResourceEntry.Name -replace '/query$', '/{PARENTID}'

        # Fix path to InvoicePDF URL, must be unique vs. /Invoices in Swagger file
        $ResourceUriName    = $ResourceUriName -replace 'InvoicePDF', 'Invoices/{id}/InvoicePDF'

        if ($SimpleSearch) {
            $SearchOps      = $SimpleSearch -split ' '
            $AdvancedSearch    = ConvertTo-Json @{
                filter      = @(@{
                                field = $SearchOps[0]
                                op    = $SearchOps[1]
                                value = $SearchOps | Select-Object -Skip 2
                            })
            } -Compress
        }

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        if ($ResourceTarget -like "*child*" -and $AdvancedSearch) {
            Write-Warning "JSON search cannot be performed on child items use the parent ID"
            break
        }

        switch ($PSCmdlet.ParameterSetName) {
            'ID'    { $Method = 'GET'  }
            default { $Method = 'POST' }
        }

        $ResourceUri = $ResourceUriName
        if ($ID) { $ResourceUri = ("$ResourceUri" -replace '{parentid}', "$($ID)")  }

        if ($ChildID) { $ResourceUri = ("$($ResourceUri)/$ChildID") }

        if ($AdvancedSearch) {
            switch ($Method) {
                'GET'   { $ResourceUri = ("$ResourceUri/query?search=$AdvancedSearch" -replace '{PARENTID}', '')}
                'POST'  {
                    $ResourceUri    = ("$ResourceUri/query" -replace '{PARENTID}', '')
                    $Body           = $AdvancedSearch
                }
                Default {

                    if (($AutoTaskModuleBaseUri.Length + $ResourceUri.Length + $AdvancedSearch.Length + 15 + 120 + 100) -ge 2048){
                        #15 characters for "//query?search="
                        #TODO: Calculation does not include Overwritten ParentID and is currently a better estimation. Therefore a "safe factor" of +120 chars is used
                        #100 characters for Call of next page (Including "paging={"pageSize":500,"previousIds":[<ID>],"nextIds":[<ID>]}&" UTF-8 encoded)
                        Write-Information "Using POST-Request as Request exceeded limit of 2100 characters. You can use -Method GET/POST to set a fixed Method."
                        $ResourceUri    = ("$ResourceUri/query" -replace '{PARENTID}', '')
                        $Body           = $AdvancedSearch
                    }
                    else { $ResourceUri = ("$ResourceUri/query?search=$AdvancedSearch" -replace '{PARENTID}', '') }

                }

            }

        }

        if ($ResourceTarget -eq "InvoicePDF" -and $ID) {
            $ResourceUri = ("$($ResourceUri)" -replace '{id}', "$($ID)")
        }

        $InvokeParams = @{
            Method      = $Method
            ResourceURI = $ResourceUri
            AllResults  = $AllResults
        }

        if ($Method -eq 'POST') { $InvokeParams.Data = $Body }

        Set-Variable -Name $ParameterName -Value $InvokeParams -Scope Global -Force -Confirm:$false

        return Invoke-AutoTaskRequest @InvokeParams

    }

}