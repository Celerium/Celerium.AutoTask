function Complete-AutoTaskResource {
<#
    .SYNOPSIS
        Tab-completes AutoTask resource & operation names

    .DESCRIPTION
        The Complete-AutoTaskResource cmdlet is the argument completer of the -Resource
        & -Operation parameters of the public functions

        Only the resources & operations that the calling function supports are returned,
        such as the resources that can be deleted for Remove-AutoTaskResource

        The values come from the resource map that is created from the AutoTask OpenAPI spec

    .PARAMETER CommandName
        The name of the command that is being completed

    .PARAMETER ParameterName
        The name of the parameter that is being completed, Resource or Operation

    .PARAMETER WordToComplete
        The text that was typed so far

    .PARAMETER CommandAst
        The syntax tree of the command that is being completed

    .PARAMETER FakeBoundParameters
        The parameters that were already typed, used to find the resource when an operation is completed

    .EXAMPLE
        Complete-AutoTaskResource -CommandName Get-AutoTaskResource -ParameterName Resource -WordToComplete Compan

        Returns the resources that start with Compan & that Get-AutoTaskResource supports

    .EXAMPLE
        Complete-AutoTaskResource -CommandName Get-AutoTaskResource -ParameterName Operation -FakeBoundParameters @{ Resource = 'InvoiceMarkupApiIntegration' }

        Returns the operations of the InvoiceMarkupApiIntegration resource that Get-AutoTaskResource supports

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Complete-AutoTaskResource.html
#>

    [CmdletBinding()]
    [OutputType([System.Management.Automation.CompletionResult])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'CommandAst', Justification = 'Part of the argument completer signature')]
    Param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$CommandName,

        [Parameter(Mandatory = $false, Position = 1)]
        [string]$ParameterName,

        [Parameter(Mandatory = $false, Position = 2)]
        [AllowEmptyString()]
        [string]$WordToComplete = '',

        [Parameter(Mandatory = $false, Position = 3)]
        $CommandAst,

        [Parameter(Mandatory = $false, Position = 4)]
        [System.Collections.IDictionary]$FakeBoundParameters = @{}
    )

    begin {}

    process {

        $Supported = 'Get-AutoTaskResource', 'New-AutoTaskBody', 'New-AutoTaskResource', 'Set-AutoTaskResource', 'Remove-AutoTaskResource'
        $Filter = @{}
        if ($CommandName -in $Supported) { $Filter.CommandName = $CommandName }

        $Pattern = ($WordToComplete -replace "^['""]|['""]$", '') + '*'

        if ($ParameterName -eq 'Operation') {
            if (-not $FakeBoundParameters['Resource']) { return }
            $Filter.Resource = "$($FakeBoundParameters['Resource'])"
            $Names = Get-AutoTaskResourceOperation @Filter | ForEach-Object { $_.Operation }
        }
        else {
            $Names = Get-AutoTaskResourceOperation @Filter | ForEach-Object { $_.Resource }
        }

        $Names | Select-Object -Unique | Where-Object { $_ -like $Pattern } | Sort-Object | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }

    }

    end {}

}
