#Region '.\Private\ApiCalls\Invoke-AutoTaskRequest.ps1' -1

function Invoke-AutoTaskRequest {
<#
    .SYNOPSIS
        Makes an API request to AutoTask

    .DESCRIPTION
        The Invoke-AutoTaskRequest cmdlet invokes an API request to the AutoTask API

        This is an internal function that is used by all public functions

    .PARAMETER Method
        Defines the type of API method to use

        Allowed values:
        'GET', 'PUT', 'POST', 'PATCH', 'DELETE'

    .PARAMETER ResourceURI
        Defines the resource uri (url) to use when creating the API call

    .PARAMETER Data
        Object containing supported AutoTask method schemas

    .PARAMETER AllResults
        Returns all items from an endpoint

    .EXAMPLE
        Invoke-AutoTaskRequest -Method GET -ResourceURI '/passwords' -UriFilter $UriFilter

        Invoke a rest method against the defined resource using the provided parameters

        Example HashTable:
            $UriParameters = @{
                'filter[id]']               = 123456789
                'filter[organization_id]']  = 12345
            }

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Invoke-AutoTaskRequest.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Invoke', SupportsShouldProcess)]
    param (
        [Parameter()]
        [ValidateSet('GET', 'PUT', 'POST', 'PATCH', 'DELETE')]
        [string]$Method = 'GET',

        [Parameter(Mandatory = $true)]
        [string]$ResourceURI,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        $Data,

        [Parameter()]
        [switch]$AllResults
    )

    begin {

        # Load Web assembly when needed as PowerShell Core has the assembly preloaded
        if ( !("System.Web.HttpUtility" -as [Type]) ) { Add-Type -Assembly System.Web }

        $FunctionName   = $MyInvocation.InvocationName
        $ParameterName  = $FunctionName + '_Parameters' -replace '-','_'

        $ApiSecret = Get-AutoTaskAPIKey -AsPlainText -WarningAction SilentlyContinue -WarningVariable 'Get_AutoTaskAPIKey_Warning'
        if ( $Get_AutoTaskAPIKey_Warning -or !$(Get-AutoTaskBaseURI -WarningAction SilentlyContinue)) {
            throw "No authentication method or base uri found, please run Add-AutoTaskAPIKey & Add-AutoTaskBaseURI to continue"
        }

        $Headers = @{
            'ApiIntegrationCode'    = $ApiSecret.ApiIntegrationCode
            'UserName'              = $ApiSecret.Username
            'Secret'                = $ApiSecret.Password
            'Content-Type'          = "application/json; charset=utf-8"
        }

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $AllResponseData = [System.Collections.Generic.List[object]]::new()

        $Page       = 1
        $RetryCount = 0
        $RetryMax   = 3

        Set-Variable -Name TEST_BASEURI -Value $AutoTaskModuleBaseUri -Scope Global -Force -Confirm:$false
        Set-Variable -Name TEST_RESOURCEURI -Value $ResourceURI -Scope Global -Force -Confirm:$false

        #POST ResourceURI have double // in the path
        $ResourceURI    = $ResourceURI -replace '(?<!:)/{2,}', '/'
        $TargetUri      = $AutoTaskModuleBaseUri + $ResourceURI

        $InvokeParams = @{
            Method      = $Method
            Headers     = $Headers
            URI         = $TargetUri
            UserAgent   = $AutoTaskModuleUserAgent
        }

        if ($Method -ne 'GET') {
            if ($Data -is [string]) { $SendingBody = $Data }
            else { $SendingBody = $Data | ConvertTo-Json -Depth $AutoTaskModuleJSONConversionDepth }

            $InvokeParams.Body  = $SendingBody
        }

        Set-Variable -Name $ParameterName -Value $InvokeParams -Scope Global -Force -Confirm:$false

        try{
            do {
                try{
                    $ApiResponse = Invoke-RestMethod @InvokeParams

                    if ($AllResults) {
                        $InvokeParams['Uri'] = $ApiResponse.pageDetails.nextPageUrl
                    }

                    # Returns blank unless $Items itself is returned for InvoicePDF function
                    if ($ResourceTarget -eq "InvoicePDF") {
                        Write-Verbose "Processing [ $(($ApiResponse | Measure-Object).Count) ] items from page [ $Page ]"
                        $AllResponseData.Add($ApiResponse)
                    }

                    if ($ApiResponse.fields) {
                        $AllResponseData.Add($ApiResponse)
                    }

                    if ($ApiResponse.items)   {
                        Write-Verbose "Processing [ $($ApiResponse.pageDetails.count) ] items from page [ $Page ]"
                        $AllResponseData.AddRange(@($ApiResponse.items))
                    }

                    if ($ApiResponse.item)    {
                        Write-Verbose "Processing [ $(($ApiResponse.item | Measure-Object).Count) ] items from page [ $Page ]"
                        $AllResponseData.AddRange(@($ApiResponse.item))
                    }

                    $Page++
                }
                catch {
                    $ExceptionError = $_.Exception.Message
                    Write-Warning 'The [ Invoke_AutoTaskRequest_Parameters, Invoke_AutoTaskRequest_ParametersQuery, & CmdletName_Parameters ] variables can provide extra details'

                    $RandomWaitTime = [Math]::Min( [Math]::Pow(2,$RetryCount) + (Get-Random -Minimum 0 -Maximum 30),120)

                    switch -Wildcard ($ExceptionError) {
                        '*400*' {   throw }
                        '*404*' {   throw "Invoke-AutoTaskRequest : URI not found - [ $TargetUri ]"}
                        '*429*' {
                                    $RetryAfter = $_.Exception.Response.Headers['Retry-After']
                                    if ($RetryAfter) { $RandomWaitTime = [int]$RetryAfter }

                                    Write-Error "Invoke-AutoTaskRequest : API rate limited  - Sleeping for [ $RandomWaitTime ] seconds"

                                    if ($RetryAfter) { Start-Sleep -Seconds [int]$RetryAfter }
                                    else { Start-Sleep -Seconds $RandomWaitTime }
                                }
                        '*504*' {   Write-Error "Invoke-AutoTaskRequest : Gateway Timeout  - Sleeping for [ $RandomWaitTime ] seconds"
                                    Start-Sleep -Seconds $RandomWaitTime
                                }
                        default { Write-Error $_ }
                    }

                    $RetryCount++
                    if ($RetryCount -lt $RetryMax) {
                        Write-Warning "Invoke-AutoTaskRequest : Retrying request [ $ResourceURI ] - Attempt [ $RetryCount/$RetryMax ]"
                    }
                    else{
                        throw "Invoke-AutoTaskRequest : Maximum retry attempts reached [ $RetryCount/$RetryMax ]"
                    }

                }
            }
            while ($AllResults -and $InvokeParams.Uri)
        }
        catch {
            Write-Error $_
            throw
        }
        finally {
            if ($Invoke_AutoTaskRequest_Parameters) {
                $Auth = $Invoke_AutoTaskRequest_Parameters['headers']['Secret']
                if ($Auth) {
                    $Invoke_AutoTaskRequest_Parameters['headers']['Secret'] = $Auth.Substring(0,[Math]::Min($Auth.Length,9)) + '*******'
                }
            }
        }

        return $AllResponseData

    }

    end {}

}
#EndRegion '.\Private\ApiCalls\Invoke-AutoTaskRequest.ps1' 203
#Region '.\Private\ApiCalls\New-AutoTaskResourceDynamicParameter.ps1' -1

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
#EndRegion '.\Private\ApiCalls\New-AutoTaskResourceDynamicParameter.ps1' 90
#Region '.\Private\ApiCalls\Set-AutoTaskResourceDynamicParameter.ps1' -1

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
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Set-AutoTaskResourceDynamicParameter.html

    .LINK
        https://webservices24.autotask.net/atservicesrest/swagger/ui/index#
