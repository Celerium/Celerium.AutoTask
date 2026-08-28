function Get-AutoTaskAPIKey {
<#
    .SYNOPSIS
        Gets the AutoTask API key

    .DESCRIPTION
        The Get-AutoTaskAPIKey cmdlet gets the AutoTask API key from
        the global variable and returns it as an object

    .PARAMETER AsPlainText
        Decrypt and return the API key in plain text

    .EXAMPLE
        Get-AutoTaskAPIKey

        Gets the Api keys and returns them as an object. The
        API secret key is returned as a secure string

    .EXAMPLE
        Get-AutoTaskAPIKey -AsPlainText

        Gets the Api keys and returns them as an object. The
        API secret key is returned as plain text

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
                    $ApiSecretKey = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AutoTaskModuleApiSecretKey)

                    [PSCustomObject]@{
                        Username            = $AutoTaskModuleApiUsername
                        Password            = ( [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ApiSecretKey) ).ToString()
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
            else { Write-Warning "The AutoTask API secret key is not set. Run Add-AutoTaskAPIKey to set the API key" }

        }
        catch {
            Write-Error $_
        }
        finally {
            if ($ApiSecretKey) {
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ApiSecretKey)
            }
        }


    }

    end {}

}