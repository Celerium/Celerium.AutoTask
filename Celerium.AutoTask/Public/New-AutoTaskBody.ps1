function New-AutoTaskBody {
<#
    .SYNOPSIS
        Creates a new resource body object

    .DESCRIPTION
        The New-AutoTaskBody cmdlet creates a new resource body
        for the AutoTask API

        Helpful when working with resource queries, modifications,
        and creating filters for advanced searches

    .PARAMETER Empty
        Creates a new resource body with no content

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

    [CmdletBinding(DefaultParameterSetName = 'Empty', SupportsShouldProcess = $true, ConfirmImpact = 'None')]
    Param(
        [Parameter(Mandatory = $false, ParameterSetName = 'Empty')]
        [switch]$Empty
    )

    DynamicParam {
        $AutoTaskModulePostPatchParameter
    }

    begin {

        $FunctionName   = $MyInvocation.InvocationName
        $ResourceTarget = $PSBoundParameters.Resource

    }
    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $ResourceURI = ($AutoTaskModuleQueries | Where-Object { $_.Post -eq $ResourceTarget } | Select-Object -First 1).Name -replace '/query$', ''
        if (-not $ResourceURI) {
            $ResourceURI = ($AutoTaskModuleQueries | Where-Object { $_.Patch -eq $ResourceTarget } | Select-Object -First 1).Name -replace '/query$', ''
        }

        $TargetURI = "$ResourceURI/entityInformation"
        try {


            $ObjectTemplate = (Invoke-AutoTaskRequest -Method GET -ResourceURI "$TargetURI/fields").fields
            try {
                $UDFs = (Invoke-AutoTaskRequest -Method GET -ResourceURI "$TargetURI/userDefinedFields").fields | Select-Object Name,Value
            }
            catch {
                if ( $_.Exception.Response.StatusCode -ne "NotFound" ) { throw }
            }

            if (-not $ObjectTemplate) { Write-Warning "Could not retrieve entityInformation for [ $ResourceTarget ]" }
            else {

                $OutputResults  = [System.Collections.Generic.List[object]]::new()
                $Properties     = [ordered]@{}

                if ($Empty) {
                    foreach ($Property in $ObjectTemplate | Where-Object { -not $_.IsReadOnly }) {
                        $Properties[$Property.Name] = $null
                    }
                    $OutputResults.Add([PSCustomObject]$Properties)
                }
                else {
                    foreach ($Property in $ObjectTemplate) {
                        $FieldMetadata = [PSCustomObject]@{
                            Name           = $Property.Name
                            DataType       = $Property.DataType
                            Length         = $Property.Length
                            IsReadOnly     = $Property.IsReadOnly
                            IsRequired     = $Property.IsRequired
                            PickListValues = if ($Property.PickListValues) {
                                $Property.PickListValues | Select-Object Label,Value,IsActive
                            } else { $null }
                        }
                        $OutputResults.Add($FieldMetadata)
                    }

                    if ($UDFs) {
                        $UDFMetadata = [PSCustomObject]@{
                            Name           = "userDefinedFields"
                            DataType       = "object[]"
                            IsReadOnly     = $false
                            IsRequired     = $false
                            PickListValues = $UDFs
                        }
                        $OutputResults.Add($UDFMetadata)
                    }
                }

            }

            if ($PSCmdlet.ShouldProcess($TargetURI)) {
                return $OutputResults
            }

        }
        catch {
            Write-Error $_
        }

    }
}