#>

    [CmdletBinding(DefaultParameterSetName = 'GenerateResource', SupportsShouldProcess = $true, ConfirmImpact = 'None')]
    Param (
        [Parameter(Mandatory = $false)]
        [string]$JsonSpec = $(Join-Path -Path "$($MyInvocation.MyCommand.Module.ModuleBase)" -ChildPath "AutoTaskAPI-2023.6.json")
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
#EndRegion '.\Private\ApiCalls\Set-AutoTaskResourceDynamicParameter.ps1' 56
#Region '.\Private\ApiKeys\Add-AutoTaskAPIKey.ps1' -1

function Add-AutoTaskAPIKey {
<#
    .SYNOPSIS
        Sets your API key used to authenticate all API calls

    .DESCRIPTION
        The Add-AutoTaskAPIKey cmdlet sets your API key which is used to
        authenticate all API calls made to AutoTask

        AutoTask API keys can be generated via the AutoTask web interface
            Resources > API User > Credentials

    .PARAMETER ApiUsername
        Plain text API username

    .PARAMETER ApiSecretKey
        Plain text API secret key

        If not defined the cmdlet will prompt you to enter the API secret key which
        will be stored as a SecureString

    .PARAMETER ApiKeySecureString
        Input a SecureString object containing the API key

    .PARAMETER ApiIntegrationCode
        Plain text API integration code

    .EXAMPLE
        Add-AutoTaskAPIKey -ApiUsername 'Celerium@Celerium.org' -ApiIntegrationCode '12345'

        Prompts to enter in the API secret key which will be stored as a SecureString

    .EXAMPLE
        Add-AutoTaskAPIKey -ApiUsername 'Celerium@Celerium.org' -ApiIntegrationCode '12345' -ApiSecretKey '12345'

        Converts the string to a SecureString and stores it in the global variable

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Add-AutoTaskAPIKey.html
#>

    [CmdletBinding(DefaultParameterSetName = 'AsPlainText')]
    [Alias('Set-AutoTaskAPIKey')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ApiUsername,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ParameterSetName = 'AsPlainText')]
        [AllowEmptyString()]
        [string]$ApiSecretKey,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ParameterSetName = 'AsSecureString')]
        [validateNotNullOrEmpty()]
        [securestring]$ApiKeySecureString,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ApiIntegrationCode
    )

    begin {}

    process{

        Set-Variable -Name "AutoTaskModuleApiUsername"          -Value $ApiUsername -Option ReadOnly -Scope Global -Force
        Set-Variable -Name "AutoTaskModuleApiIntegrationCode"   -Value $ApiIntegrationCode -Option ReadOnly -Scope Global -Force

        switch ($PSCmdlet.ParameterSetName) {
            'AsPlainText'       {

                if ($ApiSecretKey) {
                    $SecureString = ConvertTo-SecureString $ApiSecretKey -AsPlainText -Force
                }
                else {
                    Write-Output "Please enter your API key:"
                    $SecureString = Read-Host -AsSecureString
                }

                Set-Variable -Name "AutoTaskModuleApiSecretKey" -Value $SecureString -Option ReadOnly -Scope Global -Force

            }
            'AsSecureString'    {

                Set-Variable -Name "AutoTaskModuleApiSecretKey" -Value $ApiKeySecureString -Option ReadOnly -Scope Global -Force

            }
        }

    }

    end {}

}
#EndRegion '.\Private\ApiKeys\Add-AutoTaskAPIKey.ps1' 98
#Region '.\Private\ApiKeys\Get-AutoTaskAPIKey.ps1' -1

function Get-AutoTaskAPIKey {
<#
    .SYNOPSIS
        Gets the AutoTask API key

    .DESCRIPTION
        The Get-AutoTaskAPIKey cmdlet gets the AutoTask API key from
        the global variable and returns it as an object

    .PARAMETER AsPlainText
        Decrypt and return the API key in plain text

    .EXAMPLE
        Get-AutoTaskAPIKey

        Gets the Api keys and returns them as an object. The
        API secret key is returned as a secure string

    .EXAMPLE
        Get-AutoTaskAPIKey -AsPlainText

        Gets the Api keys and returns them as an object. The
        API secret key is returned as plain text

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskAPIKey.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param (
        [Parameter(Mandatory = $false)]
        [switch]$AsPlainText
    )

    begin {}

    process {

        try {

            if ($AutoTaskModuleApiSecretKey) {

                if ($AsPlainText) {
                    $ApiSecretKey = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AutoTaskModuleApiSecretKey)

                    [PSCustomObject]@{
                        Username            = $AutoTaskModuleApiUsername
                        Password            = ( [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ApiSecretKey) ).ToString()
                        ApiIntegrationCode  = $AutoTaskModuleApiIntegrationCode
                    }
                }
                else {
                    [PSCustomObject]@{
                        Username            = $AutoTaskModuleApiUsername
                        Password            = $AutoTaskModuleApiSecretKey
                        ApiIntegrationCode  = $AutoTaskModuleApiIntegrationCode
                    }
                }

            }
            else { Write-Warning "The AutoTask API secret key is not set. Run Add-AutoTaskAPIKey to set the API key" }

        }
        catch {
            Write-Error $_
        }
        finally {
            if ($ApiSecretKey) {
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ApiSecretKey)
            }
        }


    }

    end {}

}
#EndRegion '.\Private\ApiKeys\Get-AutoTaskAPIKey.ps1' 82
#Region '.\Private\ApiKeys\Remove-AutoTaskAPIKey.ps1' -1

