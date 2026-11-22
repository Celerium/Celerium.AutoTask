function Get-AutoTaskBaseURI {
<#
    .SYNOPSIS
        Shows the AutoTask base URI

    .DESCRIPTION
        The Get-AutoTaskBaseURI cmdlet shows the AutoTask base URI from
        the global variable

    .PARAMETER AndApiUri
        Also include the API version uri, such as /V1.0

    .EXAMPLE
        Get-AutoTaskBaseURI

        Shows the AutoTask base URI value defined in the global variable

    .EXAMPLE
        Get-AutoTaskBaseURI -AndApiUri

        Shows the AutoTask base URI value with the API version uri defined in the global variable

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskBaseURI.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param (
        [Parameter(Mandatory = $false)]
        [switch]$AndApiUri
    )

    begin {}

    process {

        if ([bool]$AutoTaskModuleBaseUri) {
            if ($AndApiUri) { $AutoTaskModuleBaseUriComplete }
            else { $AutoTaskModuleBaseUri }
        }
        else { Write-Warning "The AutoTask base URI is not set. Run Add-AutoTaskBaseURI to set the base URI." }

    }

    end {}

}
