function New-AutoTaskResource {
<#
    .SYNOPSIS
        Creates a new resource

    .DESCRIPTION
        The New-AutoTaskResource cmdlet creates a new resource
        in the AutoTask API

        This is a write request, it supports -WhatIf & asks for confirmation before the
        request is sent (use -Confirm:$false to skip the confirmation). Write requests are never retried

    .PARAMETER Resource
        Defines the name of the resource to create, such as Companies or CompanyNotesChild

        Run Show-AutoTaskResource -Method POST to list the resources

    .PARAMETER ParentId
        The parent resource ID to use when creating a child resource

    .PARAMETER Data
        The data body to use when creating the resource

        New-AutoTaskBody -Empty creates an object with every field of a resource

    .PARAMETER Operation
        Defines the operation of the resource to use, such as AddContactRecipients

        By default the CreateEntity operation is used, Show-AutoTaskResource lists the operations

    .EXAMPLE
        New-AutoTaskResource -Resource Companies -Data $Data

        Creates a new company with the specified data body after asking for confirmation

    .EXAMPLE
        New-AutoTaskResource -Resource CompanyNotesChild -ParentId 8765309 -Data $Data -WhatIf

        Shows the note that would be created for the company with ID 8765309 without sending the request

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Resource/New-AutoTaskResource.html
#>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ArgumentCompleter({ Complete-AutoTaskResource @args })]
        [ValidateNotNullOrEmpty()]
        [string]$Resource,

        [Parameter(Mandatory = $false)]
        [int64]$ParentId,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        $Data,

        [Parameter(Mandatory = $false)]
        [ArgumentCompleter({ Complete-AutoTaskResource @args })]
        [string]$Operation = 'CreateEntity'
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

        $InvokeParams = @{
            Method          = $Target.Method
            ResourceURI     = $Target.ResourceUri
            Data            = $Data
            WriteRequest    = $true
        }

        Set-Variable -Name $ParameterName -Value $InvokeParams -Scope Global -Force -Confirm:$false

        if ($PSCmdlet.ShouldProcess("$($Target.Resource) [ $($Target.Method) $($Target.ResourceUri) ]", 'Create')) {
            Invoke-AutoTaskRequest @InvokeParams
        }

    }

    end {}

}
