function Add-AutoTaskAPIKey {
<#
    .SYNOPSIS
        Sets the API username, secret, & integration code used to authenticate all API calls

    .DESCRIPTION
        The Add-AutoTaskAPIKey cmdlet sets the API username, secret, & integration code which
        are used to authenticate all API calls made to the AutoTask API

        The username & integration code are stored in memory as plain text & the secret is
        stored in memory as a SecureString

        AutoTask API users & their credentials are created in the AutoTask web interface
            Admin > Resources (Users) > New API User

        The API tracking identifier of the API user is the integration code

    .PARAMETER ApiUsername
        Defines the username of the API user

    .PARAMETER ApiSecretKey
        Defines the secret (password) of the API user as plain text

        If neither ApiSecretKey nor ApiKeySecureString is defined the cmdlet will prompt you
        to enter the secret which will be stored as a SecureString

    .PARAMETER ApiKeySecureString
        Input a SecureString object containing the secret of the API user

    .PARAMETER ApiIntegrationCode
        Defines the API integration code (tracking identifier) of the API user

    .EXAMPLE
        Add-AutoTaskAPIKey -ApiUsername 'api@example.com' -ApiIntegrationCode '12345'

        Prompts to enter in the API secret which will be stored as a SecureString

    .EXAMPLE
        Add-AutoTaskAPIKey -ApiUsername 'api@example.com' -ApiIntegrationCode '12345' -ApiSecretKey '12345'

        Converts the secret to a SecureString and stores the values in global variables

    .EXAMPLE
        '12345' | Add-AutoTaskAPIKey -ApiUsername 'api@example.com' -ApiIntegrationCode '12345'

        The secret is passed in from the pipeline

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Add-AutoTaskAPIKey.html
#>

    [CmdletBinding(DefaultParameterSetName = 'AsPlainText')]
    [Alias('Set-AutoTaskAPIKey')]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ApiUsername,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ParameterSetName = 'AsPlainText')]
        [AllowEmptyString()]
        [string]$ApiSecretKey,

        [Parameter(Mandatory = $true, ParameterSetName = 'AsSecureString')]
        [ValidateNotNullOrEmpty()]
        [securestring]$ApiKeySecureString,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ApiIntegrationCode
    )

    begin {}

    process {

        switch ($PSCmdlet.ParameterSetName) {

            'AsPlainText'       {
                if ($ApiSecretKey) {
                    $SecureString = ConvertTo-SecureString $ApiSecretKey -AsPlainText -Force
                }
                else {
                    $SecureString = Read-Host -Prompt 'Please enter your API secret' -AsSecureString
                }
            }

            'AsSecureString'    { $SecureString = $ApiKeySecureString }

        }

        Set-Variable -Name 'AutoTaskModuleApiUsername'          -Value $ApiUsername         -Option ReadOnly -Scope Global -Force
        Set-Variable -Name 'AutoTaskModuleApiSecretKey'         -Value $SecureString        -Option ReadOnly -Scope Global -Force
        Set-Variable -Name 'AutoTaskModuleApiIntegrationCode'   -Value $ApiIntegrationCode  -Option ReadOnly -Scope Global -Force

    }

    end {}

}
