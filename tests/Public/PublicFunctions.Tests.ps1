<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: PublicFunctions.Tests.ps1
    Type: PowerShell

.SYNOPSIS
    Pester tests for the generic public functions

.DESCRIPTION
    Pester tests for Get-AutoTaskResource, New-AutoTaskResource, Set-AutoTaskResource, Remove-AutoTaskResource,
    New-AutoTaskBody, & Show-AutoTaskResource

    The request that each function sends (method, uri, & body) is checked against the resource map that is
    created from the OpenAPI spec. Invoke-WebRequest is mocked in every test & a fallback mock throws, so no
    real request is ever made. The write functions are checked for -WhatIf, ConfirmImpact High, & no retries

.PARAMETER ModuleName
    The name of the local module to import

.PARAMETER Version
    The version of the local module to import

.PARAMETER BuildTarget
    Which version of the module to run tests against

    Allowed values:
        'built', 'notBuilt'

.LINK
    https://celerium.org

#>

#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='6.0.0' }

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$ModuleName = 'Celerium.AutoTask',

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Version,

    [Parameter(Mandatory=$true)]
    [ValidateSet('built','notBuilt')]
    [string]$BuildTarget
)

BeforeAll {
    $TestsPath = $PSScriptRoot
    while ($TestsPath -and -not (Test-Path -Path (Join-Path -Path $TestsPath -ChildPath 'TestHelper.ps1'))) { $TestsPath = Split-Path -Path $TestsPath -Parent }
    . (Join-Path -Path $TestsPath -ChildPath 'TestHelper.ps1')

    Import-TestModule -ModuleName $ModuleName -Version $Version -BuildTarget $BuildTarget
    Add-FakeHttpException

    Add-AutoTaskBaseURI -BaseURI 'https://api.example.org/atservicesrest'
    Add-AutoTaskAPIKey -ApiUsername 'user@example.org' -ApiSecretKey 'secret' -ApiIntegrationCode 'code'

    $Base = 'https://api.example.org/atservicesrest'

    function Get-SearchFromUri {
        # Returns the decoded search parameter of a request uri
        param ([string]$Uri)
        if ($Uri -match '[?&]search=([^&]+)') { return [System.Uri]::UnescapeDataString($Matches[1]) | ConvertFrom-Json }
    }

    Mock Start-Sleep -ModuleName $ModuleName {}

    # Safety net so that a test without its own mock can never make a real request
    Mock Invoke-WebRequest -ModuleName $ModuleName { throw 'Unexpected un-mocked request' }
    Mock Invoke-RestMethod -ModuleName $ModuleName { throw 'Unexpected un-mocked request' }
}

AfterAll {
    Remove-TestModule -ModuleName $ModuleName
}

BeforeDiscovery {
    $PesterTestName = (Get-Item -Path $PSCommandPath).Name
    $WriteFunctions = 'New-AutoTaskResource', 'Set-AutoTaskResource', 'Remove-AutoTaskResource'
}

