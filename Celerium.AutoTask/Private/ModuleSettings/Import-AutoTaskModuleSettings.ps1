function Import-AutoTaskModuleSettings {
<#
    .SYNOPSIS
        Imports the AutoTask BaseURI, API, & JSON configuration information to the current session

    .DESCRIPTION
        The Import-AutoTaskModuleSettings cmdlet imports the AutoTask BaseURI, API, & JSON configuration
        information stored in the AutoTask configuration file to the users current session

        By default the configuration file is stored in the following location:
            $env:USERPROFILE\Celerium.AutoTask

    .PARAMETER AutoTaskConfigPath
        Define the location to store the AutoTask configuration file

        By default the configuration file is stored in the following location:
            $env:USERPROFILE\Celerium.AutoTask

    .PARAMETER AutoTaskConfigFile
        Define the name of the AutoTask configuration file

        By default the configuration file is named:
            config.psd1

    .PARAMETER JsonSpec
        Defines the path to the swagger json file to use when creating the dynamic parameter

        By default the value used is the one defined in the root of the module folder

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

        $ModuleVersion = $MyInvocation.MyCommand.Version.ToString()

        switch ($PSVersionTable.PSEdition){
            'Core'      { $UserAgent = "Celerium.AutoTask/$ModuleVersion - PowerShell/$($PSVersionTable.PSVersion) ($($PSVersionTable.Platform) $($PSVersionTable.OS))" }
            'Desktop'   { $UserAgent = "Celerium.AutoTask/$ModuleVersion - WindowsPowerShell/$($PSVersionTable.PSVersion) ($($PSVersionTable.BuildVersion))" }
            default     { $UserAgent = "Celerium.AutoTask/$ModuleVersion - $([Microsoft.PowerShell.Commands.PSUserAgent].GetMembers('Static, NonPublic').Where{$_.Name -eq 'UserAgent'}.GetValue($null,$null))" }
        }

    }

    process {

        if (Test-Path $AutoTaskConfig) {
            $TempConfig = Import-LocalizedData -BaseDirectory $AutoTaskConfigPath -FileName $AutoTaskConfigFile

            $TempConfig.AutoTaskModuleApiSecretKey = ConvertTo-SecureString $TempConfig.AutoTaskModuleApiSecretKey

            Set-Variable -Name "AutoTaskModuleBaseUri"              -Value $TempConfig.AutoTaskModuleBaseUri                -Option ReadOnly -Scope Global -Force
            Set-Variable -Name "AutoTaskModuleBaseUriApiVersion"    -Value $TempConfig.AutoTaskModuleBaseUriApiVersion      -Option ReadOnly -Scope Global -Force
            Set-Variable -Name "AutoTaskModuleBaseUriComplete"      -Value $TempConfig.AutoTaskModuleBaseUriComplete        -Option ReadOnly -Scope Global -Force
            Set-Variable -Name "AutoTaskModuleApiUsername"          -Value $TempConfig.AutoTaskModuleApiUsername            -Option ReadOnly -Scope Global -Force
            Set-Variable -Name "AutoTaskModuleApiSecretKey"         -Value $TempConfig.AutoTaskModuleApiSecretKey           -Option ReadOnly -Scope Global -Force
            Set-Variable -Name "AutoTaskModuleApiIntegrationCode"   -Value $TempConfig.AutoTaskModuleApiIntegrationCode     -Option ReadOnly -Scope Global -Force
            Set-Variable -Name "AutoTaskModuleUserAgent"            -Value $TempConfig.AutoTaskModuleUserAgent              -Option ReadOnly -Scope Global -Force
            Set-Variable -Name "AutoTaskModuleJSONConversionDepth"  -Value $TempConfig.AutoTaskModuleJSONConversionDepth    -Option ReadOnly -Scope Global -Force

            Write-Verbose "Celerium.AutoTask Module configuration loaded successfully from [ $AutoTaskConfig ]"

            # Clean things up
            Remove-Variable "TempConfig"
        }
        else {
            Write-Verbose "No configuration file found at [ $AutoTaskConfig ] run Add-AutoTaskAPIKey & Add-AutoTaskBaseUri to get started"

            Set-Variable -Name "AutoTaskModuleUserAgent" -Value $UserAgent -Scope Global -Force
            Set-Variable -Name "AutoTaskModuleJSONConversionDepth" -Value 100 -Scope Global -Force
        }

    }

    end {}

}