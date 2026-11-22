function Get-AutoTaskResourceOperation {
<#
    .SYNOPSIS
        Gets the operations of an AutoTask resource

    .DESCRIPTION
        The Get-AutoTaskResourceOperation cmdlet returns the operations from the resource map
        and can limit them to one resource and to the operations that a public function supports

        Every operation of the AutoTask API is supported by one of the public functions:

            Get-AutoTaskResource    - GET operations & the POST query & count operations
            New-AutoTaskBody        - The QueryFieldDefinitions operation
            New-AutoTaskResource    - The CreateEntity operation & the other POST operations
            Set-AutoTaskResource    - The PATCH & PUT operations
            Remove-AutoTaskResource - The DELETE operations

    .PARAMETER Resource
        Defines the name of the resource to return the operations of, such as Companies

        The name is not case sensitive

    .PARAMETER CommandName
        Defines the public function to return the supported operations of

        Allowed values:
            'Get-AutoTaskResource', 'New-AutoTaskBody', 'New-AutoTaskResource',
            'Set-AutoTaskResource', 'Remove-AutoTaskResource'

    .EXAMPLE
        Get-AutoTaskResourceOperation -Resource Companies

        Returns every operation of the Companies resource

    .EXAMPLE
        Get-AutoTaskResourceOperation -CommandName Remove-AutoTaskResource

        Returns every operation that the Remove-AutoTaskResource function supports

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskResourceOperation.html
#>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    Param (
        [Parameter(Mandatory = $false)]
        [string]$Resource,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Get-AutoTaskResource', 'New-AutoTaskBody', 'New-AutoTaskResource', 'Set-AutoTaskResource', 'Remove-AutoTaskResource')]
        [string]$CommandName
    )

    begin {}

    process {

        $Operations = Get-AutoTaskResourceMap

        if ($Resource) {

            # A case insensitive lookup by resource name is created once per session
            if (-not $script:AutoTaskModuleResourceIndex) {
                $Index = @{}
                foreach ($Entry in $Operations) {
                    if (-not $Index.ContainsKey($Entry.Resource)) { $Index[$Entry.Resource] = [System.Collections.Generic.List[object]]::new() }
                    $Index[$Entry.Resource].Add($Entry)
                }
                $script:AutoTaskModuleResourceIndex = $Index
            }

            $Operations = if ($script:AutoTaskModuleResourceIndex.ContainsKey($Resource)) { $script:AutoTaskModuleResourceIndex[$Resource].ToArray() } else { @() }

        }

        switch ($CommandName) {
            'Get-AutoTaskResource'      { $Operations = $Operations | Where-Object { ($_.Method -eq 'GET' -and $_.Operation -ne 'CreateEntity') -or ($_.Method -eq 'POST' -and $_.Operation -in 'Query', 'QueryCount') } }
            'New-AutoTaskBody'          { $Operations = $Operations | Where-Object { $_.Operation -eq 'QueryFieldDefinitions' } }
            'New-AutoTaskResource'      { $Operations = $Operations | Where-Object { $_.Operation -eq 'CreateEntity' -or ($_.Method -eq 'POST' -and $_.Operation -notin 'Query', 'QueryCount') } }
            'Set-AutoTaskResource'      { $Operations = $Operations | Where-Object { $_.Method -in 'PATCH', 'PUT' } }
            'Remove-AutoTaskResource'   { $Operations = $Operations | Where-Object { $_.Method -eq 'DELETE' } }
        }

        $Operations

    }

    end {}

}
