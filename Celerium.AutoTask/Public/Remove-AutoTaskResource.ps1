function Remove-AutoTaskResource {
<#
    .SYNOPSIS
        Deletes a resource

    .DESCRIPTION
        The Remove-AutoTaskResource cmdlet deletes a resource
        in the AutoTask API

        For a child resource, such as CompanyNotesChild, the -ID parameter is the ID of the
        parent resource & the -ChildID parameter is the ID of the child resource to delete

        This is a write request, it supports -WhatIf & asks for confirmation before the
        request is sent (use -Confirm:$false to skip the confirmation). Write requests are never retried

    .PARAMETER Resource
        Defines the name of the resource to delete, such as Companies or CompanyNotesChild

        Run Show-AutoTaskResource -Method DELETE to list the resources

    .PARAMETER ID
        The ID of the resource to delete

        For a child resource this is the ID of the parent resource

    .PARAMETER ChildID
        The ID of the child resource to delete

    .PARAMETER Operation
        Defines the operation of the resource to use, such as DeleteContactRecipient

        By default the DeleteEntity operation is used, Show-AutoTaskResource lists the operations

    .EXAMPLE
        Remove-AutoTaskResource -Resource ActionTypes -ID 123

        Deletes the action type with the specified ID after asking for confirmation

    .EXAMPLE
        Remove-AutoTaskResource -Resource CompanyToDosChild -ID 8765309 -ChildID 123 -WhatIf

        Shows the delete request of the to-do with ID 123 of the company with ID 8765309 without sending the request

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Resource/Remove-AutoTaskResource.html
#>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ArgumentCompleter({ Complete-AutoTaskResource @args })]
        [ValidateNotNullOrEmpty()]
        [string]$Resource,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [int64]$ID,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [int64]$ChildID,

        [Parameter(Mandatory = $false)]
        [ArgumentCompleter({ Complete-AutoTaskResource @args })]
        [string]$Operation = 'DeleteEntity'
    )

    begin {

        $FunctionName   = $MyInvocation.MyCommand.Name
        $ParameterName  = $FunctionName + '_Parameters' -replace '-','_'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $PathValue = @($ID)
        if ($PSBoundParameters.ContainsKey('ChildID')) { $PathValue += $ChildID }

        try { $Target = Resolve-AutoTaskResource -Resource $Resource -Operation $Operation -CommandName $FunctionName -PathValue $PathValue }
        catch {
            if ($_.Exception.Message -like '*requires*') { throw "$($_.Exception.Message). A child resource needs -ID (parent ID) & -ChildID" }
            throw
        }

        $InvokeParams = @{
            Method          = $Target.Method
            ResourceURI     = $Target.ResourceUri
            WriteRequest    = $true
        }

        Set-Variable -Name $ParameterName -Value $InvokeParams -Scope Global -Force -Confirm:$false

        if ($PSCmdlet.ShouldProcess("$($Target.Resource) [ $($Target.Method) $($Target.ResourceUri) ]", 'Delete')) {
            Invoke-AutoTaskRequest @InvokeParams
        }

    }

    end {}

}
