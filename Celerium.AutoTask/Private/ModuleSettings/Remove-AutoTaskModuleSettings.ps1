function Remove-AutoTaskModuleSettings {
<#
    .SYNOPSIS
        Removes the stored AutoTask configuration folder

    .DESCRIPTION
        The Remove-AutoTaskModuleSettings cmdlet removes the AutoTask folder and its files
        This cmdlet also has the option to remove sensitive AutoTask variables as well

        By default configuration files are stored in the following location and will be removed:
            $env:USERPROFILE\Celerium.AutoTask

    .PARAMETER AutoTaskConfigPath
        Define the location of the AutoTask configuration folder

        By default the configuration folder is located at:
            $env:USERPROFILE\Celerium.AutoTask

    .PARAMETER AndVariables
        Define if sensitive AutoTask variables should be removed as well

        By default the variables are not removed

    .EXAMPLE
        Remove-AutoTaskModuleSettings

        Checks to see if the default configuration folder exists and removes it if it does

        The default location of the AutoTask configuration folder is:
            $env:USERPROFILE\Celerium.AutoTask

    .EXAMPLE
        Remove-AutoTaskModuleSettings -AutoTaskConfigPath C:\Celerium.AutoTask -AndVariables

        Checks to see if the defined configuration folder exists and removes it if it does
        If sensitive AutoTask variables exist then they are removed as well

        The location of the AutoTask configuration folder in this example is:
            C:\Celerium.AutoTask

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Remove-AutoTaskModuleSettings.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Destroy',SupportsShouldProcess, ConfirmImpact = 'None')]
    Param (
        [Parameter()]
        [string]$AutoTaskConfigPath = $(Join-Path -Path $home -ChildPath $(if ($IsWindows -or $PSEdition -eq 'Desktop') {"Celerium.AutoTask"}else{".Celerium.AutoTask"}) ),

        [Parameter()]
        [switch]$AndVariables
    )

    begin {}

    process {

        if(Test-Path $AutoTaskConfigPath)  {

            Remove-Item -Path $AutoTaskConfigPath -Recurse -Force -WhatIf:$WhatIfPreference

            If ($AndVariables) {
                Remove-AutoTaskApiKey
                Remove-AutoTaskBaseUri
            }

            if ($WhatIfPreference -eq $false) {

                if (!(Test-Path $AutoTaskConfigPath)) {
                    Write-Output "The Celerium.AutoTask configuration folder has been removed successfully from [ $AutoTaskConfigPath ]"
                }
                else {
                    Write-Error "The Celerium.AutoTask configuration folder could not be removed from [ $AutoTaskConfigPath ]"
                }

            }

        }
        else {
            Write-Warning "No configuration folder found at [ $AutoTaskConfigPath ]"
        }

    }

    end {}

}