function Remove-AutoTaskAPIKey {
<#
    .SYNOPSIS
        Removes the Api keys from the global variables

    .DESCRIPTION
        The Remove-AutoTaskAPIKey cmdlet removes the Api keys
        from the global variables

    .EXAMPLE
        Remove-AutoTaskAPIKey

        Removes the Api keys from the global variables

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Remove-AutoTaskAPIKey.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Destroy', SupportsShouldProcess, ConfirmImpact = 'None')]
    Param ()

    begin {}

    process {

        switch ([bool]$AutoTaskModuleApiUsername) {
            $true   { Remove-Variable -Name "AutoTaskModuleApiUsername" -Scope Global -Force }
            $false  { Write-Warning "The AutoTask API key is not set. Nothing to remove" }
        }

        switch ([bool]$AutoTaskModuleApiSecretKey) {
            $true   { Remove-Variable -Name "AutoTaskModuleApiSecretKey" -Scope Global -Force }
            $false  { Write-Warning "The AutoTask API secret key is not set. Nothing to remove" }
        }

        switch ([bool]$AutoTaskModuleApiIntegrationCode) {
            $true   { Remove-Variable -Name "AutoTaskModuleApiIntegrationCode" -Scope Global -Force }
            $false  { Write-Warning "The AutoTask API integration code is not set. Nothing to remove" }
        }

    }

    end {}

}
#EndRegion '.\Private\ApiKeys\Remove-AutoTaskAPIKey.ps1' 49
#Region '.\Private\ApiKeys\Test-AutoTaskAPIKey.ps1' -1

function Test-AutoTaskAPIKey {
<#
    .SYNOPSIS
        Test the AutoTask API key

    .DESCRIPTION
        The Test-AutoTaskAPIKey cmdlet tests the base URI & API key that
        are defined in the Get-AutoTaskBaseURI & Get-AutoTaskAPIKey cmdlets

        Helpful when needing to validate general functionality or when using
        RMM deployment tools

    .PARAMETER BaseUri
        Define the base URI for the AutoTask API connection
        using AutoTask's URI or a custom URI

        By default the value used is the one defined by the
        Get-AutoTaskBaseURI function

    .EXAMPLE
        Test-AutoTaskAPIKey

        Tests the base URI & API key that are defined in the
        Get-AutoTaskBaseURI & Get-AutoTaskAPIKey cmdlets

    .EXAMPLE
        Test-AutoTaskAPIKey -BaseUri http://myapi.gateway.celerium.org

        Tests the defined base URI & API key that was defined in
        the Get-AutoTaskAPIKey cmdlet

        The full base uri test path in this example is:
            http://myapi.gateway.celerium.org/Companies/query

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Test-AutoTaskAPIKey.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Test')]
    Param (
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$BaseUri = $AutoTaskModuleBaseUriComplete
    )

    begin { $ResourceUri = "/Companies/query?Search" }

    process {

        if ([bool]$BaseUri -eq $false -or [bool](Get-AutoTaskAPIKey -ErrorAction Stop) -eq $false) {
            Write-Error "The BaseUri and or ApiKeys are not set. Please run the Get-AutoTaskApiKey & Get-AutoTaskBaseURI cmdlets before running this function"
            return
        }

        Write-Verbose "Testing API key against [ $($BaseUri + $ResourceUri) ]"

        try {

            $ApiSecret  = Get-AutoTaskAPIKey -AsPlainText
            $Headers    = @{
                'ApiIntegrationCode'    = $ApiSecret.ApiIntegrationCode
                'UserName'              = $ApiSecret.Username
                'Secret'                = $ApiSecret.Password
                'Content-Type'          = "application/json"
            }

            $Body = @{
                MaxRecords = 1
                filter = @(
                    @{
                        op    = "gte"
                        field = "id"
                        value = 0
                    }
                )
            } | ConvertTo-Json -Depth 5

            $Parameters = @{
                'Method'        = 'POST'
                'Uri'           = $BaseUri + $ResourceUri
                'Headers'       = $Headers
                'Body'          = $Body
                'UserAgent'     = $AutoTaskModuleUserAgent
                UseBasicParsing = $true
            }

            $RestOutput = Invoke-WebRequest @Parameters -ErrorAction Stop

        }
        catch {

            [PSCustomObject]@{
                Method              = $_.Exception.Response.Method
                StatusCode          = $_.Exception.Response.StatusCode.value__
                StatusDescription   = $_.Exception.Response.StatusDescription
                Message             = $_.Exception.Message
                URI                 = $($BaseUri + $ResourceUri)
            }

        } finally {
            [void] ($Headers)
        }

        if ($RestOutput) {
            $Data = @{}
            $Data = $RestOutput

            [PSCustomObject]@{
                StatusCode          = $Data.StatusCode
                StatusDescription   = $Data.StatusDescription
                URI                 = $($BaseUri + $ResourceUri)
            }
        }

    }

    end {}

}
#EndRegion '.\Private\ApiKeys\Test-AutoTaskAPIKey.ps1' 123
#Region '.\Private\BaseUri\Add-AutoTaskBaseURI.ps1' -1

