function New-AutoTaskBody {
<#
    .SYNOPSIS
        Creates a new resource body object

    .DESCRIPTION
        The New-AutoTaskBody cmdlet creates a new resource body
        for the AutoTask API

        Helpful when working with resource queries, modifications,
        and creating filters for advanced searches

        The field definitions are read with two GET requests (fields & user defined fields),
        no data is changed in AutoTask

    .PARAMETER Resource
        Defines the name of the resource to create a body for, such as Companies or CompanyNotesChild

    .PARAMETER Empty
        Creates a new resource body with no content

        Only the fields that are not read-only are included

    .PARAMETER ParentId
        The parent resource ID used to read the field definitions of a child resource

        Default value: 0

    .EXAMPLE
        New-AutoTaskBody -Resource ContactGroups

        Creates a template showing all available fields with their types and picklist values

    .EXAMPLE
        New-AutoTaskBody -Resource Companies -Empty

        Creates a new resource body for the company with no content

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Resource/New-AutoTaskBody.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Template', SupportsShouldProcess = $true, ConfirmImpact = 'None')]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ArgumentCompleter({ Complete-AutoTaskResource @args })]
        [ValidateNotNullOrEmpty()]
        [string]$Resource,

        [Parameter(Mandatory = $false)]
        [switch]$Empty,

        [Parameter(Mandatory = $false)]
        [int64]$ParentId = 0
    )

    begin {

        $FunctionName = $MyInvocation.MyCommand.Name

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $FieldsEntry = Get-AutoTaskResourceOperation -Resource $Resource -CommandName $FunctionName | Select-Object -First 1
        if (-not $FieldsEntry) { throw "The [ $Resource ] resource does not have field definitions. Run Show-AutoTaskResource to list the available resources" }

        $PathValue  = @([regex]::Matches($FieldsEntry.Path, '\{[^}]+\}') | ForEach-Object { $ParentId })
        $Fields     = Resolve-AutoTaskResource -Resource $Resource -Operation 'QueryFieldDefinitions' -CommandName $FunctionName -PathValue $PathValue
        $HasUdf     = [bool](Get-AutoTaskResourceOperation -Resource $Resource | Where-Object { $_.Operation -eq 'QueryUserDefinedFieldDefinitions' })

        if (-not $PSCmdlet.ShouldProcess($Fields.ResourceUri, 'Read the field definitions')) { return }

        $ObjectTemplate = (Invoke-AutoTaskRequest -Method GET -ResourceURI $Fields.ResourceUri).fields

        $UDFs = $null
        if ($HasUdf -and -not $Empty) {
            $UdfTarget  = Resolve-AutoTaskResource -Resource $Resource -Operation 'QueryUserDefinedFieldDefinitions' -PathValue $PathValue
            $UDFs       = (Invoke-AutoTaskRequest -Method GET -ResourceURI $UdfTarget.ResourceUri).fields | Select-Object Name, Value
        }

        if (-not $ObjectTemplate) {
            Write-Warning "Could not retrieve the field definitions of [ $Resource ]"
            return
        }

        if ($Empty) {
            $Properties = [ordered]@{}
            foreach ($Property in $ObjectTemplate | Where-Object { -not $_.IsReadOnly }) {
                $Properties[$Property.Name] = $null
            }
            return [PSCustomObject]$Properties
        }

        foreach ($Property in $ObjectTemplate) {
            [PSCustomObject]@{
                Name           = $Property.Name
                DataType       = $Property.DataType
                Length         = $Property.Length
                IsReadOnly     = $Property.IsReadOnly
                IsRequired     = $Property.IsRequired
                PickListValues = if ($Property.PickListValues) { $Property.PickListValues | Select-Object Label, Value, IsActive } else { $null }
            }
        }

        if ($UDFs) {
            [PSCustomObject]@{
                Name           = 'userDefinedFields'
                DataType       = 'object[]'
                Length         = $null
                IsReadOnly     = $false
                IsRequired     = $false
                PickListValues = $UDFs
            }
        }

    }

    end {}

}
