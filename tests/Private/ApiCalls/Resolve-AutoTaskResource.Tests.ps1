<#
.NOTES
    Copyright 1990-2027 Celerium

    NAME: Resolve-AutoTaskResource.Tests.ps1
    Type: PowerShell

.SYNOPSIS
    Pester tests for the resource map functions

.DESCRIPTION
    Pester tests for the Get-AutoTaskSpecOperation, Get-AutoTaskResourceMap, Get-AutoTaskResourceOperation,
    Resolve-AutoTaskResource, & Complete-AutoTaskResource functions

    The tests are driven by the OpenAPI spec in the module folder, no web requests are made

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

    # Safety net, none of these functions make a web request
    Mock Invoke-WebRequest -ModuleName $ModuleName { throw 'Unexpected un-mocked request' }
    Mock Invoke-RestMethod -ModuleName $ModuleName { throw 'Unexpected un-mocked request' }

    $SpecPath   = Get-TestSpecPath
    $Map        = @(Get-AutoTaskResourceMap)
    $Commands   = 'Get-AutoTaskResource', 'New-AutoTaskResource', 'Set-AutoTaskResource', 'Remove-AutoTaskResource'
}

AfterAll {
    Remove-TestModule -ModuleName $ModuleName
}

BeforeDiscovery {
    $PesterTestName = (Get-Item -Path $PSCommandPath).Name
}

