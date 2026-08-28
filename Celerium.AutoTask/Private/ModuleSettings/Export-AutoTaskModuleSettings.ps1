function Export-AutoTaskModuleSettings {
<#
    .SYNOPSIS
        Exports the AutoTask BaseURI, API, & JSON configuration information to file

    .DESCRIPTION
        The Export-AutoTaskModuleSettings cmdlet exports the AutoTask BaseURI, API, & JSON configuration information to file

        Making use of PowerShell's System.Security.SecureString type, exporting module settings encrypts your API key in a format
        that can only be unencrypted with the your Windows account as this encryption is tied to your user principal
        This means that you cannot copy your configuration file to another computer or user account and expect it to work

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

        Write-Warning "Secrets are stored using Windows Data Protection API (DPAPI)"
        Write-Warning "DPAPI provides user context encryption in Windows but NOT in other operating systems like Linux or UNIX. It is recommended to use a more secure & cross-platform storage method"

        $AutoTaskConfig = Join-Path -Path $AutoTaskConfigPath -ChildPath $AutoTaskConfigFile

        $GlobalModuleVariables = @('AutoTaskModuleBaseUri', 'AutoTaskModuleBaseUriApiVersion', 'AutoTaskModuleApiUsername', 'AutoTaskModuleApiSecretKey', 'AutoTaskModuleUserAgent', 'AutoTaskModuleJSONConversionDepth')
        foreach ($GlobalVariable in  $GlobalModuleVariables) {
            if (-not (Get-Variable -Name $GlobalVariable -ErrorAction SilentlyContinue -ErrorVariable GlobalVariableCheck)){
                Write-Error "The required module variable [ $GlobalVariable ] is not set"
            }
        }

        # Confirm variables exist and are not null before exporting
        if (-not $GlobalVariableCheck) {
            $SecureString = $AutoTaskModuleApiSecretKey | ConvertFrom-SecureString

            if ($IsWindows -or $PSEdition -eq 'Desktop') {
                New-Item -Path $AutoTaskConfigPath -ItemType Directory -Force | ForEach-Object { $_.Attributes = $_.Attributes -bor "Hidden" }
            }
            else{
                New-Item -Path $AutoTaskConfigPath -ItemType Directory -Force
            }
@"
    @{
        AutoTaskModuleBaseUri             = '$AutoTaskModuleBaseUri'
        AutoTaskModuleBaseUriApiVersion   = '$AutoTaskModuleBaseUriApiVersion'
        AutoTaskModuleBaseUriComplete     = '$AutoTaskModuleBaseUriComplete'
        AutoTaskModuleApiUsername         = '$AutoTaskModuleApiUsername'
        AutoTaskModuleApiSecretKey        = '$SecureString'
        AutoTaskModuleApiIntegrationCode  = '$AutoTaskModuleApiIntegrationCode'
        AutoTaskModuleUserAgent           = '$AutoTaskModuleUserAgent'
        AutoTaskModuleJSONConversionDepth = '$AutoTaskModuleJSONConversionDepth'
    }
"@ | Out-File -FilePath $AutoTaskConfig -Force
        }
        else {
            Write-Error "Failed to export AutoTask Module settings to [ $AutoTaskConfig ]"
            Write-Error $_
            exit 1
        }

    }

    end {}

}