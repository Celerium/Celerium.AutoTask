function Set-AutoTaskResource {
<#
    .SYNOPSIS
        Updates a resource

    .DESCRIPTION
        The Set-AutoTaskResource cmdlet updates a resource
        in the AutoTask API

    .PARAMETER ParentID
        The ID of the parent resource to update

    .PARAMETER ID
        The ID of the resource to update

    .PARAMETER Data
        The data body to use when updating the resource

    .EXAMPLE
        Set-AutoTaskResource -Resource Companies -ID 123 -Data $data

        Updates the company resource with the specified ID

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Public/Set-AutoTaskResource.html
#>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    Param(
        [Parameter(ParameterSetName = 'ParentID', Mandatory = $false)]
        [int64]$ParentId,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [int64]$ID,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        $Data
    )

    DynamicParam {
        $AutoTaskModulePatchParameter
    }

    begin {

        $FunctionName   = $MyInvocation.InvocationName
        $ParameterName  = $functionName + '_Parameters'      -replace '-','_'

        $ResourceTarget = $PSBoundParameters.Resource
        $ResourceUri    = ($AutoTaskModuleQueries | Where-Object { $_.Patch -eq $ResourceTarget } | Select-Object -First 1).Name -replace '/query$', ''


    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        if ($ResourceTarget -like "*child*") {
            if (-not $ParentId) {
                Write-Warning "You must specify a parentId when setting a child resource"
                break
            }
            $ResourceUri = $ResourceUri -replace '{parentId}', $ParentId
        }

        $InvokeParams = @{
            Method      = 'PATCH'
            ResourceURI = $ResourceUri
            Data        = $Data
        }

        Set-Variable -Name $ParameterName -Value $InvokeParams -Scope Global -Force -Confirm:$false

        if ($PSCmdlet.ShouldProcess($ResourceUri)) {
            return Invoke-AutoTaskRequest @InvokeParams
        }

    }
}