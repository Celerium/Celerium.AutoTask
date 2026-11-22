function Remove-AutoTaskBaseURI {
<#
    .SYNOPSIS
        Removes the AutoTask base URI global variable

    .DESCRIPTION
        The Remove-AutoTaskBaseURI cmdlet removes the AutoTask base URI from
        the global variable

    .EXAMPLE
        Remove-AutoTaskBaseURI

        Removes the AutoTask base URI value from the global variable

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Remove-AutoTaskBaseURI.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Destroy', SupportsShouldProcess, ConfirmImpact = 'None')]
    Param ()

    begin {}

    process {

        if ([bool]$AutoTaskModuleBaseUri) {
            if ($PSCmdlet.ShouldProcess('AutoTaskModuleBaseUri')) {
                Remove-Variable -Name 'AutoTaskModuleBaseUri' -Scope Global -Force -ErrorAction SilentlyContinue
                Remove-Variable -Name 'AutoTaskModuleBaseUriApiVersion' -Scope Global -Force -ErrorAction SilentlyContinue
                Remove-Variable -Name 'AutoTaskModuleBaseUriComplete' -Scope Global -Force -ErrorAction SilentlyContinue
            }
        }
        else { Write-Warning "The AutoTask base URI variable is not set. Nothing to remove" }

    }

    end {}

}