function Add-AutoTaskBaseURI {
<#
    .SYNOPSIS
        Sets the base URI for the AutoTask API connection

    .DESCRIPTION
        The Add-AutoTaskBaseURI cmdlet sets the base URI which is used
        to construct the full URI for all API calls

    .PARAMETER AutoDetect
        Attempts to automatically detect the base URI for the AutoTask API connection

    .PARAMETER Version
        Defines the API version to use when constructing the full URI for all API calls

    .PARAMETER BaseUri
        Sets the base URI for the AutoTask API connection. Helpful
        if using a custom API gateway or an undocumented AutoTask API endpoint

    .PARAMETER DataCenter
        Defines the data center (platform) to use which in turn defines which
        base API URL is used

        https://ww24.autotask.net/DeveloperHelp/Content/APIs/General/API_Zones.htm

        Allowed values are:
        America East                    https://webservices3.autotask.net/atservicesrest
        America East 2                  https://webservices14.autotask.net/atservicesrest
        America East 3                  https://webservices22.autotask.net/atservicesrest
        America West                    https://webservices5.autotask.net/atservicesrest
        America West 2                  https://webservices15.autotask.net/atservicesrest
        America West 3                  https://webservices24.autotask.net/atservicesrest
        America West 4                  https://webservices25.autotask.net/atservicesrest
        Australia / New Zealand         https://webservices6.autotask.net/atservicesrest
        Australia 2                     https://webservices26.autotask.net/atservicesrest
        Australia 3                     https://webservices29.autotask.net/atservicesrest
        Deutsch German                  https://webservices18.autotask.net/atservicesrest
        Deutsch Pre-Release             https://prde.autotask.net/atservicesrest
        Español Pre-Release             https://pres.autotask.net/atservicesrest
        Español Spanish                 https://webservices12.autotask.net/atservicesrest
        EU1 (English Europe and Asia)   https://webservices19.autotask.net/atservicesrest
        Limited Release                 https://webservices1.autotask.net/atservicesrest
        Pre-release                     https://webservices2.autotask.net/atservicesrest
        UK                              https://webservices4.autotask.net/atservicesrest
        UK Limited Release              https://webservices17.autotask.net/atservicesrest
        UK Pre-release                  https://webservices11.autotask.net/atservicesrest
        UK2                             https://webservices16.autotask.net/atservicesrest
        UK3                             https://webservices28.autotask.net/atservicesrest

    .EXAMPLE
        Add-AutoTaskBaseURI

        Attempts to automatically detect the base URI for the AutoTask API connection

    .EXAMPLE
        Add-AutoTaskBaseURI -BaseUri 'https://gateway.celerium.org'

        The base URI will use https://gateway.celerium.org

    .EXAMPLE
        Add-AutoTaskBaseURI -DataCenter 'America West 3'

        The base URI will use https://webservices24.autotask.net/atservicesrest/v1.0

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Add-AutoTaskBaseURI.html
#>

    [CmdletBinding(DefaultParameterSetName = 'AutoDetect')]
    [Alias('Set-AutoTaskBaseURI')]
    Param (
        [Parameter(Mandatory = $false, ParameterSetName = 'AutoDetect')]
        [switch]$AutoDetect,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Version = $((Invoke-RestMethod -Uri "https://webservices2.autotask.net/atservicesrest/VersionInformation").apiVersions | Select-Object -Last 1),

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'CustomUri')]
        [ValidateNotNullOrEmpty()]
        [string]$BaseUri,

        [Parameter(Mandatory = $false, ParameterSetName = 'Datacenter')]
        [ValidateSet(
            'America East',
            'America East 2',
            'America East 3',
            'America West',
            'America West 2',
            'America West 3',
            'America West 4',
            'Australia / New Zealand',
            'Australia 2',
            'Australia 3',
            'Deutsch German',
            'Deutsch Pre-Release',
            'Español Pre-Release',
            'Español Spanish',
            'EU1 (English Europe and Asia)',
            'Limited Release',
            'Pre-release',
            'UK',
            'UK Limited Release',
            'UK Pre-release',
            'UK2',
            'UK3'
        )]
        [Alias('Platform')]
        [string]$DataCenter
    )

    begin {}

    process{

        if ($AutoDetect) {

            try {
                $ValidationUri  = 'https://webservices2.autotask.net/atservicesrest'
                $BaseUri        = (Invoke-RestMethod -Uri "$ValidationUri/$Version/ZoneInformation?user=$AutoTaskModuleApiUsername").url

            }
            catch {
                $ErrorMessage = $_ | Out-String
                Write-Error "Could not retrieve AutoTask BaseURI. $($ErrorMessage.Trim())"
                throw
            }

        }

        if ($DataCenter) {

            switch ($DataCenter) {
                'America East'                  {$BaseUri = 'https://webservices3.autotask.net/atservicesrest'}
                'America East 2'                {$BaseUri = 'https://webservices14.autotask.net/atservicesrest'}
                'America East 3'                {$BaseUri = 'https://webservices22.autotask.net/atservicesrest'}
                'America West'                  {$BaseUri = 'https://webservices5.autotask.net/atservicesrest'}
                'America West 2'                {$BaseUri = 'https://webservices15.autotask.net/atservicesrest'}
                'America West 3'                {$BaseUri = 'https://webservices24.autotask.net/atservicesrest'}
                'America West 4'                {$BaseUri = 'https://webservices25.autotask.net/atservicesrest'}
                'Australia / New Zealand'       {$BaseUri = 'https://webservices6.autotask.net/atservicesrest'}
                'Australia 2'                   {$BaseUri = 'https://webservices26.autotask.net/atservicesrest'}
                'Australia 3'                   {$BaseUri = 'https://webservices29.autotask.net/atservicesrest'}
                'Deutsch German'                {$BaseUri = 'https://webservices18.autotask.net/atservicesrest'}
                'Deutsch Pre-Release'           {$BaseUri = 'https://prde.autotask.net/atservicesrest'}
                'Español Pre-Release'           {$BaseUri = 'https://pres.autotask.net/atservicesrest'}
                'Español Spanish'               {$BaseUri = 'https://webservices12.autotask.net/atservicesrest'}
                'EU1 (English Europe and Asia)' {$BaseUri = 'https://webservices19.autotask.net/atservicesrest'}
                'Limited Release'               {$BaseUri = 'https://webservices1.autotask.net/atservicesrest'}
                'Pre-release'                   {$BaseUri = 'https://webservices2.autotask.net/atservicesrest'}
                'UK'                            {$BaseUri = 'https://webservices4.autotask.net/atservicesrest'}
                'UK Limited Release'            {$BaseUri = 'https://webservices17.autotask.net/atservicesrest'}
                'UK Pre-release'                {$BaseUri = 'https://webservices11.autotask.net/atservicesrest'}
                'UK2'                           {$BaseUri = 'https://webservices16.autotask.net/atservicesrest'}
                'UK3'                           {$BaseUri = 'https://webservices28.autotask.net/atservicesrest'}
            }

        }

        if($BaseUri[$BaseUri.Length-1] -eq "/") {
            $BaseUri = $BaseUri.Substring(0,$BaseUri.Length-1)
        }

        Write-Verbose "Using URI: [ $($BaseURI + "/$Version") ]"

        Set-Variable -Name "AutoTaskModuleBaseUri"              -Value $BaseURI -Option ReadOnly -Scope Global -Force
        Set-Variable -Name "AutoTaskModuleBaseUriApiVersion"    -Value $Version -Option ReadOnly -Scope Global -Force
        Set-Variable -Name "AutoTaskModuleBaseUriComplete"      -Value ($BaseURI + "/$Version") -Option ReadOnly -Scope Global -Force

    }

    end {}

}
#EndRegion '.\Private\BaseUri\Add-AutoTaskBaseURI.ps1' 178
#Region '.\Private\BaseUri\Get-AutoTaskBaseURI.ps1' -1

