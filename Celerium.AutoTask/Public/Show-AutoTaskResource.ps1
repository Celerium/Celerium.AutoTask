function Show-AutoTaskResource {
<#
    .SYNOPSIS
        Shows the available resources & operations of the AutoTask API

    .DESCRIPTION
        The Show-AutoTaskResource cmdlet shows the resources & operations that can be
        used with the -Resource & -Operation parameters of the public functions

        By default all available values are shown. The values come from the resource map
        that is created from the AutoTask OpenAPI spec when the module is built

        GET     -> Get-AutoTaskResource (POST Query & QueryCount operations as well)
        POST    -> New-AutoTaskResource
        PATCH   -> Set-AutoTaskResource (PUT operations as well)
        DELETE  -> Remove-AutoTaskResource

    .PARAMETER Name
        Defines the name of the resource to limit the output to

        This is a wildcard search and will return all resources
        that start with the provided value

    .PARAMETER Method
        Defines the type of API method to show available values for

        Allowed values:
        'GET', 'PUT', 'POST', 'PATCH', 'DELETE'

    .PARAMETER UniqueOnly
        Returns only unique resource names

    .PARAMETER JsonSpec
        Defines the path to an AutoTask OpenAPI (swagger) json file to read the
        resources from instead of the resource map of the module

    .EXAMPLE
        Show-AutoTaskResource

        Show all available resources & operations

    .EXAMPLE
        Show-AutoTaskResource -Name Companies

        Shows available values on the Companies* resources

    .EXAMPLE
        Show-AutoTaskResource -Name Companies -Method GET

        Shows available values for the GET method on the Companies* resource

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Resource/Show-AutoTaskResource.html
#>

    [CmdletBinding(DefaultParameterSetName = 'All')]
    Param(
        [Parameter(Mandatory = $false, Position = 0)]
        [ArgumentCompleter({ Complete-AutoTaskResource @args })]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet('GET', 'PUT', 'POST', 'PATCH', 'DELETE')]
        [string]$Method,

        [Parameter(Mandatory = $false, ParameterSetName = 'UniqueOnly')]
        [switch]$UniqueOnly,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$JsonSpec
    )

    begin {

        $FunctionName   = $MyInvocation.MyCommand.Name
        $ParameterName  = $FunctionName + '_Parameters' -replace '-','_'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $Operations = if ($JsonSpec) { Get-AutoTaskSpecOperation -JsonSpec $JsonSpec } else { Get-AutoTaskResourceMap }

        $ResourceList = foreach ($Entry in $Operations) {
            [PSCustomObject]@{
                Method      = $Entry.Method
                Resource    = $Entry.Resource
                Operation   = $Entry.Operation
                Path        = $Entry.Path
                Index       = ($Entry.Path -split '/')[2]
            }
        }

        $ResourceList = $ResourceList | Sort-Object Resource, Method, Path

        if ($Name)      { $ResourceList = $ResourceList | Where-Object { $_.Resource -like "$Name*" } }
        if ($Method)    { $ResourceList = $ResourceList | Where-Object { $_.Method -eq $Method } }
        if ($UniqueOnly){ $ResourceList = $ResourceList | Select-Object -Property Resource -Unique }

        Set-Variable -Name $ParameterName -Value $PSBoundParameters -Scope Global -Force -Confirm:$false

        $ResourceList

    }

    end {}

}
