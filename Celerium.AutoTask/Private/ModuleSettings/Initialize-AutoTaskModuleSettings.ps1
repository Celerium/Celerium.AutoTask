#Used to auto load either baseline settings or saved configurations when the module is imported
Import-AutoTaskModuleSettings -Verbose:$false

if ($null -eq $AutoTaskModuleSwagger) {

    Write-Verbose "Loading dynamic parameters for API resource methods"
    Set-AutoTaskResourceDynamicParameter

}