function New-AutoTaskResourceDynamicParameter {
<#
    .SYNOPSIS
        Creates a new AutoTask resource dynamic parameter

    .DESCRIPTION
        The New-AutoTaskResourceDynamicParameter cmdlet creates a new dynamic parameter
        for either the resource list or definitions list inside of swagger json
        by opening the file, reading the contents and converting a custom object

    .PARAMETER ParameterType
        Defines the type of resource or definition to use when creating the dynamic parameter

    .PARAMETER JsonSpec
        Defines the path to the swagger json file to use when creating the dynamic parameter

        By default the value used is the one defined in the root of the module folder

    .EXAMPLE
        New-AutoTaskResourceDynamicParameter

        You will be prompted to select a parameter type and resource

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/New-AutoTaskResourceDynamicParameter.html

    .LINK
        https://webservices24.autotask.net/atservicesrest/swagger/ui/index#
#>

    [CmdletBinding(DefaultParameterSetName = 'GenerateResource', SupportsShouldProcess = $true, ConfirmImpact = 'None')]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$ParameterType,

        [Parameter(Mandatory = $false)]
        [string]$JsonSpec
    )

    begin {}

    process {

        $ParameterName                  = "Resource"
        $RuntimeParameterDictionary     = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $AttributeCollection            = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute             = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory   = $true
        $AttributeCollection.Add($ParameterAttribute)

        Set-Variable -Name "AutoTaskModuleSwagger" -Value $(Get-Content $JsonSpec -Raw | ConvertFrom-Json) -Option ReadOnly -Scope Global -Force

        $Queries = foreach ($Path in $AutoTaskModuleSwagger.Paths.PSObject.Properties) {
            [PSCustomObject]@{
                Index  = $($path.name.split("/")[2])
                Name   = $($path.Name)
                Get    = $($Path.value.get.tags)
                Post   = $($Path.value.post.tags)
                Patch  = $($Path.value.patch.tags)
                Delete = $($Path.value.delete.tags)

            }
        }
        Set-Variable -Name "AutoTaskModuleQueries" -Value $Queries -Option ReadOnly -Scope Global -Force

        $ResourceList = $null
        foreach ( $Type in $ParameterType.Split( ' ' ) ) {
            $ResourceList += foreach ($Query in $Queries | Where-Object { $null -ne $_."$Type" }  ) {
                $Resource = $Query."$Type" | Select-Object -Last 1
                $Resource
            }
        }
        $ResourceList = $ResourceList | Sort-Object -Unique

        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ResourceList)
        $AttributeCollection.Add($ValidateSetAttribute)

        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

        return $RuntimeParameterDictionary

    }

    end{}
}