Describe "Testing the public functions with [ $PesterTestName ]" -Tag @('public') {

    Context "Write safety" {

        It "[ <_> ] supports ShouldProcess with ConfirmImpact High" -ForEach $WriteFunctions {
            $Binding = (Get-Command -Name $_).ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
            $Binding.SupportsShouldProcess | Should -BeTrue
            $Binding.ConfirmImpact | Should -Be 'High'
        }

        It "[ <_> ] does not send a request with -WhatIf" -ForEach $WriteFunctions {
            $Params = @{ Resource = 'Companies'; WhatIf = $true }
            $Command = $_
            switch ($Command) {
                'New-AutoTaskResource'      { $Params.Data = @{ companyName = 'Example' } }
                'Set-AutoTaskResource'      { $Params.Data = @{ phone = '1' }; $Params.ID = 5 }
                'Remove-AutoTaskResource'   { $Params.Resource = 'ActionTypes'; $Params.ID = 5 }
            }
            & $Command @Params
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 0 -Exactly
        }

        It "[ <_> ] never retries a failed request" -ForEach $WriteFunctions {
            Mock Invoke-WebRequest -ModuleName $ModuleName {
                $Ex = [FakeHttpException]::new('unavailable')
                $Ex.Response = [PSCustomObject]@{ StatusCode = 503; Headers = @{} }
                throw $Ex
            }
            $Params = @{ Resource = 'Companies'; Confirm = $false; WarningAction = 'SilentlyContinue' }
            $Command = $_
            switch ($Command) {
                'New-AutoTaskResource'      { $Params.Data = @{ companyName = 'Example' } }
                'Set-AutoTaskResource'      { $Params.Data = @{ phone = '1' }; $Params.ID = 5 }
                'Remove-AutoTaskResource'   { $Params.Resource = 'ActionTypes'; $Params.ID = 5 }
            }
            { & $Command @Params } | Should -Throw '*503*'
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly
            Should -Invoke Start-Sleep -ModuleName $ModuleName -Times 0 -Exactly
        }

        It "[ <_> ] tab-completes & validates the -Operation parameter" -ForEach (@('Get-AutoTaskResource') + $WriteFunctions) {
            $Completer = (Get-Command -Name $_).Parameters['Operation'].Attributes | Where-Object { $_ -is [System.Management.Automation.ArgumentCompleterAttribute] }
            "$($Completer.ScriptBlock)" | Should -Match 'Complete-AutoTaskResource'
        }

    }

    Context "[ Get-AutoTaskResource ]" {

        BeforeEach {
            Mock Invoke-WebRequest -ModuleName $ModuleName {
                if ("$Uri" -match '/query') { New-FakeResponse -Content '{"items":[{"id":1},{"id":2}],"pageDetails":{"count":2,"nextPageUrl":null}}' }
                else { New-FakeResponse -Content '{"item":{"id":5}}' }
            }
        }

        It "Gets a resource by ID" {
            (Get-AutoTaskResource -Resource Companies -ID 5).id | Should -Be 5
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { $Method -eq 'GET' -and "$Uri" -eq "$Base/V1.0/Companies/5" }
        }

        It "Accepts the resource name by position & in any case" {
            Get-AutoTaskResource companies -ID 5 > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { "$Uri" -eq "$Base/V1.0/Companies/5" }
        }

        It "Gets a resource whose path does not match its name" {
            Get-AutoTaskResource -Resource OrganizationalLevel1 -ID 5 > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { "$Uri" -eq "$Base/V1.0/OrganizationalLevel1s/5" }
        }

        It "Gets every child item of a parent with -ID" {
            Get-AutoTaskResource -Resource CompanyAlertsChild -ID 5 > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { $Method -eq 'GET' -and "$Uri" -eq "$Base/V1.0/Companies/5/Alerts" }
        }

        It "Gets a child item with -ID & -ChildID" {
            Get-AutoTaskResource -Resource CompanyAlertsChild -ID 5 -ChildID 7 > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { "$Uri" -eq "$Base/V1.0/Companies/5/Alerts/7" }
        }

        It "Sends a simple search as a GET query" {
            @(Get-AutoTaskResource -Resource Companies -SimpleSearch 'isActive eq true').Count | Should -Be 2
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter {
                $Search = Get-SearchFromUri -Uri "$Uri"
                $Method -eq 'GET' -and "$Uri" -like "$Base/V1.0/Companies/query?search=*" -and
                $Search.filter[0].field -eq 'isActive' -and $Search.filter[0].op -eq 'eq' -and $Search.filter[0].value -eq 'true'
            }
        }

        It "Keeps the spaces of a simple search value" {
            Get-AutoTaskResource -Resource Companies -SimpleSearch 'companyName beginsWith Example Company' > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { (Get-SearchFromUri -Uri "$Uri").filter[0].value -eq 'Example Company' }
        }

        It "Sends an advanced search as a POST query with -Method POST" {
            $Search = '{"MaxRecords":10,"filter":[{"op":"eq","field":"isActive","value":true}]}'
            Get-AutoTaskResource -Resource Companies -AdvancedSearch $Search -Method POST > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { $Method -eq 'POST' -and "$Uri" -eq "$Base/V1.0/Companies/query" -and $Body -eq $Search }
        }

        It "Uses a POST query when the url would be too long" {
            $Search = '{"filter":[{"op":"in","field":"id","value":[' + ((1..600) -join ',') + ']}]}'
            Get-AutoTaskResource -Resource Companies -AdvancedSearch $Search > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { $Method -eq 'POST' -and "$Uri" -eq "$Base/V1.0/Companies/query" }
        }

        It "Counts the items of a search with -Operation QueryCount" {
            Mock Invoke-WebRequest -ModuleName $ModuleName { New-FakeResponse -Content '{"queryCount":42}' }
            (Get-AutoTaskResource -Resource Companies -SimpleSearch 'isActive eq true' -Operation QueryCount).queryCount | Should -Be 42
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { $Method -eq 'POST' -and "$Uri" -eq "$Base/V1.0/Companies/query/count" }
        }

        It "Queries every item of a resource without -ID or a search" {
            Get-AutoTaskResource -Resource Companies > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'GET' -and (Get-SearchFromUri -Uri "$Uri").filter[0].op -eq 'gte' -and "$Uri" -like "$Base/V1.0/Companies/query?*"
            }
        }

        It "Gets a resource that only has one operation without -ID" {
            Mock Invoke-WebRequest -ModuleName $ModuleName { New-FakeResponse -Content '{"externalRequestThreshold":10000,"currentTimeframeRequestCount":1}' }
            (Get-AutoTaskResource -Resource ThresholdApiIntegration).externalRequestThreshold | Should -Be 10000
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { $Method -eq 'GET' -and "$Uri" -eq "$Base/V1.0/ThresholdInformation" }
        }

        It "Gets the field definitions with -Operation QueryFieldDefinitions" {
            Mock Invoke-WebRequest -ModuleName $ModuleName { New-FakeResponse -Content '{"fields":[{"name":"id"}]}' }
            (Get-AutoTaskResource -Resource Companies -Operation QueryFieldDefinitions).fields.name | Should -Be 'id'
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { "$Uri" -eq "$Base/V1.0/Companies/entityInformation/fields" }
        }

        It "Requires -Operation for a resource with more than one ID operation" {
            { Get-AutoTaskResource -Resource InvoiceMarkupApiIntegration -ID 5 } | Should -Throw '*-Operation*'
            Get-AutoTaskResource -Resource InvoiceMarkupApiIntegration -ID 5 -Operation QueryInvoicePdf > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { "$Uri" -eq "$Base/V1.0/Invoices/5/InvoicePdf" }
        }

        It "Does not search a child resource" {
            { Get-AutoTaskResource -Resource CompanyAlertsChild -SimpleSearch 'id gt 0' } | Should -Throw '*child*'
            { Get-AutoTaskResource -Resource CompanyAlertsChild } | Should -Throw '*child*'
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 0 -Exactly
        }

        It "Throws for an unknown resource without a request" {
            { Get-AutoTaskResource -Resource NotAResource -ID 1 } | Should -Throw '*not found*'
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 0 -Exactly
        }

        It "Throws for an operation that is not a GET operation" {
            { Get-AutoTaskResource -Resource Companies -Operation PatchEntity } | Should -Throw '*does not support*'
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 0 -Exactly
        }

        It "Gets every page with -AllResults" {
            Mock Invoke-WebRequest -ModuleName $ModuleName {
                if ("$Uri" -like '*next*') { New-FakeResponse -Content '{"items":[{"id":3}],"pageDetails":{"count":1,"nextPageUrl":null}}' }
                else { New-FakeResponse -Content '{"items":[{"id":1},{"id":2}],"pageDetails":{"count":2,"nextPageUrl":"https://api.example.org/atservicesrest/V1.0/Companies/query/next?paging=2"}}' }
            }
            @(Get-AutoTaskResource -Resource Companies -SimpleSearch 'isActive eq true' -AllResults).Count | Should -Be 3
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 2 -Exactly
        }

        It "Gets the ID from the pipeline" {
            [PSCustomObject]@{ id = 5 } | Get-AutoTaskResource -Resource Companies > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { "$Uri" -eq "$Base/V1.0/Companies/5" }
        }

        It "Only sends GET requests & POST queries" {
            Get-AutoTaskResource -Resource Companies -ID 5 > $null
            Get-AutoTaskResource -Resource Companies -AdvancedSearch '{"filter":[]}' -Method POST > $null
            Get-AutoTaskResource -Resource CompanyNotesChild -ID 5 > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 0 -Exactly -ParameterFilter { $Method -notin 'GET', 'POST' -or ($Method -eq 'POST' -and "$Uri" -notmatch '/query(/count)?$') }
        }

    }

    Context "[ New-AutoTaskResource ]" {

        BeforeEach {
            Mock Invoke-WebRequest -ModuleName $ModuleName { New-FakeResponse -Content '{"itemId":99}' }
        }

        It "Creates a resource & returns the new item ID" {
            (New-AutoTaskResource -Resource Companies -Data @{ companyName = 'Example' } -Confirm:$false).itemId | Should -Be 99
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { $Method -eq 'POST' -and "$Uri" -eq "$Base/V1.0/Companies" -and $Body -eq '{"companyName":"Example"}' }
        }

        It "Creates a child resource with -ParentId" {
            New-AutoTaskResource -Resource CompanyNotesChild -ParentId 5 -Data @{ title = 'Note' } -Confirm:$false > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { $Method -eq 'POST' -and "$Uri" -eq "$Base/V1.0/Companies/5/Notes" }
        }

        It "Requires -ParentId for a child resource" {
            { New-AutoTaskResource -Resource CompanyNotesChild -Data @{ title = 'Note' } -Confirm:$false } | Should -Throw '*-ParentId*'
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 0 -Exactly
        }

        It "Uses another POST operation with -Operation" {
            New-AutoTaskResource -Resource AccountInvoiceSettings -Operation AddContactRecipients -ParentId 5 -Data @(@{ id = 1 }) -Confirm:$false > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { $Method -eq 'POST' -and "$Uri" -eq "$Base/V1.0/Companies/5/invoiceSettings/contactRecipients" }
        }

        It "Does not create a query with -Operation Query" {
            { New-AutoTaskResource -Resource Companies -Operation Query -Data @{ a = 1 } -Confirm:$false } | Should -Throw '*does not support*'
        }

        It "Creates each object from the pipeline" {
            @{ companyName = 'A' }, @{ companyName = 'B' } | New-AutoTaskResource -Resource Companies -Confirm:$false > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 2 -Exactly
        }

    }

    Context "[ Set-AutoTaskResource ]" {

        BeforeEach {
            Mock Invoke-WebRequest -ModuleName $ModuleName { New-FakeResponse -Content '{"itemId":5}' }
        }

        It "Sends a PATCH request with the ID in the body" {
            Set-AutoTaskResource -Resource Companies -ID 5 -Data @{ phone = '1' } -Confirm:$false > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter {
                $Data = $Body | ConvertFrom-Json
                $Method -eq 'PATCH' -and "$Uri" -eq "$Base/V1.0/Companies" -and $Data.id -eq 5 -and $Data.phone -eq '1'
            }
        }

        It "Does not change the object of the caller" {
            $Data = [PSCustomObject]@{ phone = '1' }
            Set-AutoTaskResource -Resource Companies -ID 5 -Data $Data -Confirm:$false > $null
            $Data.PSObject.Properties.Name | Should -Not -Contain 'id'
        }

        It "Adds the ID to a JSON string body" {
            Set-AutoTaskResource -Resource Companies -ID 5 -Data '{"phone":"1"}' -Confirm:$false > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { ($Body | ConvertFrom-Json).id -eq 5 }
        }

        It "Updates an object from the pipeline" {
            [PSCustomObject]@{ id = 5; phone = '2' } | Set-AutoTaskResource -Resource Companies -Confirm:$false > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { ($Body | ConvertFrom-Json).id -eq 5 -and ($Body | ConvertFrom-Json).phone -eq '2' }
        }

        It "Updates a child resource with -ParentId" {
            Set-AutoTaskResource -Resource CompanyNotesChild -ParentId 5 -ID 7 -Data @{ title = 'x' } -Confirm:$false > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { $Method -eq 'PATCH' -and "$Uri" -eq "$Base/V1.0/Companies/5/Notes" }
        }

        It "Sends a PUT request with -Operation UpdateEntity" {
            Set-AutoTaskResource -Resource Companies -ID 5 -Data @{ phone = '1' } -Operation UpdateEntity -Confirm:$false > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { $Method -eq 'PUT' -and "$Uri" -eq "$Base/V1.0/Companies" }
        }

    }

    Context "[ Remove-AutoTaskResource ]" {

        BeforeEach {
            Mock Invoke-WebRequest -ModuleName $ModuleName { New-FakeResponse -Content '{"itemId":5}' }
        }

        It "Sends a DELETE request" {
            Remove-AutoTaskResource -Resource ActionTypes -ID 5 -Confirm:$false > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { $Method -eq 'DELETE' -and "$Uri" -eq "$Base/V1.0/ActionTypes/5" -and $null -eq $Body }
        }

        It "Deletes a child resource with -ID & -ChildID" {
            Remove-AutoTaskResource -Resource CompanyToDosChild -ID 5 -ChildID 7 -Confirm:$false > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { $Method -eq 'DELETE' -and "$Uri" -eq "$Base/V1.0/Companies/5/ToDos/7" }
        }

        It "Requires -ChildID for a child resource" {
            { Remove-AutoTaskResource -Resource CompanyToDosChild -ID 5 -Confirm:$false } | Should -Throw '*-ChildID*'
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 0 -Exactly
        }

        It "Throws for a resource that cannot be deleted" {
            { Remove-AutoTaskResource -Resource Companies -ID 5 -Confirm:$false } | Should -Throw '*does not support*'
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 0 -Exactly
        }

    }

    Context "[ New-AutoTaskBody ]" {

        BeforeEach {
            Mock Invoke-WebRequest -ModuleName $ModuleName {
                if ("$Uri" -like '*userDefinedFields') { New-FakeResponse -Content '{"fields":[{"name":"Udf1","value":null}]}' }
                else { New-FakeResponse -Content '{"fields":[{"name":"id","dataType":"long","isReadOnly":true},{"name":"companyName","dataType":"string","isReadOnly":false,"isRequired":true},{"name":"companyType","dataType":"integer","isReadOnly":false,"picklistValues":[{"label":"Customer","value":"1","isActive":true}]}]}' }
            }
        }

        It "Returns the field definitions & the user defined fields" {
            $Result = @(New-AutoTaskBody -Resource Companies)
            $Result.Name | Should -Be @('id', 'companyName', 'companyType', 'userDefinedFields')
            ($Result | Where-Object { $_.Name -eq 'companyType' }).PickListValues.Label | Should -Be 'Customer'
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { $Method -eq 'GET' -and "$Uri" -eq "$Base/V1.0/Companies/entityInformation/fields" }
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { $Method -eq 'GET' -and "$Uri" -eq "$Base/V1.0/Companies/entityInformation/userDefinedFields" }
        }

        It "Returns an empty body without the read-only fields with -Empty" {
            $Result = New-AutoTaskBody -Resource Companies -Empty
            $Result.PSObject.Properties.Name | Should -Be @('companyName', 'companyType')
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly
        }

        It "Uses a parent ID for a child resource" {
            New-AutoTaskBody -Resource CompanyNotesChild -Empty > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { "$Uri" -eq "$Base/V1.0/Companies/0/Notes/entityInformation/fields" }
        }

        It "Does not send a request with -WhatIf" {
            New-AutoTaskBody -Resource Companies -WhatIf | Should -BeNullOrEmpty
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 0 -Exactly
        }

        It "Throws for an unknown resource" {
            { New-AutoTaskBody -Resource NotAResource } | Should -Throw '*field definitions*'
        }

    }

    Context "[ Show-AutoTaskResource ]" {

        It "Shows every operation of the resource map" {
            @(Show-AutoTaskResource).Count | Should -Be @(Get-AutoTaskResourceMap).Count
        }

        It "Filters by resource name & method" {
            $Result = @(Show-AutoTaskResource -Name Companies -Method GET)
            $Result.Count | Should -BeGreaterThan 0
            @($Result | Where-Object { $_.Method -ne 'GET' -or $_.Resource -notlike 'Companies*' }).Count | Should -Be 0
            $Result[0].PSObject.Properties.Name | Should -Be @('Method', 'Resource', 'Operation', 'Path', 'Index')
        }

        It "Returns unique resource names with -UniqueOnly" {
            @(Show-AutoTaskResource -UniqueOnly).Count | Should -Be @((Get-AutoTaskResourceMap).Resource | Select-Object -Unique).Count
        }

        It "Reads another spec with -JsonSpec" {
            $Path = Join-Path -Path $TestDrive -ChildPath 'spec.json'
            Set-Content -Path $Path -Value '{"swagger":"2.0","paths":{"/V1.0/Things/{id}":{"get":{"tags":["Things"],"operationId":"Things_QueryItem"}}}}'
            $Result = @(Show-AutoTaskResource -JsonSpec $Path)
            $Result.Count | Should -Be 1
            $Result[0].Resource | Should -Be 'Things'
            $Result[0].Index | Should -Be 'Things'
        }

    }

}
