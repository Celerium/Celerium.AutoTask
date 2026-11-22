function Remove-AutoTaskAPIKey {
<#
    .SYNOPSIS
        Removes the API username, secret, & integration code from the global variables

    .DESCRIPTION
        The Remove-AutoTaskAPIKey cmdlet removes the API username, secret, & integration code
        from the global variables

    .EXAMPLE
        Remove-AutoTaskAPIKey

        Removes the API values from the global variables

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Remove-AutoTaskAPIKey.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Destroy', SupportsShouldProcess, ConfirmImpact = 'None')]
    Param ()

    begin {}

    process {

        if ([bool]$AutoTaskModuleApiUsername -or [bool]$AutoTaskModuleApiSecretKey -or [bool]$AutoTaskModuleApiIntegrationCode) {
            if ($PSCmdlet.ShouldProcess('AutoTaskModuleApiUsername, AutoTaskModuleApiSecretKey, AutoTaskModuleApiIntegrationCode')) {
                Remove-Variable -Name 'AutoTaskModuleApiUsername' -Scope Global -Force -ErrorAction SilentlyContinue
                Remove-Variable -Name 'AutoTaskModuleApiSecretKey' -Scope Global -Force -ErrorAction SilentlyContinue
                Remove-Variable -Name 'AutoTaskModuleApiIntegrationCode' -Scope Global -Force -ErrorAction SilentlyContinue
            }
        }
        else { Write-Warning "The AutoTask API values are not set. Nothing to remove" }

    }

    end {}

}
