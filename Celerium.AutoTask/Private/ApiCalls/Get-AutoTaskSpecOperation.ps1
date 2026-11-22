function Get-AutoTaskSpecOperation {
<#
    .SYNOPSIS
        Gets every operation from an AutoTask OpenAPI (swagger) spec

    .DESCRIPTION
        The Get-AutoTaskSpecOperation cmdlet reads an AutoTask OpenAPI (swagger) spec
        and returns one object per operation (HTTP method & path)

        The resource is the tag of the operation, such as Companies or CompanyAlertsChild,
        and the operation is the part of the operationId after the resource name, such as
        Query, QueryItem, CreateEntity, PatchEntity, or DeleteEntity

        This function is used by the build\New-AutoTaskResourceMap.ps1 script to create
        the resource map of the module & by Show-AutoTaskResource -JsonSpec

    .PARAMETER JsonSpec
        Defines the path to the AutoTask OpenAPI (swagger) json file

    .PARAMETER Spec
        Defines an AutoTask OpenAPI (swagger) spec that was already converted from JSON

    .EXAMPLE
        Get-AutoTaskSpecOperation -JsonSpec .\Celerium.AutoTask\AutoTaskAPI-2023.6.json

        Returns every operation of the spec

    .EXAMPLE
        Get-AutoTaskSpecOperation -JsonSpec .\AutoTaskAPI-2023.6.json | Where-Object { $_.Resource -eq 'Companies' }

        Returns the operations of the Companies resource

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskSpecOperation.html
#>

    [CmdletBinding(DefaultParameterSetName = 'File')]
    [OutputType([PSCustomObject])]
    Param (
        [Parameter(Mandatory = $true, ParameterSetName = 'File')]
        [ValidateNotNullOrEmpty()]
        [string]$JsonSpec,

        [Parameter(Mandatory = $true, ParameterSetName = 'Object')]
        [ValidateNotNull()]
        [PSObject]$Spec
    )

    begin {}

    process {

        if ($PSCmdlet.ParameterSetName -eq 'File') {
            if (-not (Test-Path -Path $JsonSpec -PathType Leaf)) {
                throw "The OpenAPI spec was not found at [ $JsonSpec ]"
            }
            $Spec = [System.IO.File]::ReadAllText((Resolve-Path -Path $JsonSpec).ProviderPath, [System.Text.Encoding]::UTF8).TrimStart([char]0xFEFF) | ConvertFrom-Json
        }

        if (-not $Spec.paths) { throw 'The OpenAPI spec does not have any paths' }

        $Operations = foreach ($Path in $Spec.paths.PSObject.Properties) {
            foreach ($Method in 'get', 'post', 'put', 'patch', 'delete') {

                $Definition = $Path.Value.PSObject.Properties[$Method]
                if (-not $Definition) { continue }

                $Tag            = @($Definition.Value.tags)[0]
                $OperationId    = "$($Definition.Value.operationId)"

                # The operationId is <Tag>_<Operation>, such as Companies_QueryItem
                $Resource   = if ($Tag) { "$Tag" } else { ($OperationId -split '_', 2)[0] }
                $Operation  = if ($OperationId -like "$($Resource)_*") { $OperationId.Substring($Resource.Length + 1) }
                              elseif ($OperationId -match '_') { ($OperationId -split '_', 2)[1] }
                              else { $OperationId }

                [PSCustomObject]@{
                    Resource    = $Resource
                    Operation   = $Operation
                    Method      = $Method.ToUpperInvariant()
                    Path        = $Path.Name
                }

            }
        }

        # Ordinal sorting keeps the order identical on every platform & culture
        $Sorted = [System.Collections.Generic.List[object]]::new()
        $Sorted.AddRange(@($Operations))
        $Sorted.Sort([System.Comparison[object]]{
            param ($Left, $Right)
            $Result = [string]::CompareOrdinal($Left.Resource, $Right.Resource)
            if ($Result -eq 0) { $Result = [string]::CompareOrdinal($Left.Operation, $Right.Operation) }
            if ($Result -eq 0) { $Result = [string]::CompareOrdinal($Left.Method, $Right.Method) }
            return $Result
        })

        $Sorted

    }

    end {}

}
