function Get-AutoTaskResource {
<#
    .SYNOPSIS
        Gets a resource

    .DESCRIPTION
        The Get-AutoTaskResource cmdlet gets a resource from the AutoTask API
        by ID or by using a simple or advanced search query

        Every resource of the AutoTask OpenAPI spec is supported, the -Resource parameter
        tab-completes the resource names & Show-AutoTaskResource lists them

        For a child resource, such as CompanyAlertsChild, the -ID parameter is the ID of the
        parent resource & the -ChildID parameter is the ID of the child resource

        Without -ID or a search query every item of the resource is queried, the first
        500 items are returned unless -AllResults is used

    .PARAMETER Resource
        Defines the name of the resource to get, such as Companies or CompanyAlertsChild

        Run Show-AutoTaskResource -Method GET to list the resources

    .PARAMETER ID
        Defines the ID of the resource to get

        For a child resource this is the ID of the parent resource, without -ChildID
        every child item of the parent is returned

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
        Defines the type of API method to use for an advanced search query

        By default a GET request is used unless the request url would be longer
        than 2048 characters, then a POST request is used

        Allowed values:
        'GET', 'POST'

    .PARAMETER Operation
        Defines the operation of the resource to use, such as QueryCount, QueryFieldDefinitions,
        or QueryInvoicePdf

        By default the operation is selected from the other parameters. Use this parameter for
        the other GET operations of a resource, Show-AutoTaskResource lists the operations

    .PARAMETER AllResults
        Returns all items from an endpoint

        By default only the first 500 items are returned

    .PARAMETER Raw
        Returns the full API response object, such as the items & the page details of a query

    .EXAMPLE
        Get-AutoTaskResource -Resource Companies -ID 8765309

        Get the company with ID 8765309

    .EXAMPLE
        Get-AutoTaskResource -Resource Companies -SimpleSearch "isActive eq true"

        Gets the first 500 active companies

    .EXAMPLE
        Get-AutoTaskResource -Resource Companies -AdvancedSearch '{"MaxRecords":100,"filter":[{"op":"eq","field":"IsActive","value":true},{"op":"and","items":[{"op":"beginsWith","field":"companyName","value":"D"}]}]}'

        Gets the first 100 active companies with a name starting with "D"

    .EXAMPLE
        Get-AutoTaskResource -Resource CompanyAlertsChild -ID 8765309

        Gets every alert of the company with ID 8765309

    .EXAMPLE
        Get-AutoTaskResource -Resource Companies -SimpleSearch "isActive eq true" -Operation QueryCount

        Gets the number of active companies

    .EXAMPLE
        Get-AutoTaskResource -Resource ThresholdApiIntegration

        Gets the API usage threshold information

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Resource/Get-AutoTaskResource.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ArgumentCompleter({ Complete-AutoTaskResource @args })]
        [ValidateNotNullOrEmpty()]
        [string]$Resource,

        [Parameter(Mandatory = $true, ParameterSetName = 'ID', ValueFromPipelineByPropertyName = $true)]
        [int64]$ID,

        [Parameter(Mandatory = $false, ParameterSetName = 'ID')]
        [int64]$ChildID,

        [Parameter(Mandatory = $true, ParameterSetName = 'SimpleSearch')]
        [ValidateNotNullOrEmpty()]
        [string]$SimpleSearch,

        [Parameter(Mandatory = $true, ParameterSetName = 'AdvancedSearch')]
        [ValidateNotNullOrEmpty()]
        [string]$AdvancedSearch,

        [Parameter(Mandatory = $false, ParameterSetName = 'AdvancedSearch')]
        [ValidateSet('GET', 'POST')]
        [string]$Method,

        [Parameter(Mandatory = $false)]
        [ArgumentCompleter({ Complete-AutoTaskResource @args })]
        [string]$Operation,

        [Parameter(Mandatory = $false, ParameterSetName = 'Index')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SimpleSearch')]
        [Parameter(Mandatory = $false, ParameterSetName = 'AdvancedSearch')]
        [switch]$AllResults,

        [Parameter(Mandatory = $false)]
        [switch]$Raw
    )

    begin {

        $FunctionName   = $MyInvocation.MyCommand.Name
        $ParameterName  = $FunctionName + '_Parameters' -replace '-','_'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $Supported = @(Get-AutoTaskResourceOperation -Resource $Resource -CommandName $FunctionName)
        if ($Supported.Count -eq 0) {
            if (@(Get-AutoTaskResourceOperation -Resource $Resource).Count) { throw "The [ $Resource ] resource does not support GET requests. Run Show-AutoTaskResource -Name $Resource to list its operations" }
            throw "The [ $Resource ] resource was not found. Run Show-AutoTaskResource to list the available resources"
        }

        $Names      = @($Supported | ForEach-Object { $_.Operation })
        $IsChild    = [bool]($Supported | Where-Object { $_.Operation -eq 'Query' -and $_.Method -eq 'GET' })
        $Search     = $null
        $PathValue  = @()

        switch ($PSCmdlet.ParameterSetName) {

            'ID' {

                $PathValue = @($ID)
                if ($PSBoundParameters.ContainsKey('ChildID')) { $PathValue += $ChildID }

                if (-not $Operation) {
                    $Operation = if ($IsChild) { if ($PSBoundParameters.ContainsKey('ChildID')) { 'QueryItem' } else { 'Query' } }
                                 elseif ($Names -contains 'QueryItem') { 'QueryItem' }
                                 else {
                                    # Resources such as InvoiceMarkupApiIntegration only have special operations
                                    $WithId = @($Supported | Where-Object { $_.Path -match '\{' -and $_.Method -eq 'GET' })
                                    if ($WithId.Count -ne 1) { throw "Use the -Operation parameter to select one of the operations of the [ $Resource ] resource: $(($WithId | ForEach-Object { $_.Operation }) -join ', ')" }
                                    $WithId[0].Operation
                                 }
                }

            }

            'Index' {

                if (-not $Operation) {
                    $WithoutId = @($Supported | Where-Object { $_.Path -notmatch '\{' -and $_.Method -eq 'GET' -and $_.Operation -notmatch 'EntityInformation|FieldDefinitions|^UrlParameter' })

                    if ($Names -contains 'Query' -and -not $IsChild) {
                        # Every item of the resource
                        $Search     = '{"filter":[{"op":"gte","field":"id","value":0}]}'
                        $Operation  = 'Query'
                    }
                    elseif ($IsChild) { throw "The [ $Resource ] resource is a child resource, use -ID with the ID of the parent resource" }
                    elseif ($WithoutId.Count -eq 1) { $Operation = $WithoutId[0].Operation }
                    else { throw "Use the -ID or -Operation parameter with the [ $Resource ] resource. Operations: $($Names -join ', ')" }
                }
                elseif ($Operation -in 'Query', 'QueryCount', 'UrlParameterQuery', 'UrlParameterQueryCount' -and -not $IsChild) {
                    $Search = '{"filter":[{"op":"gte","field":"id","value":0}]}'
                }

            }

            default {

                if ($IsChild -or $Names -notcontains 'Query') {
                    throw "The [ $Resource ] resource does not support search queries. A child resource is queried with -ID & the ID of the parent resource"
                }

                if ($PSCmdlet.ParameterSetName -eq 'SimpleSearch') {
                    $SearchOps  = @($SimpleSearch.Trim() -split '\s+')
                    $Filter     = [ordered]@{ op = $SearchOps[1]; field = $SearchOps[0] }
                    if ($SearchOps.Count -gt 2) { $Filter.value = ($SearchOps | Select-Object -Skip 2) -join ' ' }
                    $Search = ConvertTo-Json -InputObject @{ filter = @($Filter) } -Depth 5 -Compress
                }
                else { $Search = $AdvancedSearch }

                if (-not $Operation) { $Operation = 'Query' }

            }

        }

        if ($Search) {

            # A search uses the POST query (body) or the GET query (search url parameter)
            if ($Operation -like 'UrlParameter*')               { $UseGet = $true }
            elseif ($PSBoundParameters.ContainsKey('Method'))   { $UseGet = $Method -eq 'GET' }
            elseif ($PSBoundParameters.ContainsKey('Operation')) { $UseGet = $false }
            else {
                # The url of a GET request is limited to 2048 characters, 200 characters are kept for the path & paging
                $UseGet = ("$AutoTaskModuleBaseUri".Length + 200 + [System.Uri]::EscapeDataString($Search).Length) -lt 2048
            }

            $BaseOperation = $Operation -replace '^UrlParameter', ''
            if ($BaseOperation -notin 'Query', 'QueryCount') { throw "The [ $Operation ] operation cannot be used with a search query, use Query or QueryCount" }
            $Operation = if ($UseGet) { "UrlParameter$BaseOperation" } else { $BaseOperation }

        }

        $Target = Resolve-AutoTaskResource -Resource $Resource -Operation $Operation -CommandName $FunctionName -PathValue $PathValue

        $InvokeParams = @{
            Method      = $Target.Method
            ResourceURI = $Target.ResourceUri
            AllResults  = $AllResults
            Raw         = $Raw
        }

        if ($Search) {
            if ($Target.Method -eq 'GET') { $InvokeParams.UriFilter = @{ search = $Search } }
            else { $InvokeParams.Data = $Search }
        }

        Set-Variable -Name $ParameterName -Value $InvokeParams -Scope Global -Force -Confirm:$false

        Invoke-AutoTaskRequest @InvokeParams

    }

    end {}

}
