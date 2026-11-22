---
document type: cmdlet
external help file: Celerium.AutoTask-Help.xml
grand_parent: Internal
HelpUri: https://celerium.github.io/Celerium.AutoTask/site/Internal/Import-AutoTaskModuleSettings.html
Locale: en-US
Module Name: Celerium.AutoTask
parent: PUT
PlatyPS schema version: 2024-05-01
title: Import-AutoTaskModuleSettings
---

# Import-AutoTaskModuleSettings

## SYNOPSIS

Imports the AutoTask BaseURI, API, & JSON configuration information to the current session

## SYNTAX

### Set (Default)

```
Import-AutoTaskModuleSettings [[-AutoTaskConfigPath] <string>] [[-AutoTaskConfigFile] <string>]
```

## ALIASES

This cmdlet has the following aliases,
  - None

## DESCRIPTION

The Import-AutoTaskModuleSettings cmdlet imports the AutoTask BaseURI, API, & JSON configuration
information stored in the AutoTask configuration file to the users current session

By default the configuration file is stored in the following location:
    $env:USERPROFILE\Celerium.AutoTask

The AUTOTASK_BASE_URI, AUTOTASK_API_USERNAME, AUTOTASK_API_SECRET, & AUTOTASK_API_INTEGRATION_CODE
environment variables are also supported and take precedence over the values stored in the
configuration file

## EXAMPLES

### EXAMPLE 1

```powershell
Import-AutoTaskModuleSettings
```

Validates that the configuration file created with the Export-AutoTaskModuleSettings cmdlet exists
then imports the stored data into the current users session

The default location of the AutoTask configuration file is:
    $env:USERPROFILE\Celerium.AutoTask\config.psd1

### EXAMPLE 2

```powershell
Import-AutoTaskModuleSettings -AutoTaskConfigPath C:\Celerium.AutoTask -AutoTaskConfigFile MyConfig.psd1
```

Validates that the configuration file created with the Export-AutoTaskModuleSettings cmdlet exists
then imports the stored data into the current users session

The location of the AutoTask configuration file in this example is:
    C:\Celerium.AutoTask\MyConfig.psd1

## PARAMETERS

### -AutoTaskConfigFile

Define the name of the AutoTask configuration file

By default the configuration file is named:
    config.psd1

```yaml
Type: System.String
DefaultValue: config.psd1
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -AutoTaskConfigPath

Define the location to store the AutoTask configuration file

By default the configuration file is stored in the following location:
    $env:USERPROFILE\Celerium.AutoTask

```yaml
Type: System.String
DefaultValue: $(Join-Path -Path $home -ChildPath $(if ($IsWindows -or $PSEdition -eq 'Desktop') {"Celerium.AutoTask"}else{".Celerium.AutoTask"}) )
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

N/A


## RELATED LINKS

- [](https://celerium.github.io/Celerium.AutoTask/site/Internal/Import-AutoTaskModuleSettings.html)