function Get-AutoTaskBaseURI {
<#
    .SYNOPSIS
        Shows the AutoTask base URI

    .DESCRIPTION
        The Get-AutoTaskBaseURI cmdlet shows the AutoTask base URI from
        the global variable

    .PARAMETER AndApiUri
        Also include the default Api version uri

    .EXAMPLE
        Get-AutoTaskBaseURI

        Shows the AutoTask base URI value defined in the global variable

    .EXAMPLE
        Get-AutoTaskBaseURI -AndApiUri

        Shows the AutoTask base URI value with the default Api version uri defined in the global variable

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskBaseURI.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param (
        [Parameter(Mandatory = $false)]
        [switch]$AndApiUri
    )

    begin {}

    process {

        switch ([bool]$AutoTaskModuleBaseUri) {
            $true   {
                if ($AndApiUri) { $AutoTaskModuleBaseUri + "/" + $AutoTaskModuleBaseUriApiVersion }
                else { $AutoTaskModuleBaseUri }
            }
            $false  { Write-Warning "The AutoTask base URI is not set. Run Add-AutoTaskBaseURI to set the base URI." }
        }

    }

    end {}

}
#EndRegion '.\Private\BaseUri\Get-AutoTaskBaseURI.ps1' 53
#Region '.\Private\BaseUri\Remove-AutoTaskBaseURI.ps1' -1

function Remove-AutoTaskBaseURI {
<#
    .SYNOPSIS
        Removes the AutoTask base URI global variable

    .DESCRIPTION
        The Remove-AutoTaskBaseURI cmdlet removes the AutoTask base URI from
        the global variable

    .EXAMPLE
        Remove-AutoTaskBaseURI

        Removes the AutoTask base URI value from the global variable

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Internal/Remove-AutoTaskBaseURI.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Destroy', SupportsShouldProcess, ConfirmImpact = 'None')]
    Param ()

    begin {}

    process {

        switch ([bool]$AutoTaskModuleBaseUri) {

            $true   {
                if ($PSCmdlet.ShouldProcess('AutoTaskModuleBaseUri')) {
                    Remove-Variable -Name "AutoTaskModuleBaseUri" -Scope Global -Force
                    Remove-Variable -Name "AutoTaskModuleBaseUriApiVersion" -Scope Global -Force
                    Remove-Variable -Name "AutoTaskModuleBaseUriComplete" -Scope Global -Force
                }
            }
            $false  { Write-Warning "The AutoTask base URI variable is not set. Nothing to remove" }

        }

    }

    end {}

}
#EndRegion '.\Private\BaseUri\Remove-AutoTaskBaseURI.ps1' 47
#Region '.\Private\ModuleSettings\Export-AutoTaskModuleSettings.ps1' -1

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
#EndRegion '.\Private\ModuleSettings\Export-AutoTaskModuleSettings.ps1' 105
#Region '.\Private\ModuleSettings\Get-AutoTaskModuleSettings.ps1' -1

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
#EndRegion '.\Private\ModuleSettings\Get-AutoTaskModuleSettings.ps1' 89
#Region '.\Private\ModuleSettings\Import-AutoTaskModuleSettings.ps1' -1

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
#EndRegion '.\Private\ModuleSettings\Import-AutoTaskModuleSettings.ps1' 110
#Region '.\Private\ModuleSettings\Initialize-AutoTaskModuleSettings.ps1' -1

#Used to auto load either baseline settings or saved configurations when the module is imported
Import-AutoTaskModuleSettings -Verbose:$false

if ($null -eq $AutoTaskModuleSwagger) {

    Write-Verbose "Loading dynamic parameters for API resource methods"
    Set-AutoTaskResourceDynamicParameter

}
#EndRegion '.\Private\ModuleSettings\Initialize-AutoTaskModuleSettings.ps1' 10
#Region '.\Private\ModuleSettings\Remove-AutoTaskModuleSettings.ps1' -1

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
#EndRegion '.\Private\ModuleSettings\Remove-AutoTaskModuleSettings.ps1' 91
#Region '.\Public\Get-AutoTaskResource.ps1' -1

