function Add-AutoTaskAPIKey {
<#
    .SYNOPSIS
        Sets your API key used to authenticate all API calls

    .DESCRIPTION
        The Add-AutoTaskAPIKey cmdlet sets your API key which is used to
        authenticate all API calls made to AutoTask

        AutoTask API keys can be generated via the AutoTask web interface
            Resources > API User > Credentials

    .PARAMETER ApiUsername
        Plain text API username

    .PARAMETER ApiSecretKey
        Plain text API secret key

        If not defined the cmdlet will prompt you to enter the API secret key which
        will be stored as a SecureString

    .PARAMETER ApiKeySecureString
        Input a SecureString object containing the API key

    .PARAMETER ApiIntegrationCode
        Plain text API integration code

    .EXAMPLE
        Add-AutoTaskAPIKey -ApiUsername 'Celerium@Celerium.org' -ApiIntegrationCode '12345'

        Prompts to enter in the API secret key which will be stored as a SecureString

    .EXAMPLE
        Add-AutoTaskAPIKey -ApiUsername 'Celerium@Celerium.org' -ApiIntegrationCode '12345' -ApiSecretKey '12345'

        Converts the string to a SecureString and stores it in the global variable

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Add-AutoTaskAPIKey.html
#>

    [CmdletBinding(DefaultParameterSetName = 'AsPlainText')]
    [Alias('Set-AutoTaskAPIKey')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ApiUsername,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ParameterSetName = 'AsPlainText')]
        [AllowEmptyString()]
        [string]$ApiSecretKey,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ParameterSetName = 'AsSecureString')]
        [validateNotNullOrEmpty()]
        [securestring]$ApiKeySecureString,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ApiIntegrationCode
    )

    begin {}

    process{

        Set-Variable -Name "AutoTaskModuleApiUsername"          -Value $ApiUsername -Option ReadOnly -Scope Global -Force
        Set-Variable -Name "AutoTaskModuleApiIntegrationCode"   -Value $ApiIntegrationCode -Option ReadOnly -Scope Global -Force

        switch ($PSCmdlet.ParameterSetName) {
            'AsPlainText'       {

                if ($ApiSecretKey) {
                    $SecureString = ConvertTo-SecureString $ApiSecretKey -AsPlainText -Force
                }
                else {
                    Write-Output "Please enter your API key:"
                    $SecureString = Read-Host -AsSecureString
                }

                Set-Variable -Name "AutoTaskModuleApiSecretKey" -Value $SecureString -Option ReadOnly -Scope Global -Force

            }
            'AsSecureString'    {

                Set-Variable -Name "AutoTaskModuleApiSecretKey" -Value $ApiKeySecureString -Option ReadOnly -Scope Global -Force

            }
        }

    }

    end {}

}