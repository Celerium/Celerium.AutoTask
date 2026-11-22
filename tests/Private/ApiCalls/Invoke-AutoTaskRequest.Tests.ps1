<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: Invoke-AutoTaskRequest.Tests.ps1
    Type: PowerShell

.SYNOPSIS
    Pester tests for the Invoke-AutoTaskRequest function

.DESCRIPTION
    Pester tests for the Invoke-AutoTaskRequest function

    No real API calls are made, Invoke-WebRequest is mocked in every test & a fallback mock throws

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

    function Set-TestConnection {
        Add-AutoTaskBaseURI -BaseURI 'https://api.example.org/atservicesrest'
        Add-AutoTaskAPIKey -ApiUsername 'user@example.org' -ApiSecretKey 'secret' -ApiIntegrationCode 'code'
    }
    Set-TestConnection

    function New-QueryResponse {
        # Creates a query response such as the /V1.0/Companies/query endpoint returns
        param ([int]$Page, [int]$TotalPages)
        $Next = if ($Page -lt $TotalPages) { "https://api.example.org/atservicesrest/V1.0/Companies/query/next?paging=$($Page + 1)" } else { $null }
        $Body = [ordered]@{
            items       = @( @{ id = "$Page-a" }, @{ id = "$Page-b" } )
            pageDetails = [ordered]@{ count = 2; requestCount = 500; prevPageUrl = $null; nextPageUrl = $Next }
        }
        New-FakeResponse -Content ($Body | ConvertTo-Json -Depth 5 -Compress)
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
    $CommandName = $PesterTestName -replace '.Tests.ps1',''
}

