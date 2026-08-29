function Show-AutoTaskResource {
<#
    .SYNOPSIS
        Shows available values from the dynamically generated
        resource parameter

    .DESCRIPTION
        The Show-AutoTaskResource cmdlet shows available values
        from the dynamically generated resource parameter

        By default all available values are show

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
        Defines the path to the swagger json file to use when creating
        the dynamic parameter

    .EXAMPLE
        Show-AutoTaskResource

        Show all available values from the dynamically generated resource parameter

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

    [CmdletBinding(defaultParameterSetName = 'All')]
    Param(
        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet('GET', 'PUT', 'POST', 'PATCH', 'DELETE')]
        [String]$Method,

        [Parameter(Mandatory = $false, ParameterSetName = 'UniqueOnly')]
        [switch]$UniqueOnly,

        [Parameter(Mandatory = $false)]
        [string]$JsonSpec = $(Join-Path -Path "$($MyInvocation.MyCommand.Module.ModuleBase)" -ChildPath "AutoTaskAPI-2023.6.json")
    )


    begin {

        $FunctionName       = $MyInvocation.InvocationName
        $ParameterName      = $functionName + '_Parameters'      -replace '-','_'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        if (-not $AutoTaskModuleSwagger) {
            $Swagger = Get-Content $JsonSpec -Raw | ConvertFrom-Json

            $Queries = foreach ($Path in $Swagger.Paths.PSObject.Properties) {
                [PSCustomObject]@{
                    Index  = $Path.Name.Split('/')[2]
                    Name   = $Path.Name
                    GET    = $Path.Value.GET.Tags
                    PUT    = $Path.Value.PUT.Tags
                    POST   = $Path.Value.POST.Tags
                    PATCH  = $Path.Value.PATCH.Tags
                    DELETE = $Path.Value.DELETE.Tags
                }
            }
        }
        else {
            $Queries = $AutoTaskModuleQueries
        }

        $ResourceList = foreach ($Type in 'GET','PUT','POST','PATCH','DELETE') {
            foreach ($Query in $Queries | Where-Object { $null -ne $_.$Type }) {
                [PSCustomObject]@{
                    Method   = $Type
                    Resource = $Query.$Type | Select-Object -Last 1
                    Path     = $Query.Name
                    Index    = $Query.Index
                }
            }
        }

        $ResourceList = $ResourceList | Sort-Object Resource,Method,Path

        if ($Name)      { $ResourceList = $ResourceList | Where-Object Resource -like "$Name*"}
        if ($Method)    { $ResourceList = $ResourceList | Where-Object Method -eq $Method }
        if ($UniqueOnly){ $ResourceList = $ResourceList | Select-Object -Property Resource -Unique }

        Set-Variable -Name $ParameterName -Value $PSBoundParameters -Scope Global -Force -Confirm:$false

        return $ResourceList

    }

}