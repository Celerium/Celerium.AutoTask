function Remove-AutoTaskResource {
<#
    .SYNOPSIS
        Deletes a resource

    .DESCRIPTION
        The Remove-AutoTaskResource cmdlet deletes a resource
        in the AutoTask API

    .PARAMETER ID
        The ID of the resource to delete

    .PARAMETER ChildID
        The ID of the child resource to delete

    .EXAMPLE
        Remove-AutoTaskResource -Resource Companies -ID 123

        Deletes the company resource with the specified ID

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Resource/Remove-AutoTaskResource.html
#>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [int64]$ID,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [int64]$ChildID
    )

    DynamicParam {
        $AutoTaskModuleDeleteParameter
    }

    begin {

        $FunctionName   = $MyInvocation.InvocationName
        $ParameterName  = $functionName + '_Parameters'      -replace '-','_'

        $ResourceTarget = $PSBoundParameters.Resource
        #$ResourceUri    = (($AutoTaskModuleQueries | Where-Object { $_.Delete -eq $ResourceTarget }).Name | Select-Object -First 1) -replace '/query', '/{PARENTID}' | Select-Object -First 1
        $ResourceUri    = ($AutoTaskModuleQueries | Where-Object { $_.Delete -eq $ResourceTarget } | Select-Object -First 1).Name -replace '/query$', '/{PARENTID}'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        if (-not $ChildID -and $ResourceTarget -like "*Child*") {
            Write-Warning "You must enter a ChildID to delete a Child resource"
            break
        }

        $ResourceUri = $ResourceUri -replace '{PARENTID}', $ID

        if ($ID)        { $ResourceUri = $ResourceUri -replace '{ID}', $ID }
        if ($ChildID)   { $ResourceUri = $ResourceUri -replace '{ID}', $ChildID }

        $InvokeParams = @{
            Method      = 'DELETE'
            ResourceURI = $ResourceUri
        }

        Set-Variable -Name $ParameterName -Value $InvokeParams -Scope Global -Force -Confirm:$false

        if ($PSCmdlet.ShouldProcess($ResourceUri)) {
            return Invoke-AutoTaskRequest @InvokeParams
        }


    }
}