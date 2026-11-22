function Get-AutoTaskAPIKey {
<#
    .SYNOPSIS
        Gets the AutoTask API username, secret, & integration code

    .DESCRIPTION
        The Get-AutoTaskAPIKey cmdlet gets the AutoTask API username, secret, & integration code
        from the global variables and returns them as an object

        By default the secret is returned as a SecureString

    .PARAMETER AsPlainText
        Decrypt and return the API secret in plain text

    .EXAMPLE
        Get-AutoTaskAPIKey

        Gets the API values and returns them as an object with the secret as a SecureString

    .EXAMPLE
        Get-AutoTaskAPIKey -AsPlainText

        Gets the API values and returns them as an object with the secret as plain text

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskAPIKey.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param (
        [Parameter(Mandatory = $false)]
        [switch]$AsPlainText
    )

    begin {}

    process {

        try {

            if ($AutoTaskModuleApiSecretKey) {

                if ($AsPlainText) {
                    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AutoTaskModuleApiSecretKey)
                    [PSCustomObject]@{
                        Username            = $AutoTaskModuleApiUsername
                        Password            = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)
                        ApiIntegrationCode  = $AutoTaskModuleApiIntegrationCode
                    }
                }
                else {
                    [PSCustomObject]@{
                        Username            = $AutoTaskModuleApiUsername
                        Password            = $AutoTaskModuleApiSecretKey
                        ApiIntegrationCode  = $AutoTaskModuleApiIntegrationCode
                    }
                }

            }
            else { Write-Warning "The AutoTask API secret is not set. Run Add-AutoTaskAPIKey to set the API values" }

        }
        catch {
            Write-Error $_
        }
        finally {
            if ($BSTR) { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR) }
        }

    }

    end {}

}