function Get-AutoTaskResource {
<#
    .SYNOPSIS
        Gets a resource

    .DESCRIPTION
        The Get-AutoTaskResource cmdlet gets a resource from the AutoTask API
        by ID or by using a simple or advanced search query

    .PARAMETER ID
        Defines the ID of the resource to get

    .PARAMETER ChildID
        Defines the ID of the child resource to get

    .PARAMETER SimpleSearch
        Defines a simple search query to use when getting the resource

        Limited to a single filter such as
        "isActive eq true" or "id eq 8765309"

    .PARAMETER AdvancedSearch
        Defines an advanced search query to use when getting the resource

        '{
            "MaxRecords":100,
            "filter":[
                {"op":"eq","field":"IsActive","value":true},
                {"op":"and","items":[
                    {"op":"beginsWith","field":"companyName","value":"D"}
                ]}
            ]
        }'

    .PARAMETER Method
        Defines the type of API method to use

        Allowed values:
        'GET', 'POST'

    .PARAMETER AllResults
        Returns all items from an endpoint

        By default only the first 500 items are returned

    .EXAMPLE
        Get-AutoTaskResource -Resource Companies -ID 8765309

        Get the company with ID 8765309

    .EXAMPLE
        Get-AutoTaskResource -Resource Companies -SimpleSearch "isActive eq true"

        Gets the first 500 active companies

    .EXAMPLE
        Get-AutoTaskResource -Resource Companies -AdvancedSearch '{"MaxRecords":100,"filter":[{"op":"eq","field":"IsActive","value":true},{"op":"and","items":[{"op":"beginsWith","field":"companyName","value":"D"}]}]}'

        Gets the first 100 active companies with a name starting with "D"

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Resource/Get-AutoTaskResource.html
#>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ID')]
        [int64]$ID,

        [Parameter(Mandatory = $false, ParameterSetName = 'ID')]
        [int64]$ChildID,

        [Parameter(Mandatory = $true, ParameterSetName = 'SimpleSearch')]
        [String]$SimpleSearch,

        [Parameter(Mandatory = $true, ParameterSetName = 'AdvancedSearch')]
        [String]$AdvancedSearch,

        [Parameter(Mandatory = $false, ParameterSetName = 'AdvancedSearch')]
        [ValidateSet('GET', 'POST')]
        [String]$Method,

        [Parameter(ParameterSetName = 'SimpleSearch')]
        [Parameter(ParameterSetName = 'AdvancedSearch')]
        [switch]$AllResults
    )

    DynamicParam {
        $AutoTaskModuleGetParameter
    }

    begin {

        $FunctionName       = $MyInvocation.InvocationName
        $ParameterName      = $functionName + '_Parameters'      -replace '-','_'

        $ResourceTarget     = $PSBoundParameters.Resource
        $ResourceIndex      = $AutoTaskModuleQueries | Group-Object Index -AsHashTable -AsString
        $ResourceEntry      = @(($ResourceIndex[$ResourceTarget] | Where-Object { $_.Get -eq $ResourceTarget }))[0]
        $ResourceUriName    = $ResourceEntry.Name -replace '/query$', '/{PARENTID}'

        # Fix path to InvoicePDF URL, must be unique vs. /Invoices in Swagger file
        $ResourceUriName    = $ResourceUriName -replace 'InvoicePDF', 'Invoices/{id}/InvoicePDF'

        if ($SimpleSearch) {
            $SearchOps      = $SimpleSearch -split ' '
            $AdvancedSearch    = ConvertTo-Json @{
                filter      = @(@{
                                field = $SearchOps[0]
                                op    = $SearchOps[1]
                                value = $SearchOps | Select-Object -Skip 2
                            })
            } -Compress
        }

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        if ($ResourceTarget -like "*child*" -and $AdvancedSearch) {
            Write-Warning "JSON search cannot be performed on child items use the parent ID"
            break
        }

        switch ($PSCmdlet.ParameterSetName) {
            'ID'    { $Method = 'GET'  }
            default { $Method = 'POST' }
        }

        $ResourceUri = $ResourceUriName
        if ($ID) { $ResourceUri = ("$ResourceUri" -replace '{parentid}', "$($ID)")  }

        if ($ChildID) { $ResourceUri = ("$($ResourceUri)/$ChildID") }

        if ($AdvancedSearch) {
            switch ($Method) {
                'GET'   { $ResourceUri = ("$ResourceUri/query?search=$AdvancedSearch" -replace '{PARENTID}', '')}
                'POST'  {
                    $ResourceUri    = ("$ResourceUri/query" -replace '{PARENTID}', '')
                    $Body           = $AdvancedSearch
                }
                Default {

                    if (($AutoTaskModuleBaseUri.Length + $ResourceUri.Length + $AdvancedSearch.Length + 15 + 120 + 100) -ge 2048){
                        #15 characters for "//query?search="
                        #TODO: Calculation does not include Overwritten ParentID and is currently a better estimation. Therefore a "safe factor" of +120 chars is used
                        #100 characters for Call of next page (Including "paging={"pageSize":500,"previousIds":[<ID>],"nextIds":[<ID>]}&" UTF-8 encoded)
                        Write-Information "Using POST-Request as Request exceeded limit of 2100 characters. You can use -Method GET/POST to set a fixed Method."
                        $ResourceUri    = ("$ResourceUri/query" -replace '{PARENTID}', '')
                        $Body           = $AdvancedSearch
                    }
                    else { $ResourceUri = ("$ResourceUri/query?search=$AdvancedSearch" -replace '{PARENTID}', '') }

                }

            }

        }

        if ($ResourceTarget -eq "InvoicePDF" -and $ID) {
            $ResourceUri = ("$($ResourceUri)" -replace '{id}', "$($ID)")
        }

        $InvokeParams = @{
            Method      = $Method
            ResourceURI = $ResourceUri
            AllResults  = $AllResults
        }

        if ($Method -eq 'POST') { $InvokeParams.Data = $Body }

        Set-Variable -Name $ParameterName -Value $InvokeParams -Scope Global -Force -Confirm:$false

        return Invoke-AutoTaskRequest @InvokeParams

    }

}
#EndRegion '.\Public\Get-AutoTaskResource.ps1' 185
#Region '.\Public\New-AutoTaskBody.ps1' -1

