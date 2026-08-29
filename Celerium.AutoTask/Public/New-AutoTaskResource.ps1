function New-AutoTaskResource {
<#
    .SYNOPSIS
        Creates a new resource

    .DESCRIPTION
        The New-AutoTaskResource cmdlet creates a new resource
        in the AutoTask API

    .PARAMETER ParentId
        The parent resource ID to use when creating a child resource

    .PARAMETER Data
        The data body to use when creating the resource

    .EXAMPLE
        New-AutoTaskResource -Resource Companies -Data $data

        Creates a new resource for the company with the specified data body

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Resource/New-AutoTaskResource.html
#>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    Param(
        [Parameter(Mandatory = $false)]
        [String]$ParentId,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        $Data
    )

    DynamicParam {
        $AutoTaskModulePostParameter
    }

    begin {

        $FunctionName   = $MyInvocation.InvocationName
        $ParameterName  = $FunctionName + '_Parameters' -replace '-','_'

        $ResourceTarget = $PSBoundParameters.Resource
        $ResourceUri    = ($AutoTaskModuleQueries | Where-Object { $_.Post -eq $ResourceTarget } | Select-Object -First 1).Name -replace '/query$', ''

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        if ($ResourceTarget -like "*child*") {
            if (-not $ParentId ) {
                Write-Error "You must specify a parentId when creating a child resource"
                break
            }
            $ResourceUri = $ResourceUri -replace '{parentId}', $ParentId
        }

        $InvokeParams = @{
            Method      = 'POST'
            ResourceURI = $ResourceUri
            Data        = $Data
        }

        Set-Variable -Name $ParameterName -Value $InvokeParams -Scope Global -Force -Confirm:$false

        if ($PSCmdlet.ShouldProcess($ResourceUri)) {
            return Invoke-AutoTaskRequest @InvokeParams
        }

    }
}