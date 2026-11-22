function Export-AutoTaskModuleSettings {
<#
    .SYNOPSIS
        Exports the AutoTask BaseURI, API, & JSON configuration information to file

    .DESCRIPTION
        The Export-AutoTaskModuleSettings cmdlet exports the AutoTask BaseURI, API, & JSON configuration information to file

        Making use of PowerShell's System.Security.SecureString type, exporting module settings encrypts your API secret &
        integration code in a format that can only be unencrypted with the your Windows account as this encryption is tied
        to your user principal. This means that you cannot copy your configuration file to another computer or user account
        and expect it to work

        On Linux & macOS the SecureString is NOT encrypted, it is recommended to use the AUTOTASK_BASE_URI,
        AUTOTASK_API_USERNAME, AUTOTASK_API_SECRET, & AUTOTASK_API_INTEGRATION_CODE environment variables
        or a secret store instead

    .PARAMETER AutoTaskConfigPath
        Define the location to store the AutoTask configuration file

        By default the configuration file is stored in the following location:
            $env:USERPROFILE\Celerium.AutoTask

    .PARAMETER AutoTaskConfigFile
        Define the name of the AutoTask configuration file

        By default the configuration file is named:
            config.psd1

    .EXAMPLE
        Export-AutoTaskModuleSettings

        Validates that the BaseURI, API, and JSON depth are set then exports their values
        to the current user's AutoTask configuration file located at:
            $env:USERPROFILE\Celerium.AutoTask\config.psd1

    .EXAMPLE
        Export-AutoTaskModuleSettings -AutoTaskConfigPath C:\Celerium.AutoTask -AutoTaskConfigFile MyConfig.psd1

        Validates that the BaseURI, API, and JSON depth are set then exports their values
        to the current user's AutoTask configuration file located at:
            C:\Celerium.AutoTask\MyConfig.psd1

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Export-AutoTaskModuleSettings.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Set')]
    Param (
        [Parameter()]
        [string]$AutoTaskConfigPath = $(Join-Path -Path $home -ChildPath $(if ($IsWindows -or $PSEdition -eq 'Desktop') {"Celerium.AutoTask"}else{".Celerium.AutoTask"}) ),

        [Parameter()]
        [string]$AutoTaskConfigFile = 'config.psd1'
    )

    begin {}

    process {

        if ($IsWindows -or $PSEdition -eq 'Desktop') {
            Write-Verbose "Secrets are stored using the Windows Data Protection API (DPAPI)"
        }
        else {
            Write-Warning "DPAPI provides user context encryption in Windows but NOT in other operating systems like Linux or UNIX. It is recommended to use the AUTOTASK_BASE_URI, AUTOTASK_API_USERNAME, AUTOTASK_API_SECRET, & AUTOTASK_API_INTEGRATION_CODE environment variables or a more secure & cross-platform storage method"
        }

        $AutoTaskConfig = Join-Path -Path $AutoTaskConfigPath -ChildPath $AutoTaskConfigFile

        $GlobalModuleVariables = @('AutoTaskModuleBaseUri', 'AutoTaskModuleBaseUriApiVersion', 'AutoTaskModuleBaseUriComplete', 'AutoTaskModuleApiUsername', 'AutoTaskModuleApiSecretKey', 'AutoTaskModuleApiIntegrationCode', 'AutoTaskModuleJSONConversionDepth')

        $MissingVariables = foreach ($GlobalVariable in $GlobalModuleVariables) {
            if (-not (Get-Variable -Name $GlobalVariable -ErrorAction SilentlyContinue)) { $GlobalVariable }
        }

        if ($MissingVariables) {
            throw "Failed to export AutoTask Module settings, the required module variables [ $($MissingVariables -join ', ') ] are not set"
        }

        $SecretKey          = $AutoTaskModuleApiSecretKey | ConvertFrom-SecureString
        $IntegrationCode    = ConvertTo-SecureString -String $AutoTaskModuleApiIntegrationCode -AsPlainText -Force | ConvertFrom-SecureString

        if ($IsWindows -or $PSEdition -eq 'Desktop') {
            New-Item -Path $AutoTaskConfigPath -ItemType Directory -Force | ForEach-Object { $_.Attributes = $_.Attributes -bor "Hidden" }
        }
        else {
            New-Item -Path $AutoTaskConfigPath -ItemType Directory -Force > $null
        }

@"
@{
    AutoTaskModuleBaseUri             = '$($AutoTaskModuleBaseUri -replace "'","''")'
    AutoTaskModuleBaseUriApiVersion   = '$($AutoTaskModuleBaseUriApiVersion -replace "'","''")'
    AutoTaskModuleBaseUriComplete     = '$($AutoTaskModuleBaseUriComplete -replace "'","''")'
    AutoTaskModuleApiUsername         = '$($AutoTaskModuleApiUsername -replace "'","''")'
    AutoTaskModuleApiSecretKey        = '$SecretKey'
    AutoTaskModuleApiIntegrationCode  = '$IntegrationCode'
    AutoTaskModuleJSONConversionDepth = '$AutoTaskModuleJSONConversionDepth'
}
"@ | Out-File -FilePath $AutoTaskConfig -Force

    }

    end {}

}