Describe "Testing [ $CommandName ] function with [ $PesterTestName ]" -Tag @('apiCalls') {

    Context "[ $CommandName ] write requests" {

        BeforeEach {
            Mock Invoke-WebRequest -ModuleName $ModuleName { New-FakeResponse -Content '{"itemId":123}' }
        }

        It "Exposes every method" {
            $Attribute = (Get-Command Invoke-AutoTaskRequest).Parameters['Method'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $Attribute.ValidValues | Should -Be @('GET', 'POST', 'PUT', 'PATCH', 'DELETE')
        }

        It "Sends the [ <_> ] method with the JSON body" -ForEach 'POST', 'PUT', 'PATCH', 'DELETE' {
            Invoke-AutoTaskRequest -Method $_ -ResourceURI '/V1.0/Companies' -Data @{ a = 1 } > $null

            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter {
                $Method -eq $_ -and "$Uri" -eq 'https://api.example.org/atservicesrest/V1.0/Companies' -and $Body -eq '{"a":1}' -and $ContentType -like 'application/json*'
            }
        }

        It "Returns the full response of a create request" {
            (Invoke-AutoTaskRequest -Method POST -ResourceURI '/V1.0/Companies' -Data @{ a = 1 }).itemId | Should -Be 123
        }

        It "Sends a JSON string body as is" {
            Invoke-AutoTaskRequest -Method PATCH -ResourceURI '/V1.0/Companies' -Data '{"id":1,"x":[1,2]}' > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { $Body -eq '{"id":1,"x":[1,2]}' }
        }

        It "Never retries a [ <_> ] write request" -ForEach 'POST', 'PUT', 'PATCH', 'DELETE' {
            Mock Invoke-WebRequest -ModuleName $ModuleName {
                $Ex = [FakeHttpException]::new('unavailable')
                $Ex.Response = [PSCustomObject]@{ StatusCode = 503; Headers = @{} }
                throw $Ex
            }
            { Invoke-AutoTaskRequest -Method $_ -ResourceURI '/V1.0/Companies' -Data @{ a = 1 } -WarningAction SilentlyContinue } | Should -Throw '*503*'
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly
            Should -Invoke Start-Sleep -ModuleName $ModuleName -Times 0 -Exactly
        }

        It "Never retries a GET request that is marked as a write request" {
            Mock Invoke-WebRequest -ModuleName $ModuleName {
                $Ex = [FakeHttpException]::new('unavailable')
                $Ex.Response = [PSCustomObject]@{ StatusCode = 503; Headers = @{} }
                throw $Ex
            }
            { Invoke-AutoTaskRequest -Method GET -ResourceURI '/V1.0/TimeOffRequests/1/Approve' -WriteRequest -WarningAction SilentlyContinue } | Should -Throw '*503*'
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly
        }

        It "Ignores -AllResults for a write request" {
            Mock Invoke-WebRequest -ModuleName $ModuleName { New-QueryResponse -Page 1 -TotalPages 3 }
            Invoke-AutoTaskRequest -Method PATCH -ResourceURI '/V1.0/Companies' -Data @{ a = 1 } -AllResults > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly
        }

    }

    Context "[ $CommandName ] request building" {

        BeforeEach {
            Mock Invoke-WebRequest -ModuleName $ModuleName { New-FakeResponse -Content '{"item":{"id":1}}' }
        }

        AfterEach {
            Set-TestConnection
        }

        It "Throws when the base uri or API values are not set" {
            Remove-AutoTaskAPIKey
            { Invoke-AutoTaskRequest -ResourceURI '/V1.0/Companies/1' } | Should -Throw '*Add-AutoTaskAPIKey*'
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 0 -Exactly
        }

        It "Throws when the base uri is not set" {
            Remove-AutoTaskBaseURI
            { Invoke-AutoTaskRequest -ResourceURI '/V1.0/Companies/1' } | Should -Throw '*Add-AutoTaskBaseURI*'
        }

        It "Sends a GET request with the AutoTask authentication headers & the user agent" {
            Invoke-AutoTaskRequest -ResourceURI '/V1.0/Companies/1' > $null

            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'GET' -and "$Uri" -eq 'https://api.example.org/atservicesrest/V1.0/Companies/1' -and
                $Headers['UserName'] -eq 'user@example.org' -and $Headers['Secret'] -eq 'secret' -and $Headers['ApiIntegrationCode'] -eq 'code' -and
                $Headers['Accept'] -eq 'application/json' -and $UserAgent -match '^Celerium.AutoTask/' -and $null -eq $Body
            }
        }

        It "Url encodes the query string parameters" {
            Invoke-AutoTaskRequest -ResourceURI '/V1.0/Companies/query' -UriFilter @{ search = '{"filter":[{"op":"eq","field":"id","value":0}]}' } > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter {
                ([uri]$Uri).AbsoluteUri -eq ('https://api.example.org/atservicesrest/V1.0/Companies/query?search=' + [System.Uri]::EscapeDataString('{"filter":[{"op":"eq","field":"id","value":0}]}'))
            }
        }

        It "Adds a missing leading slash & removes double slashes from the path" {
            Invoke-AutoTaskRequest -ResourceURI 'V1.0//Companies//query' > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { "$Uri" -eq 'https://api.example.org/atservicesrest/V1.0/Companies/query' }
        }

        It "Does not change double slashes in the query string" {
            Invoke-AutoTaskRequest -ResourceURI '/V1.0/Companies/query?search=http://a' > $null
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { "$Uri" -eq 'https://api.example.org/atservicesrest/V1.0/Companies/query?search=http://a' }
        }

        It "Does not store the API secret or integration code in the debug variable" {
            Invoke-AutoTaskRequest -ResourceURI '/V1.0/Companies/1' > $null
            $DebugValue = Get-Variable -Name 'Invoke_AutoTaskRequest_Parameters' -Scope Global -ValueOnly
            $DebugValue.Headers['Secret'] | Should -Be '*******'
            $DebugValue.Headers['ApiIntegrationCode'] | Should -Be '*******'
            ($DebugValue.Headers.Values -join ' ') | Should -Not -Match 'secret|code'
        }

        It "Does not leave the old global debug variables behind" {
            Invoke-AutoTaskRequest -ResourceURI '/V1.0/Companies/1' > $null
            Get-Variable -Name 'TEST_BASEURI', 'TEST_RESOURCEURI' -Scope Global -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

    }

    Context "[ $CommandName ] response handling" {

        It "Returns the item of a single resource response" {
            Mock Invoke-WebRequest -ModuleName $ModuleName { New-FakeResponse -Content '{"item":{"id":1,"companyName":"Example"}}' }
            (Invoke-AutoTaskRequest -ResourceURI '/V1.0/Companies/1').companyName | Should -Be 'Example'
        }

        It "Returns nothing when the item is null" {
            Mock Invoke-WebRequest -ModuleName $ModuleName { New-FakeResponse -Content '{"item":null}' }
            Invoke-AutoTaskRequest -ResourceURI '/V1.0/Companies/999' | Should -BeNullOrEmpty
        }

        It "Returns the items of a query response" {
            Mock Invoke-WebRequest -ModuleName $ModuleName { New-QueryResponse -Page 1 -TotalPages 3 }
            $Result = Invoke-AutoTaskRequest -Method POST -ResourceURI '/V1.0/Companies/query' -Data '{}'
            @($Result).Count | Should -Be 2
            $Result[0].id | Should -Be '1-a'
        }

        It "Returns the full response with -Raw" {
            Mock Invoke-WebRequest -ModuleName $ModuleName { New-QueryResponse -Page 1 -TotalPages 3 }
            $Result = Invoke-AutoTaskRequest -Method POST -ResourceURI '/V1.0/Companies/query' -Data '{}' -Raw
            $Result.pageDetails.nextPageUrl | Should -Not -BeNullOrEmpty
            @($Result.items).Count | Should -Be 2
        }

        It "Returns an object response as is, such as field definitions" {
            Mock Invoke-WebRequest -ModuleName $ModuleName { New-FakeResponse -Content '{"fields":[{"name":"id"},{"name":"companyName"}]}' }
            @((Invoke-AutoTaskRequest -ResourceURI '/V1.0/Companies/entityInformation/fields').fields).Count | Should -Be 2
        }

        It "Returns nothing for an empty items array" {
            Mock Invoke-WebRequest -ModuleName $ModuleName { New-FakeResponse -Content '{"items":[],"pageDetails":{"count":0,"nextPageUrl":null}}' }
            Invoke-AutoTaskRequest -ResourceURI '/V1.0/Companies/query' | Should -BeNullOrEmpty
        }

        It "Returns an empty object for an empty response" {
            Mock Invoke-WebRequest -ModuleName $ModuleName { New-FakeResponse -Content '' }
            Invoke-AutoTaskRequest -Method DELETE -ResourceURI '/V1.0/ActionTypes/1' | Should -BeOfType [System.Management.Automation.PSCustomObject]
        }

        It "Decodes non ASCII characters as UTF-8" {
            Mock Invoke-WebRequest -ModuleName $ModuleName { New-FakeResponse -Content ('{"item":{"name":"Caf' + [char]0x00E9 + '"}}') -ContentType 'application/json' }
            (Invoke-AutoTaskRequest -ResourceURI '/V1.0/Companies/1').name | Should -Be ('Caf' + [char]0x00E9)
        }

        It "Returns binary data as a byte array" {
            Mock Invoke-WebRequest -ModuleName $ModuleName { New-FakeResponse -Bytes ([byte[]](37, 80, 68, 70)) -ContentType 'application/pdf' }
            $Result = Invoke-AutoTaskRequest -ResourceURI '/V1.0/Invoices/1/InvoicePdf'
            $Result.GetType().Name | Should -Be 'Byte[]'
        }

    }

    Context "[ $CommandName ] paging" {

        BeforeEach {
            Mock Invoke-WebRequest -ModuleName $ModuleName {
                $Page = if ("$Uri" -match 'paging=(\d+)') { [int]$Matches[1] } else { 1 }
                New-QueryResponse -Page $Page -TotalPages 3
            }
        }

        It "Returns only the first page by default" {
            @(Invoke-AutoTaskRequest -Method POST -ResourceURI '/V1.0/Companies/query' -Data '{}').Count | Should -Be 2
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly
        }

        It "Follows the next page url with -AllResults & sends the query body again" {
            $Result = Invoke-AutoTaskRequest -Method POST -ResourceURI '/V1.0/Companies/query' -Data '{"filter":[]}' -AllResults

            @($Result).Count | Should -Be 6
            $Result.id | Should -Be @('1-a', '1-b', '2-a', '2-b', '3-a', '3-b')
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 3 -Exactly -ParameterFilter { $Method -eq 'POST' -and $Body -eq '{"filter":[]}' }
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { "$Uri" -like '*paging=3' }
        }

        It "Returns every item & the last page details with -AllResults -Raw" {
            $Result = Invoke-AutoTaskRequest -ResourceURI '/V1.0/Companies/query' -AllResults -Raw
            @($Result.items).Count | Should -Be 6
            $Result.PSObject.Properties.Name | Should -Contain 'pageDetails'
        }

        It "Does not follow a next page url on another host" {
            Mock Invoke-WebRequest -ModuleName $ModuleName {
                New-FakeResponse -Content '{"items":[{"id":1}],"pageDetails":{"count":1,"nextPageUrl":"https://evil.example.com/V1.0/Companies/query/next"}}'
            }
            @(Invoke-AutoTaskRequest -ResourceURI '/V1.0/Companies/query' -AllResults -WarningAction SilentlyContinue).Count | Should -Be 1
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly
        }

    }

    Context "[ $CommandName ] error handling" {

        It "Does not retry a [ <Status> ] response" -ForEach @(
            @{ Status = 400; Message = '*400*' }
            @{ Status = 401; Message = '*401*Unauthorized*' }
            @{ Status = 403; Message = '*403*Forbidden*' }
            @{ Status = 404; Message = '*404*not found*' }
            @{ Status = 500; Message = '*500*' }
        ) {
            Mock Invoke-WebRequest -ModuleName $ModuleName {
                $Ex = [FakeHttpException]::new('failed')
                $Ex.Response = [PSCustomObject]@{ StatusCode = $Status; Headers = @{} }
                throw $Ex
            }
            { Invoke-AutoTaskRequest -ResourceURI '/V1.0/Companies/1' -WarningAction SilentlyContinue } | Should -Throw $Message
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 1 -Exactly
        }

        It "Retries a read [ <_> ] response & then succeeds" -ForEach 429, 502, 503, 504 {
            $Script:Attempt = 0
            $Status = $_
            Mock Invoke-WebRequest -ModuleName $ModuleName {
                $Script:Attempt++
                if ($Script:Attempt -lt 2) {
                    $Ex = [FakeHttpException]::new('unavailable')
                    $Ex.Response = [PSCustomObject]@{ StatusCode = $Status; Headers = @{} }
                    throw $Ex
                }
                New-FakeResponse -Content '{"item":{"id":1}}'
            }

            (Invoke-AutoTaskRequest -ResourceURI '/V1.0/Companies/1' -WarningAction SilentlyContinue).id | Should -Be 1
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 2 -Exactly
            Should -Invoke Start-Sleep -ModuleName $ModuleName -Times 1 -Exactly
        }

        It "Retries a POST query because it does not change data" {
            $Script:Attempt = 0
            Mock Invoke-WebRequest -ModuleName $ModuleName {
                $Script:Attempt++
                if ($Script:Attempt -lt 2) {
                    $Ex = [FakeHttpException]::new('rate limited')
                    $Ex.Response = [PSCustomObject]@{ StatusCode = 429; Headers = @{} }
                    throw $Ex
                }
                New-QueryResponse -Page 1 -TotalPages 1
            }
            @(Invoke-AutoTaskRequest -Method POST -ResourceURI '/V1.0/Companies/query' -Data '{}' -WarningAction SilentlyContinue).Count | Should -Be 2
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 2 -Exactly
        }

        It "Stops after the maximum number of retries" {
            Mock Invoke-WebRequest -ModuleName $ModuleName {
                $Ex = [FakeHttpException]::new('unavailable')
                $Ex.Response = [PSCustomObject]@{ StatusCode = 503; Headers = @{} }
                throw $Ex
            }
            { Invoke-AutoTaskRequest -ResourceURI '/V1.0/Companies/1' -WarningAction SilentlyContinue } | Should -Throw '*Maximum retry attempts*'
            Should -Invoke Invoke-WebRequest -ModuleName $ModuleName -Times 3 -Exactly
        }

        It "Honors the Retry-After header when rate limited" {
            $Script:Attempt = 0
            Mock Invoke-WebRequest -ModuleName $ModuleName {
                $Script:Attempt++
                if ($Script:Attempt -lt 2) {
                    $Ex = [FakeHttpException]::new('rate limited')
                    $Ex.Response = [PSCustomObject]@{ StatusCode = 429; Headers = @{ 'Retry-After' = '7' } }
                    throw $Ex
                }
                New-FakeResponse -Content '{"item":{"id":1}}'
            }

            Invoke-AutoTaskRequest -ResourceURI '/V1.0/Companies/1' -WarningAction SilentlyContinue > $null
            Should -Invoke Start-Sleep -ModuleName $ModuleName -Times 1 -Exactly -ParameterFilter { $Seconds -eq 7 }
        }

        It "Uses the AutoTask error detail in the exception message" {
            Mock Invoke-WebRequest -ModuleName $ModuleName {
                $Ex = [FakeHttpException]::new('Internal Server Error')
                $Ex.Response = [PSCustomObject]@{ StatusCode = 500; Headers = @{} }
                $Record = [System.Management.Automation.ErrorRecord]::new($Ex, 'ServerError', 'InvalidOperation', $null)
                $Record.ErrorDetails = [System.Management.Automation.ErrorDetails]::new('{"errors":["Missing ApiIntegrationCode header"]}')
                throw $Record
            }
            { Invoke-AutoTaskRequest -ResourceURI '/V1.0/Companies/1' -WarningAction SilentlyContinue } | Should -Throw '*Missing ApiIntegrationCode header*'
        }

    }

}
