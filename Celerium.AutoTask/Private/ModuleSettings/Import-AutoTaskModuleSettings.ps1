function Import-AutoTaskModuleSettings {
<#
    .SYNOPSIS
        Imports the AutoTask BaseURI, API, & JSON configuration information to the current session

    .DESCRIPTION
        The Import-AutoTaskModuleSettings cmdlet imports the AutoTask BaseURI, API, & JSON configuration
        information stored in the AutoTask configuration file to the users current session

        By default the configuration file is stored in the following location:
            $env:USERPROFILE\Celerium.AutoTask

        The AUTOTASK_BASE_URI, AUTOTASK_API_USERNAME, AUTOTASK_API_SECRET, & AUTOTASK_API_INTEGRATION_CODE
        environment variables are also supported and take precedence over the values stored in the
        configuration file

    .PARAMETER AutoTaskConfigPath
        Define the location to store the AutoTask configuration file

        By default the configuration file is stored in the following location:
            $env:USERPROFILE\Celerium.AutoTask

    .PARAMETER AutoTaskConfigFile
        Define the name of the AutoTask configuration file

        By default the configuration file is named:
            config.psd1

    .EXAMPLE
        Import-AutoTaskModuleSettings

        Validates that the configuration file created with the Export-AutoTaskModuleSettings cmdlet exists
        then imports the stored data into the current users session

        The default location of the AutoTask configuration file is:
            $env:USERPROFILE\Celerium.AutoTask\config.psd1

    .EXAMPLE
        Import-AutoTaskModuleSettings -AutoTaskConfigPath C:\Celerium.AutoTask -AutoTaskConfigFile MyConfig.psd1

        Validates that the configuration file created with the Export-AutoTaskModuleSettings cmdlet exists
        then imports the stored data into the current users session

        The location of the AutoTask configuration file in this example is:
            C:\Celerium.AutoTask\MyConfig.psd1

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Import-AutoTaskModuleSettings.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Set')]
    Param (
        [Parameter()]
        [string]$AutoTaskConfigPath = $(Join-Path -Path $home -ChildPath $(if ($IsWindows -or $PSEdition -eq 'Desktop') {"Celerium.AutoTask"}else{".Celerium.AutoTask"}) ),

        [Parameter()]
        [string]$AutoTaskConfigFile = 'config.psd1'
    )

    begin {

        $AutoTaskConfig = Join-Path -Path $AutoTaskConfigPath -ChildPath $AutoTaskConfigFile

        $ModuleVersion = if ($MyInvocation.MyCommand.Version) { $MyInvocation.MyCommand.Version.ToString() } else { '2.0.0' }

        switch ($PSVersionTable.PSEdition){
            'Core'      { $UserAgent = "Celerium.AutoTask/$ModuleVersion - PowerShell/$($PSVersionTable.PSVersion) ($($PSVersionTable.Platform) $($PSVersionTable.OS))" }
            'Desktop'   { $UserAgent = "Celerium.AutoTask/$ModuleVersion - WindowsPowerShell/$($PSVersionTable.PSVersion) ($($PSVersionTable.BuildVersion))" }
            default     { $UserAgent = "Celerium.AutoTask/$ModuleVersion - PowerShell/$($PSVersionTable.PSVersion)" }
        }

    }

    process {

        Set-Variable -Name "AutoTaskModuleUserAgent"            -Value $UserAgent -Scope Global -Force
        Set-Variable -Name "AutoTaskModuleJSONConversionDepth"  -Value 100 -Scope Global -Force

        if (Test-Path -Path $AutoTaskConfig) {

            try {
                $TempConfig = Import-PowerShellDataFile -Path $AutoTaskConfig -ErrorAction Stop

                if ($TempConfig.AutoTaskModuleBaseUri) {
                    $ApiVersion = if ($TempConfig.AutoTaskModuleBaseUriApiVersion) { $TempConfig.AutoTaskModuleBaseUriApiVersion } else { 'V1.0' }
                    Set-Variable -Name "AutoTaskModuleBaseUri"              -Value $TempConfig.AutoTaskModuleBaseUri                -Option ReadOnly -Scope Global -Force
                    Set-Variable -Name "AutoTaskModuleBaseUriApiVersion"    -Value $ApiVersion                                      -Option ReadOnly -Scope Global -Force
                    Set-Variable -Name "AutoTaskModuleBaseUriComplete"      -Value "$($TempConfig.AutoTaskModuleBaseUri)/$ApiVersion" -Option ReadOnly -Scope Global -Force
                }

                if ($TempConfig.AutoTaskModuleJSONConversionDepth) {
                    Set-Variable -Name "AutoTaskModuleJSONConversionDepth" -Value ([int]$TempConfig.AutoTaskModuleJSONConversionDepth) -Scope Global -Force
                }

                if ($TempConfig.AutoTaskModuleApiUsername) {
                    Set-Variable -Name "AutoTaskModuleApiUsername" -Value $TempConfig.AutoTaskModuleApiUsername -Option ReadOnly -Scope Global -Force
                }

                if ($TempConfig.AutoTaskModuleApiSecretKey) {
                    $SecretKey = ConvertTo-SecureString $TempConfig.AutoTaskModuleApiSecretKey
                    Set-Variable -Name "AutoTaskModuleApiSecretKey" -Value $SecretKey -Option ReadOnly -Scope Global -Force
                }

                if ($TempConfig.AutoTaskModuleApiIntegrationCode) {

                    # Version 2.0.0+ encrypts the integration code, version 1.x stored it as plain text
                    try {
                        $SecureCode         = ConvertTo-SecureString $TempConfig.AutoTaskModuleApiIntegrationCode -ErrorAction Stop
                        $BSTR               = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureCode)
                        $IntegrationCode    = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)
                    }
                    catch { $IntegrationCode = $TempConfig.AutoTaskModuleApiIntegrationCode }
                    finally {
                        if ($BSTR) { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR) }
                    }

                    Set-Variable -Name "AutoTaskModuleApiIntegrationCode" -Value $IntegrationCode -Option ReadOnly -Scope Global -Force

                }

                Write-Verbose "Celerium.AutoTask Module configuration loaded successfully from [ $AutoTaskConfig ]"
            }
            catch {
                Write-Warning "The Celerium.AutoTask Module configuration at [ $AutoTaskConfig ] could not be loaded - $($_.Exception.Message)"
            }
            finally {
                Remove-Variable -Name "TempConfig", "IntegrationCode" -ErrorAction SilentlyContinue
            }

        }
        else {
            Write-Verbose "No configuration file found at [ $AutoTaskConfig ] run Add-AutoTaskAPIKey & Add-AutoTaskBaseURI to get started"
        }

        # Environment variables take precedence & are the recommended method for CI\CD, Linux, & macOS
        if ($env:AUTOTASK_BASE_URI) {
            try { Add-AutoTaskBaseURI -BaseURI $env:AUTOTASK_BASE_URI }
            catch { Write-Warning "The AUTOTASK_BASE_URI environment variable is not valid - $($_.Exception.Message)" }
        }

        if ($env:AUTOTASK_API_USERNAME -and $env:AUTOTASK_API_SECRET -and $env:AUTOTASK_API_INTEGRATION_CODE) {
            Add-AutoTaskAPIKey -ApiUsername $env:AUTOTASK_API_USERNAME -ApiSecretKey $env:AUTOTASK_API_SECRET -ApiIntegrationCode $env:AUTOTASK_API_INTEGRATION_CODE
        }
        elseif ($env:AUTOTASK_API_USERNAME -or $env:AUTOTASK_API_SECRET -or $env:AUTOTASK_API_INTEGRATION_CODE) {
            Write-Warning 'The AUTOTASK_API_USERNAME, AUTOTASK_API_SECRET, & AUTOTASK_API_INTEGRATION_CODE environment variables must all be set, the API values were not loaded from the environment'
        }

    }

    end {}

}
