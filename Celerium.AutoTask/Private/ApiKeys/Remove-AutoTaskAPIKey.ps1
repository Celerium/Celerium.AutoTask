function Remove-AutoTaskAPIKey {
<#
    .SYNOPSIS
        Removes the Api keys from the global variables

    .DESCRIPTION
        The Remove-AutoTaskAPIKey cmdlet removes the Api keys
        from the global variables

    .EXAMPLE
        Remove-AutoTaskAPIKey

        Removes the Api keys from the global variables

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Remove-AutoTaskAPIKey.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Destroy', SupportsShouldProcess, ConfirmImpact = 'None')]
    Param ()

    begin {}

    process {

        switch ([bool]$AutoTaskModuleApiUsername) {
            $true   { Remove-Variable -Name "AutoTaskModuleApiUsername" -Scope Global -Force }
            $false  { Write-Warning "The AutoTask API key is not set. Nothing to remove" }
        }

        switch ([bool]$AutoTaskModuleApiSecretKey) {
            $true   { Remove-Variable -Name "AutoTaskModuleApiSecretKey" -Scope Global -Force }
            $false  { Write-Warning "The AutoTask API secret key is not set. Nothing to remove" }
        }

        switch ([bool]$AutoTaskModuleApiIntegrationCode) {
            $true   { Remove-Variable -Name "AutoTaskModuleApiIntegrationCode" -Scope Global -Force }
            $false  { Write-Warning "The AutoTask API integration code is not set. Nothing to remove" }
        }

    }

    end {}

}