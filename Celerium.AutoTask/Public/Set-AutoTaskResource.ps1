function Set-AutoTaskResource {
<#
    .SYNOPSIS
        Updates a resource

    .DESCRIPTION
        The Set-AutoTaskResource cmdlet updates a resource
        in the AutoTask API

        By default a PATCH request is sent, which only changes the fields in the data body

        This is a write request, it supports -WhatIf & asks for confirmation before the
        request is sent (use -Confirm:$false to skip the confirmation). Write requests are never retried

    .PARAMETER Resource
        Defines the name of the resource to update, such as Companies or CompanyNotesChild

        Run Show-AutoTaskResource -Method PATCH to list the resources

    .PARAMETER ParentId
        The ID of the parent resource when updating a child resource

    .PARAMETER ID
        The ID of the resource to update

        The ID is added to the data body as the id field, AutoTask finds the item to update by this field

    .PARAMETER Data
        The data body to use when updating the resource

    .PARAMETER Operation
        Defines the operation of the resource to use, such as UpdateEntity (PUT) which replaces the item

        By default the PatchEntity operation is used, Show-AutoTaskResource lists the operations

    .EXAMPLE
        Set-AutoTaskResource -Resource Companies -ID 123 -Data @{ phone = '555-555-5555' }

        Updates the phone number of the company with ID 123 after asking for confirmation

    .EXAMPLE
        Get-AutoTaskResource -Resource Companies -ID 123 | Set-AutoTaskResource -Resource Companies -WhatIf

        Shows the update request of the company that was piped in without sending the request

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Resource/Set-AutoTaskResource.html
#>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ArgumentCompleter({ Complete-AutoTaskResource @args })]
        [ValidateNotNullOrEmpty()]
        [string]$Resource,

        [Parameter(Mandatory = $false)]
        [int64]$ParentId,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [int64]$ID,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        $Data,

        [Parameter(Mandatory = $false)]
        [ArgumentCompleter({ Complete-AutoTaskResource @args })]
        [string]$Operation = 'PatchEntity'
    )

    begin {

        $FunctionName   = $MyInvocation.MyCommand.Name
        $ParameterName  = $FunctionName + '_Parameters' -replace '-','_'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $PathValue = if ($PSBoundParameters.ContainsKey('ParentId')) { @($ParentId) } else { @() }

        try { $Target = Resolve-AutoTaskResource -Resource $Resource -Operation $Operation -CommandName $FunctionName -PathValue $PathValue }
        catch {
            if ($_.Exception.Message -like '*requires*') { throw "$($_.Exception.Message). Use -ParentId with the ID of the parent resource" }
            throw
        }

        $Body = $Data
        if ($PSBoundParameters.ContainsKey('ID')) {

            # A copy of the data is changed so that the object of the caller is not modified
            if ($Data -is [string]) { $Data = $Data | ConvertFrom-Json }

            $Copy = [ordered]@{}
            if ($Data -is [System.Collections.IDictionary]) { foreach ($Key in $Data.Keys) { $Copy["$Key"] = $Data[$Key] } }
            else { foreach ($Property in $Data.PSObject.Properties) { $Copy[$Property.Name] = $Property.Value } }

            $IdKey = @($Copy.Keys | Where-Object { $_ -eq 'id' })[0]
            if ($IdKey) { $Copy[$IdKey] = $ID } else { $Copy['id'] = $ID }

            $Body = [PSCustomObject]$Copy

        }

        $InvokeParams = @{
            Method          = $Target.Method
            ResourceURI     = $Target.ResourceUri
            Data            = $Body
            WriteRequest    = $true
        }

        Set-Variable -Name $ParameterName -Value $InvokeParams -Scope Global -Force -Confirm:$false

        $Description = if ($PSBoundParameters.ContainsKey('ID')) { "$($Target.Resource) ID [ $ID ] [ $($Target.Method) $($Target.ResourceUri) ]" } else { "$($Target.Resource) [ $($Target.Method) $($Target.ResourceUri) ]" }

        if ($PSCmdlet.ShouldProcess($Description, 'Update')) {
            Invoke-AutoTaskRequest @InvokeParams
        }

    }

    end {}

}