function New-AutoTaskBody {
<#
    .SYNOPSIS
        Creates a new resource body object

    .DESCRIPTION
        The New-AutoTaskBody cmdlet creates a new resource body
        for the AutoTask API

        Helpful when working with resource queries, modifications,
        and creating filters for advanced searches

    .PARAMETER Empty
        Creates a new resource body with no content

    .EXAMPLE
        New-AutoTaskBody -Resource ContactGroups

        Creates a template showing all available fields with their types and picklist values

    .EXAMPLE
        New-AutoTaskBody -Resource Companies -Empty

        Creates a new resource body for the company with no content

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Resource/New-AutoTaskBody.html
#>

    [CmdletBinding(DefaultParameterSetName = 'Empty', SupportsShouldProcess = $true, ConfirmImpact = 'None')]
    Param(
        [Parameter(Mandatory = $false, ParameterSetName = 'Empty')]
        [switch]$Empty
    )

    DynamicParam {
        $AutoTaskModulePostPatchParameter
    }

    begin {

        $FunctionName   = $MyInvocation.InvocationName
        $ResourceTarget = $PSBoundParameters.Resource

    }
    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        $ResourceURI = ($AutoTaskModuleQueries | Where-Object { $_.Post -eq $ResourceTarget } | Select-Object -First 1).Name -replace '/query$', ''
        if (-not $ResourceURI) {
            $ResourceURI = ($AutoTaskModuleQueries | Where-Object { $_.Patch -eq $ResourceTarget } | Select-Object -First 1).Name -replace '/query$', ''
        }

        $TargetURI = "$ResourceURI/entityInformation"
        try {


            $ObjectTemplate = (Invoke-AutoTaskRequest -Method GET -ResourceURI "$TargetURI/fields").fields
            try {
                $UDFs = (Invoke-AutoTaskRequest -Method GET -ResourceURI "$TargetURI/userDefinedFields").fields | Select-Object Name,Value
            }
            catch {
                if ( $_.Exception.Response.StatusCode -ne "NotFound" ) { throw }
            }

            if (-not $ObjectTemplate) { Write-Warning "Could not retrieve entityInformation for [ $ResourceTarget ]" }
            else {

                $OutputResults  = [System.Collections.Generic.List[object]]::new()
                $Properties     = [ordered]@{}

                if ($Empty) {
                    foreach ($Property in $ObjectTemplate | Where-Object { -not $_.IsReadOnly }) {
                        $Properties[$Property.Name] = $null
                    }
                    $OutputResults.Add([PSCustomObject]$Properties)
                }
                else {
                    foreach ($Property in $ObjectTemplate) {
                        $FieldMetadata = [PSCustomObject]@{
                            Name           = $Property.Name
                            DataType       = $Property.DataType
                            Length         = $Property.Length
                            IsReadOnly     = $Property.IsReadOnly
                            IsRequired     = $Property.IsRequired
                            PickListValues = if ($Property.PickListValues) {
                                $Property.PickListValues | Select-Object Label,Value,IsActive
                            } else { $null }
                        }
                        $OutputResults.Add($FieldMetadata)
                    }

                    if ($UDFs) {
                        $UDFMetadata = [PSCustomObject]@{
                            Name           = "userDefinedFields"
                            DataType       = "object[]"
                            IsReadOnly     = $false
                            IsRequired     = $false
                            PickListValues = $UDFs
                        }
                        $OutputResults.Add($UDFMetadata)
                    }
                }

            }

            if ($PSCmdlet.ShouldProcess($TargetURI)) {
                return $OutputResults
            }

        }
        catch {
            Write-Error $_
        }

    }
}
#EndRegion '.\Public\New-AutoTaskBody.ps1' 122
#Region '.\Public\New-AutoTaskResource.ps1' -1

function New-AutoTaskResource {
<#
    .SYNOPSIS
        Creates a new resource

    .DESCRIPTION
        The New-AutoTaskResource cmdlet creates a new resource
        in the AutoTask API

    .PARAMETER ParentId
        The parent resource ID to use when creating a child resource

    .PARAMETER Data
        The data body to use when creating the resource

    .EXAMPLE
        New-AutoTaskResource -Resource Companies -Data $data

        Creates a new resource for the company with the specified data body

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Resource/New-AutoTaskResource.html
#>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    Param(
        [Parameter(Mandatory = $false)]
        [String]$ParentId,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        $Data
    )

    DynamicParam {
        $AutoTaskModulePostParameter
    }

    begin {

        $FunctionName   = $MyInvocation.InvocationName
        $ParameterName  = $FunctionName + '_Parameters' -replace '-','_'

        $ResourceTarget = $PSBoundParameters.Resource
        $ResourceUri    = ($AutoTaskModuleQueries | Where-Object { $_.Post -eq $ResourceTarget } | Select-Object -First 1).Name -replace '/query$', ''

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        if ($ResourceTarget -like "*child*") {
            if (-not $ParentId ) {
                Write-Error "You must specify a parentId when creating a child resource"
                break
            }
            $ResourceUri = $ResourceUri -replace '{parentId}', $ParentId
        }

        $InvokeParams = @{
            Method      = 'POST'
            ResourceURI = $ResourceUri
            Data        = $Data
        }

        Set-Variable -Name $ParameterName -Value $InvokeParams -Scope Global -Force -Confirm:$false

        if ($PSCmdlet.ShouldProcess($ResourceUri)) {
            return Invoke-AutoTaskRequest @InvokeParams
        }

    }
}
#EndRegion '.\Public\New-AutoTaskResource.ps1' 78
#Region '.\Public\Remove-AutoTaskResource.ps1' -1

function Remove-AutoTaskResource {
<#
    .SYNOPSIS
        Deletes a resource

    .DESCRIPTION
        The Remove-AutoTaskResource cmdlet deletes a resource
        in the AutoTask API

    .PARAMETER ID
        The ID of the resource to delete

    .PARAMETER ChildID
        The ID of the child resource to delete

    .EXAMPLE
        Remove-AutoTaskResource -Resource Companies -ID 123

        Deletes the company resource with the specified ID

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Resource/Remove-AutoTaskResource.html
#>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [int64]$ID,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [int64]$ChildID
    )

    DynamicParam {
        $AutoTaskModuleDeleteParameter
    }

    begin {

        $FunctionName   = $MyInvocation.InvocationName
        $ParameterName  = $functionName + '_Parameters'      -replace '-','_'

        $ResourceTarget = $PSBoundParameters.Resource
        $ResourceUri    = ($AutoTaskModuleQueries | Where-Object { $_.Delete -eq $ResourceTarget } | Select-Object -First 1).Name -replace '/query$', '/{PARENTID}'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        if (-not $ChildID -and $ResourceTarget -like "*Child*") {
            Write-Warning "You must enter a ChildID to delete a Child resource"
            break
        }

        $ResourceUri = $ResourceUri -replace '{PARENTID}', $ID

        if ($ID)        { $ResourceUri = $ResourceUri -replace '{ID}', $ID }
        if ($ChildID)   { $ResourceUri = $ResourceUri -replace '{ID}', $ChildID }

        $InvokeParams = @{
            Method      = 'DELETE'
            ResourceURI = $ResourceUri
        }

        Set-Variable -Name $ParameterName -Value $InvokeParams -Scope Global -Force -Confirm:$false

        if ($PSCmdlet.ShouldProcess($ResourceUri)) {
            return Invoke-AutoTaskRequest @InvokeParams
        }


    }
}
#EndRegion '.\Public\Remove-AutoTaskResource.ps1' 79
#Region '.\Public\Set-AutoTaskResource.ps1' -1

