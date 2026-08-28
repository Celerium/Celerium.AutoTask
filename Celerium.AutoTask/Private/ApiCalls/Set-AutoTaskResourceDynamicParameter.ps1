function Set-AutoTaskResourceDynamicParameter {
<#
    .SYNOPSIS
        Helper function for the New-AutoTaskResourceDynamicParameter

    .DESCRIPTION
        The Set-AutoTaskResourceDynamicParameter cmdlet is a simple helper
        function for the New-AutoTaskResourceDynamicParameter cmdlet that creates
        a new dynamic parameter for either the resource list or definitions
        list inside of swagger json

    .PARAMETER JsonSpec
        Defines the path to the swagger json file to use when creating the dynamic parameter

        By default the value used is the one defined in the root of the module folder

    .EXAMPLE
        Set-AutoTaskResourceDynamicParameter

        Generates the dynamic parameter for either the resource list or definitions list
        inside of swagger json

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/ApiCalls/Set-AutoTaskResourceDynamicParameter.html

    .LINK
        https://webservices24.autotask.net/atservicesrest/swagger/ui/index#
#>

    [CmdletBinding(DefaultParameterSetName = 'GenerateResource', SupportsShouldProcess = $true, ConfirmImpact = 'None')]
    Param (
        [Parameter(Mandatory = $false)]
        [string]$JsonSpec = $(Join-Path -Path "$($MyInvocation.MyCommand.Module.ModuleBase)" -ChildPath "AutoTaskAPI-v1-2023.6.json")
    )

    begin {}

    process {

        Write-Verbose "Configuring API resource methods"

        Set-Variable -Name "AutoTaskModuleGetParameter"         -Value (New-AutoTaskResourceDynamicParameter -ParameterType "Get" -JsonSpec $JsonSpec)          -Option ReadOnly -Scope Global -Force
        Set-Variable -Name "AutoTaskModulePatchParameter"       -Value (New-AutoTaskResourceDynamicParameter -ParameterType "Patch" -JsonSpec $JsonSpec)        -Option ReadOnly -Scope Global -Force
        Set-Variable -Name "AutoTaskModuleDeleteParameter"      -Value (New-AutoTaskResourceDynamicParameter -ParameterType "Delete" -JsonSpec $JsonSpec)       -Option ReadOnly -Scope Global -Force
        Set-Variable -Name "AutoTaskModulePostParameter"        -Value (New-AutoTaskResourceDynamicParameter -ParameterType "Post" -JsonSpec $JsonSpec)         -Option ReadOnly -Scope Global -Force
        Set-Variable -Name "AutoTaskModulePostPatchParameter"   -Value (New-AutoTaskResourceDynamicParameter -ParameterType "Post Patch" -JsonSpec $JsonSpec)   -Option ReadOnly -Scope Global -Force


    }

    end{}
}