Describe "Testing the resource map functions with [ $PesterTestName ]" -Tag @('apiCalls', 'resourceMap') {

    Context "[ Get-AutoTaskResourceMap ] & [ Get-AutoTaskSpecOperation ]" {

        It "The resource map matches the OpenAPI spec (run build\New-AutoTaskResourceMap.ps1 when this fails)" {
            $FromSpec = @(Get-AutoTaskSpecOperation -JsonSpec $SpecPath)
            $Map.Count | Should -Be $FromSpec.Count
            $Expected   = $FromSpec | ForEach-Object { "$($_.Resource)|$($_.Operation)|$($_.Method)|$($_.Path)" }
            $Actual     = $Map | ForEach-Object { "$($_.Resource)|$($_.Operation)|$($_.Method)|$($_.Path)" }
            Compare-Object -ReferenceObject $Expected -DifferenceObject $Actual -CaseSensitive | Should -BeNullOrEmpty
        }

        It "Every resource & operation pair is unique" {
            @($Map | Group-Object -Property Resource, Operation | Where-Object { $_.Count -gt 1 }).Count | Should -Be 0
        }

        It "Has the resources & operations of the spec" {
            $Map.Count | Should -BeGreaterThan 3000
            @($Map.Resource | Select-Object -Unique).Count | Should -BeGreaterThan 380
        }

        It "Reads an already converted spec" {
            $Spec = '{"swagger":"2.0","paths":{"/V1.0/Things/{id}":{"get":{"tags":["Things"],"operationId":"Things_QueryItem"},"delete":{"tags":["Things"],"operationId":"Things_DeleteEntity"}}}}' | ConvertFrom-Json
            $Result = @(Get-AutoTaskSpecOperation -Spec $Spec)
            $Result.Count | Should -Be 2
            $Result[0].Operation | Should -Be 'DeleteEntity'
            $Result[0].Method | Should -Be 'DELETE'
            $Result[1].Path | Should -Be '/V1.0/Things/{id}'
        }

        It "Throws when the spec file does not exist" {
            { Get-AutoTaskSpecOperation -JsonSpec (Join-Path -Path $TestDrive -ChildPath 'missing.json') } | Should -Throw '*not found*'
        }

    }

    Context "[ Get-AutoTaskResourceOperation ]" {

        It "Every operation of the spec is supported by one of the generic functions" {
            $Supported = @{}
            foreach ($Command in $Commands) {
                foreach ($Entry in Get-AutoTaskResourceOperation -CommandName $Command) { $Supported["$($Entry.Resource)|$($Entry.Operation)"] = $Command }
            }
            $Missing = @($Map | Where-Object { -not $Supported.ContainsKey("$($_.Resource)|$($_.Operation)") } | ForEach-Object { "$($_.Method) $($_.Path)" })
            $Missing | Should -BeNullOrEmpty
        }

        It "Get-AutoTaskResource only uses GET requests & the POST queries" {
            $Entries = @(Get-AutoTaskResourceOperation -CommandName Get-AutoTaskResource)
            @($Entries | Where-Object { $_.Method -notin 'GET', 'POST' }).Count | Should -Be 0
            @($Entries | Where-Object { $_.Method -eq 'POST' -and $_.Path -notmatch '/query(/count)?$' }).Count | Should -Be 0
        }

        It "Get-AutoTaskResource does not use the GET request that approves a time off request" {
            Get-AutoTaskResourceOperation -Resource TimeOffRequestsApproveChild -CommandName Get-AutoTaskResource | Where-Object { $_.Operation -eq 'CreateEntity' } | Should -BeNullOrEmpty
            (Get-AutoTaskResourceOperation -Resource TimeOffRequestsApproveChild -CommandName New-AutoTaskResource).Operation | Should -Contain 'CreateEntity'
        }

        It "The write functions only use their methods" {
            @(Get-AutoTaskResourceOperation -CommandName Set-AutoTaskResource | Where-Object { $_.Method -notin 'PATCH', 'PUT' }).Count | Should -Be 0
            @(Get-AutoTaskResourceOperation -CommandName Remove-AutoTaskResource | Where-Object { $_.Method -ne 'DELETE' }).Count | Should -Be 0
            @(Get-AutoTaskResourceOperation -CommandName New-AutoTaskResource | Where-Object { $_.Method -eq 'POST' -and $_.Operation -in 'Query', 'QueryCount' }).Count | Should -Be 0
        }

        It "Finds a resource regardless of the case" {
            @(Get-AutoTaskResourceOperation -Resource 'companies').Count | Should -Be @(Get-AutoTaskResourceOperation -Resource 'Companies').Count
            @(Get-AutoTaskResourceOperation -Resource 'Companies').Count | Should -BeGreaterThan 5
        }

        It "Returns nothing for an unknown resource" {
            Get-AutoTaskResourceOperation -Resource 'NotAResource' | Should -BeNullOrEmpty
        }

    }

    Context "[ Resolve-AutoTaskResource ]" {

        It "Resolves [ <Resource> <Operation> ] to [ <Method> <Uri> ]" -ForEach @(
            @{ Resource = 'Companies';                   Operation = 'QueryItem';             Values = @(5);       Method = 'GET';    Uri = '/V1.0/Companies/5' }
            @{ Resource = 'Companies';                   Operation = 'Query';                 Values = @();        Method = 'POST';   Uri = '/V1.0/Companies/query' }
            @{ Resource = 'Companies';                   Operation = 'UrlParameterQueryCount'; Values = @();       Method = 'GET';    Uri = '/V1.0/Companies/query/count' }
            @{ Resource = 'Companies';                   Operation = 'PatchEntity';           Values = @();        Method = 'PATCH';  Uri = '/V1.0/Companies' }
            @{ Resource = 'CompanyAlertsChild';          Operation = 'Query';                 Values = @(5);       Method = 'GET';    Uri = '/V1.0/Companies/5/Alerts' }
            @{ Resource = 'CompanyAlertsChild';          Operation = 'QueryItem';             Values = @(5, 7);    Method = 'GET';    Uri = '/V1.0/Companies/5/Alerts/7' }
            @{ Resource = 'CompanyToDosChild';           Operation = 'DeleteEntity';          Values = @(5, 7);    Method = 'DELETE'; Uri = '/V1.0/Companies/5/ToDos/7' }
            @{ Resource = 'AccountInvoiceSettings';      Operation = 'DeleteContactRecipient'; Values = @(5, 7);   Method = 'DELETE'; Uri = '/V1.0/Companies/5/invoiceSettings/contactRecipients/7' }
            @{ Resource = 'InvoiceMarkupApiIntegration'; Operation = 'QueryInvoicePdf';       Values = @(5);       Method = 'GET';    Uri = '/V1.0/Invoices/5/InvoicePdf' }
            @{ Resource = 'OrganizationalLevel1';        Operation = 'QueryItem';             Values = @(5);       Method = 'GET';    Uri = '/V1.0/OrganizationalLevel1s/5' }
            @{ Resource = 'ResourceTimeOffBalancesChild'; Operation = 'QueryItem';            Values = @(5, 2026); Method = 'GET';    Uri = '/V1.0/Resources/5/TimeOffBalances/2026' }
            @{ Resource = 'ZoneInformationApiIntegration'; Operation = 'QueryZoneInformation'; Values = @();       Method = 'GET';    Uri = '/V1.0/ZoneInformation' }
        ) {
            $Result = Resolve-AutoTaskResource -Resource $Resource -Operation $Operation -PathValue $Values
            $Result.Method | Should -Be $Method
            $Result.ResourceUri | Should -BeExactly $Uri
        }

        It "Resolves one operation of every operation name in the spec" {
            foreach ($Group in $Map | Group-Object -Property Operation, Method) {
                $Entry  = $Group.Group[0]
                $Count  = ([regex]::Matches($Entry.Path, '\{[^}]+\}')).Count
                $Values = @(1..([Math]::Max($Count, 1)) | Select-Object -First $Count)
                $Result = Resolve-AutoTaskResource -Resource $Entry.Resource -Operation $Entry.Operation -PathValue $Values
                $Result.Method | Should -Be $Entry.Method
                $Result.ResourceUri | Should -Not -Match '[{}]'
            }
        }

        It "Returns the canonical resource name" {
            (Resolve-AutoTaskResource -Resource 'companies' -Operation 'QueryItem' -PathValue 1).Resource | Should -BeExactly 'Companies'
        }

        It "Url encodes the path values" {
            (Resolve-AutoTaskResource -Resource 'Companies' -Operation 'QueryItem' -PathValue 'a/b').ResourceUri | Should -Be '/V1.0/Companies/a%2Fb'
        }

        It "Throws for an unknown resource" {
            { Resolve-AutoTaskResource -Resource 'NotAResource' -Operation 'QueryItem' } | Should -Throw '*not found*Show-AutoTaskResource*'
        }

        It "Throws for an operation that the resource does not have" {
            { Resolve-AutoTaskResource -Resource 'Companies' -Operation 'DeleteEntity' -PathValue 1 } | Should -Throw '*does not support*'
        }

        It "Throws for an operation that the command does not support" {
            { Resolve-AutoTaskResource -Resource 'Companies' -Operation 'PatchEntity' -CommandName Get-AutoTaskResource } | Should -Throw '*does not support*Get-AutoTaskResource*'
        }

        It "Throws when the number of ID values does not match the path" {
            { Resolve-AutoTaskResource -Resource 'CompanyAlertsChild' -Operation 'QueryItem' -PathValue 5 } | Should -Throw '*requires*2*'
            { Resolve-AutoTaskResource -Resource 'Companies' -Operation 'Query' -PathValue 5 } | Should -Throw '*requires*0*'
        }

    }

    Context "[ Complete-AutoTaskResource ]" {

        It "Completes the resources that the command supports" {
            $Names = @(Complete-AutoTaskResource -CommandName Remove-AutoTaskResource -ParameterName Resource -WordToComplete 'CompanyT' | ForEach-Object { $_.CompletionText })
            $Names | Should -Contain 'CompanyToDosChild'
            $Names | Should -Not -Contain 'CompanyTeams'
        }

        It "Completes every resource for other commands" {
            @(Complete-AutoTaskResource -CommandName Show-AutoTaskResource -ParameterName Name -WordToComplete '').Count | Should -Be @($Map.Resource | Select-Object -Unique).Count
        }

        It "Completes the operations of the typed resource" {
            $Names = @(Complete-AutoTaskResource -CommandName Get-AutoTaskResource -ParameterName Operation -WordToComplete '' -FakeBoundParameters @{ Resource = 'InvoiceMarkupApiIntegration' } | ForEach-Object { $_.CompletionText })
            $Names | Should -Be @('QueryInvoiceMarkupHtml', 'QueryInvoiceMarkupXml', 'QueryInvoicePdf')
        }

        It "Returns nothing for an operation without a resource" {
            Complete-AutoTaskResource -CommandName Get-AutoTaskResource -ParameterName Operation -WordToComplete '' | Should -BeNullOrEmpty
        }

        It "Is the argument completer of the [ <_> ] -Resource parameter" -ForEach 'Get-AutoTaskResource', 'New-AutoTaskResource', 'Set-AutoTaskResource', 'Remove-AutoTaskResource', 'New-AutoTaskBody' {
            $Completer = (Get-Command -Name $_).Parameters['Resource'].Attributes | Where-Object { $_ -is [System.Management.Automation.ArgumentCompleterAttribute] }
            "$($Completer.ScriptBlock)" | Should -Match 'Complete-AutoTaskResource'
        }

        It "Works with TabExpansion2" {
            $Result = TabExpansion2 -inputScript 'Get-AutoTaskResource -Resource CompanyAlertsCh' -cursorColumn ('Get-AutoTaskResource -Resource CompanyAlertsCh'.Length)
            $Result.CompletionMatches.CompletionText | Should -Contain 'CompanyAlertsChild'
        }

    }

}
