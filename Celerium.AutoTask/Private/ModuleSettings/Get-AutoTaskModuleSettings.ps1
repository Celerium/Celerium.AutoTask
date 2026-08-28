function Get-AutoTaskModuleSettings {
<#
    .SYNOPSIS
        Gets the saved AutoTask configuration settings

    .DESCRIPTION
        The Get-AutoTaskModuleSettings cmdlet gets the saved AutoTask configuration settings
        from the local system

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

    .PARAMETER OpenConfigFile
        Opens the AutoTask configuration file

    .EXAMPLE
        Get-AutoTaskModuleSettings

        Gets the contents of the configuration file that was created with the
        Export-AutoTaskModuleSettings

        The default location of the AutoTask configuration file is:
            $env:USERPROFILE\Celerium.AutoTask\config.psd1

    .EXAMPLE
        Get-AutoTaskModuleSettings -AutoTaskConfigPath C:\Celerium.AutoTask -AutoTaskConfigFile MyConfig.psd1 -OpenConfFile

        Opens the configuration file from the defined location in the default editor

        The location of the AutoTask configuration file in this example is:
            C:\Celerium.AutoTask\MyConfig.psd1

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskModuleSettings.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param (
        [Parameter()]
        [string]$AutoTaskConfigPath = $(Join-Path -Path $home -ChildPath $(if ($IsWindows -or $PSEdition -eq 'Desktop') {"Celerium.AutoTask"}else{".Celerium.AutoTask"}) ),

        [Parameter()]
        [string]$AutoTaskConfigFile = 'config.psd1',

        [Parameter()]
        [switch]$OpenConfigFile
    )

    begin {
        $AutoTaskConfig = Join-Path -Path $AutoTaskConfigPath -ChildPath $AutoTaskConfigFile
    }

    process {

        if (Test-Path -Path $AutoTaskConfig) {

            if($OpenConfigFile) {
                Invoke-Item -Path $AutoTaskConfig
            }
            else{
                Import-LocalizedData -BaseDirectory $AutoTaskConfigPath -FileName $AutoTaskConfigFile
            }

        }
        else{
            Write-Verbose "No configuration file found at [ $AutoTaskConfig ]"
        }

    }

    end {}

}