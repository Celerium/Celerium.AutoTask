function Resolve-AutoTaskResource {
<#
    .SYNOPSIS
        Resolves an AutoTask resource & operation to a request uri

    .DESCRIPTION
        The Resolve-AutoTaskResource cmdlet finds an operation of a resource in the resource map
        and replaces the placeholders of its path, such as {parentId} & {id}, with the provided values

        An error is thrown when the resource or the operation does not exist, when the public function
        does not support the operation, or when the number of values does not match the placeholders

    .PARAMETER Resource
        Defines the name of the resource, such as Companies or CompanyAlertsChild

        The name is not case sensitive

    .PARAMETER Operation
        Defines the name of the operation, such as Query, QueryItem, CreateEntity, PatchEntity, or DeleteEntity

        Show-AutoTaskResource lists the operations of every resource

    .PARAMETER CommandName
        Defines the public function that makes the request, only the operations that the
        function supports are allowed

    .PARAMETER PathValue
        Defines the values of the path placeholders in the order that they appear in the path

        For a child resource the first value is the parent ID & the second value is the child ID

    .EXAMPLE
        Resolve-AutoTaskResource -Resource Companies -Operation QueryItem -PathValue 12345

        Returns the GET method & the /V1.0/Companies/12345 resource uri

    .EXAMPLE
        Resolve-AutoTaskResource -Resource CompanyAlertsChild -Operation QueryItem -PathValue 12345, 67

        Returns the GET method & the /V1.0/Companies/12345/Alerts/67 resource uri

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Resolve-AutoTaskResource.html
#>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Resource,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Operation,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Get-AutoTaskResource', 'New-AutoTaskBody', 'New-AutoTaskResource', 'Set-AutoTaskResource', 'Remove-AutoTaskResource')]
        [string]$CommandName,

        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [object[]]$PathValue = @()
    )

    begin {}

    process {

        $ResourceOperations = @(Get-AutoTaskResourceOperation -Resource $Resource)
        if ($ResourceOperations.Count -eq 0) {
            throw "The [ $Resource ] resource was not found. Run Show-AutoTaskResource to list the available resources"
        }

        $Supported = if ($CommandName) { @(Get-AutoTaskResourceOperation -Resource $Resource -CommandName $CommandName) } else { $ResourceOperations }

        $Entry = $Supported | Where-Object { $_.Operation -eq $Operation } | Select-Object -First 1
        if (-not $Entry) {
            $Names  = @($Supported | ForEach-Object { $_.Operation } | Select-Object -Unique)
            $Using  = if ($CommandName) { " with $CommandName" } else { '' }
            $List   = if ($Names.Count) { $Names -join ', ' } else { 'none' }
            throw "The [ $($ResourceOperations[0].Resource) ] resource does not support the [ $Operation ] operation$Using. Supported operations: $List"
        }

        $Placeholders = @([regex]::Matches($Entry.Path, '\{[^}]+\}') | ForEach-Object { $_.Value })
        $Values       = @($PathValue | Where-Object { $null -ne $_ -and "$_" -ne '' })

        if ($Values.Count -ne $Placeholders.Count) {
            throw "The [ $($Entry.Operation) ] operation of the [ $($Entry.Resource) ] resource ( $($Entry.Path) ) requires [ $($Placeholders.Count) ] ID value(s) $(if ($Placeholders.Count) { "for $($Placeholders -join ', ') " })but [ $($Values.Count) ] were provided"
        }

        $ResourceUri = $Entry.Path
        for ($Index = 0; $Index -lt $Placeholders.Count; $Index++) {
            $Position       = $ResourceUri.IndexOf($Placeholders[$Index])
            $ResourceUri    = $ResourceUri.Substring(0, $Position) + [System.Uri]::EscapeDataString("$($Values[$Index])") + $ResourceUri.Substring($Position + $Placeholders[$Index].Length)
        }

        [PSCustomObject]@{
            Resource        = $Entry.Resource
            Operation       = $Entry.Operation
            Method          = $Entry.Method
            Path            = $Entry.Path
            ResourceUri     = $ResourceUri
            Placeholders    = $Placeholders
        }

    }

    end {}

}
