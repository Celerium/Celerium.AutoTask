<#
    .SYNOPSIS
        Populates example data using the Celerium.AutoTask module

    .DESCRIPTION
        The Invoke-ExampleAutoTaskContactGroups script populates example
        data using the various methods available to an endpoint

        By default on the first run this script will create 5 new contact groups
        All subsequent runs will then update various fields of those contact groups

        Unless the -Verbose parameter is used, no output is displayed while the script runs

    .PARAMETER ApiIntegrationCode
        Defines the API integration code to use when making API calls to AutoTask

    .PARAMETER APIUsername
        Defines the username to use when making API calls to AutoTask

    .PARAMETER ApiSecret
        Defines the API secret to use when making API calls to AutoTask

    .PARAMETER RemoveExamples
        Defines if the example data should be deleted

    .PARAMETER RemoveExamplesConfirm
        Defines if the example data should be deleted only when prompted

    .PARAMETER ExamplesToMake
        Defines how many examples to make

    .EXAMPLE
        .\Invoke-ContactGroupsExample.ps1

        Checks for existing contact groups and either updates or creates new example contact groups

        API calls are made individually, so if 5 examples are made then 5 API calls are made

        No progress information is sent to the console while the script is running

    .EXAMPLE
        .\Invoke-ContactGroupsExample.ps1 -ApiIntegrationCode 'code' -APIUsername 'user' -ApiSecret 'secret' -RemoveExamples -RemoveExamplesConfirm -Verbose

        Checks for existing contact groups and either updates or creates new example contact groups, then
        it will prompt to delete all the contact groups

        Progress information is sent to the console while the script is running

    .NOTES
        N/A

    .INPUTS
        N/A

    .OUTPUTS
        Console

    .LINK
        https://webservices24.autotask.net/atservicesrest/swagger/ui/index#/ContactGroups

    .LINK
        https://github.com/Celerium/Celerium.AutoTask
#>

<############################################################################################
                                        Code
############################################################################################>
#Requires -Version 3.0
<# #Requires -Modules @{ ModuleName='Celerium.AutoTask'; ModuleVersion='1.0.0' } #>

#Region     [ Parameters ]

    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$ApiIntegrationCode,

        [Parameter()]
        [string]$APIUsername,

        [Parameter()]
        [string]$ApiSecret,

        [Parameter()]
        [switch]$RemoveExamples,

        [Parameter()]
        [switch]$RemoveExamplesConfirm,

        [Parameter()]
        [ValidateRange(1, 100)]
        [int64]$ExamplesToMake = 3

    )

#EndRegion  [ Parameters ]

    Write-Verbose ''
    Write-Verbose "START - $(Get-Date -Format yyyy-MM-dd-HH:mm) - Using the [ $($PSCmdlet.ParameterSetName) ] parameterSet"
    Write-Verbose ''
    Write-Verbose " - (0/4) - $(Get-Date -Format MM-dd-HH:mm) - Setting up prerequisites"

#Region     [ Prerequisites ]

    $FunctionName   = $MyInvocation.MyCommand.Name -replace '.ps1' -replace '-','_'
    $StepNumber     = 1
    $ExampleName    = 'ExampleContactGroup'

    Import-Module Celerium.AutoTask -Verbose:$false

    #Setting up AutoTask authentication
    try {

        if ($ApiIntegrationCode -and $APIUsername -and $ApiSecret) {
            Add-AutoTaskAPIKey -ApiIntegrationCode $ApiIntegrationCode -ApiUsername $APIUsername -ApiSecretKey $ApiSecret
        }
        else{

            $Auth = Get-AutoTaskAPIKey -AsPlainText -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            $Base = Get-AutoTaskBaseURI -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

            if ([bool]$Auth -eq $false -or (Test-AutoTaskAPIKey).StatusCode -ne '200' ) {
                Throw "The AutoTask API [ integration code, username, and secret ] are not correct. Run Add-AutoTaskAPIKey to set"
            }

        }

    }
    catch {
        Write-Error $_
        exit 1
    }

#EndRegion  [ Prerequisites ]

    Write-Verbose " - ($StepNumber/4) - $(Get-Date -Format MM-dd-HH:mm) - Find existing examples"
    $StepNumber++

#Region     [ Find Existing Data ]

    #Check if examples are present
    $CurrentContactGroups = Get-AutoTaskResource -Resource ContactGroups -SimpleSearch "name beginswith $ExampleName"
    if ($CurrentContactGroups) {
        Write-Verbose " -       - $(Get-Date -Format MM-dd-HH:mm) - Found [ $(($CurrentContactGroups| Measure-Object).Count) ] existing contact groups"
    }

#EndRegion  [ Find Existing Data ]

Write-Verbose " - ($StepNumber/4) - $(Get-Date -Format MM-dd-HH:mm) - Populate examples"
$StepNumber++

#Region     [ Example Code ]

    #Example values
    $ExampleNumber = 1

    #Stage array lists to store example data
    $NewContactGroupTemplate = New-AutoTaskBody -Resource ContactGroups -Empty

    #Loop to create example data
    while($ExampleNumber -le $ExamplesToMake) {

        $ExampleContactGroupName = "$ExampleName-$ExampleNumber"

        $ExistingContactGroup = $CurrentContactGroups | Where-Object {$_.name -eq $ExampleContactGroupName}
        $isActive = $true,$false | Get-Random

        if (-not $ExistingContactGroup) {

            Write-Verbose "Creating example Contact Group [ $ExampleContactGroupName ] that isActive [ $isActive ]"
            $NewContactObject            = $NewContactGroupTemplate

            $NewContactObject.isActive   = $isActive
            $NewContactObject.name       = $ExampleContactGroupName

            New-AutoTaskResource -Resource ContactGroups -Data $NewContactObject

        }
        else {

            Write-Verbose "Updating example Contact Group [ $ExampleContactGroupName ] that isActive [ $isActive ]"

            $ExistingContactGroup.isActive  = $isActive
            $ExistingContactGroup.name      = "$ExampleContactGroupName-Updated-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')"

            Set-AutoTaskResource -Resource ContactGroups -ID $ExistingContactGroup.id -Data $ExistingContactGroup

        }

        #Clear hashtable's for the next loop
        $ExistingContactGroup    = $null
        $NewContactObject        = $null

        $ExampleNumber++

    }
    #End of Loop

    #Check if examples are present
    $CurrentContactGroups = Get-AutoTaskResource -Resource ContactGroups -SimpleSearch "name beginswith $ExampleName"

#EndRegion  [ Example Code ]

#Region     [ Example Cleanup ]

    if ($RemoveExamples -and $CurrentContactGroups) {

        Write-Verbose " - ($StepNumber/4) - $(Get-Date -Format MM-dd-HH:mm) - Deleting examples"
        $StepNumber++

        if ($RemoveExamplesConfirm) { Read-Host "Press enter to delete [ $( ($CurrentContactGroups | Measure-Object).Count) ] contact groups" }

        foreach ($ContactGroup in $CurrentContactGroups) {
            Write-Verbose "Deleting contact group [ $($ContactGroup.name) ] with ID [ $($ContactGroup.id) ]"
            Remove-AutoTaskResource -Resource ContactGroups -ID $ContactGroup.id | Out-Null
        }

    }

    Write-Verbose " - ($StepNumber/4) - $(Get-Date -Format MM-dd-HH:mm) - Done"


#EndRegion  [ Example Cleanup ]

Write-Verbose ''
Write-Verbose "END - $(Get-Date -Format yyyy-MM-dd-HH:mm)"
Write-Verbose ''