function Set-AutoTaskResource {
<#
    .SYNOPSIS
        Updates a resource

    .DESCRIPTION
        The Set-AutoTaskResource cmdlet updates a resource
        in the AutoTask API

    .PARAMETER ParentID
        The ID of the parent resource to update

    .PARAMETER ID
        The ID of the resource to update

    .PARAMETER Data
        The data body to use when updating the resource

    .EXAMPLE
        Set-AutoTaskResource -Resource Companies -ID 123 -Data $data

        Updates the company resource with the specified ID

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Resource/Set-AutoTaskResource.html
#>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    Param(
        [Parameter(ParameterSetName = 'ParentID', Mandatory = $false)]
        [int64]$ParentId,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [int64]$ID,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        $Data
    )

    DynamicParam {
        $AutoTaskModulePatchParameter
    }

    begin {

        $FunctionName   = $MyInvocation.InvocationName
        $ParameterName  = $functionName + '_Parameters'      -replace '-','_'

        $ResourceTarget = $PSBoundParameters.Resource
        $ResourceUri    = ($AutoTaskModuleQueries | Where-Object { $_.Patch -eq $ResourceTarget } | Select-Object -First 1).Name -replace '/query$', ''


    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        if ($ResourceTarget -like "*child*") {
            if (-not $ParentId) {
                Write-Warning "You must specify a parentId when setting a child resource"
                break
            }
            $ResourceUri = $ResourceUri -replace '{parentId}', $ParentId
        }

        $InvokeParams = @{
            Method      = 'PATCH'
            ResourceURI = $ResourceUri
            Data        = $Data
        }

        Set-Variable -Name $ParameterName -Value $InvokeParams -Scope Global -Force -Confirm:$false

        if ($PSCmdlet.ShouldProcess($ResourceUri)) {
            return Invoke-AutoTaskRequest @InvokeParams
        }

    }
}
#EndRegion '.\Public\Set-AutoTaskResource.ps1' 85
#Region '.\Public\Show-AutoTaskResource.ps1' -1

function Show-AutoTaskResource {
<#
    .SYNOPSIS
        Shows available values from the dynamically generated
        resource parameter

    .DESCRIPTION
        The Show-AutoTaskResource cmdlet shows available values
        from the dynamically generated resource parameter

        By default all available values are show

    .PARAMETER Name
        Defines the name of the resource to limit the output to

        This is a wildcard search and will return all resources
        that start with the provided value

    .PARAMETER Method
        Defines the type of API method to show available values for

        Allowed values:
        'GET', 'PUT', 'POST', 'PATCH', 'DELETE'

    .PARAMETER UniqueOnly
        Returns only unique resource names

    .PARAMETER JsonSpec
        Defines the path to the swagger json file to use when creating
        the dynamic parameter

    .EXAMPLE
        Show-AutoTaskResource

        Show all available values from the dynamically generated resource parameter

    .EXAMPLE
        Show-AutoTaskResource -Name Companies

        Shows available values on the Companies* resources

    .EXAMPLE
        Show-AutoTaskResource -Name Companies -Method GET

        Shows available values for the GET method on the Companies* resource

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/Celerium.AutoTask/site/Resource/Show-AutoTaskResource.html
#>

    [CmdletBinding(defaultParameterSetName = 'All')]
    Param(
        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet('GET', 'PUT', 'POST', 'PATCH', 'DELETE')]
        [String]$Method,

        [Parameter(Mandatory = $false, ParameterSetName = 'UniqueOnly')]
        [switch]$UniqueOnly,

        [Parameter(Mandatory = $false)]
        [string]$JsonSpec = $(Join-Path -Path "$($MyInvocation.MyCommand.Module.ModuleBase)" -ChildPath "AutoTaskAPI-2023.6.json")
    )


    begin {

        $FunctionName       = $MyInvocation.InvocationName
        $ParameterName      = $functionName + '_Parameters'      -replace '-','_'

    }

    process {

        Write-Verbose "[ $FunctionName ] - Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        if (-not $AutoTaskModuleSwagger) {
            $Swagger = Get-Content $JsonSpec -Raw | ConvertFrom-Json

            $Queries = foreach ($Path in $Swagger.Paths.PSObject.Properties) {
                [PSCustomObject]@{
                    Index  = $Path.Name.Split('/')[2]
                    Name   = $Path.Name
                    GET    = $Path.Value.GET.Tags
                    PUT    = $Path.Value.PUT.Tags
                    POST   = $Path.Value.POST.Tags
                    PATCH  = $Path.Value.PATCH.Tags
                    DELETE = $Path.Value.DELETE.Tags
                }
            }
        }
        else {
            $Queries = $AutoTaskModuleQueries
        }

        $ResourceList = foreach ($Type in 'GET','PUT','POST','PATCH','DELETE') {
            foreach ($Query in $Queries | Where-Object { $null -ne $_.$Type }) {
                [PSCustomObject]@{
                    Method   = $Type
                    Resource = $Query.$Type | Select-Object -Last 1
                    Path     = $Query.Name
                    Index    = $Query.Index
                }
            }
        }

        $ResourceList = $ResourceList | Sort-Object Resource,Method,Path

        if ($Name)      { $ResourceList = $ResourceList | Where-Object Resource -like "$Name*"}
        if ($Method)    { $ResourceList = $ResourceList | Where-Object Method -eq $Method }
        if ($UniqueOnly){ $ResourceList = $ResourceList | Select-Object -Property Resource -Unique }

        Set-Variable -Name $ParameterName -Value $PSBoundParameters -Scope Global -Force -Confirm:$false

        return $ResourceList

    }

}
#EndRegion '.\Public\Show-AutoTaskResource.ps1' 125
