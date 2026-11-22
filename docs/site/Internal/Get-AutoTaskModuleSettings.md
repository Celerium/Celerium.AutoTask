---
document type: cmdlet
external help file: Celerium.AutoTask-Help.xml
grand_parent: Internal
HelpUri: https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskModuleSettings.html
Locale: en-US
Module Name: Celerium.AutoTask
parent: GET
PlatyPS schema version: 2024-05-01
title: Get-AutoTaskModuleSettings
---

# Get-AutoTaskModuleSettings

## SYNOPSIS

Gets the saved AutoTask configuration settings

## SYNTAX

### Index (Default)

```
Get-AutoTaskModuleSettings [[-AutoTaskConfigPath] <string>] [[-AutoTaskConfigFile] <string>]
 [-OpenConfigFile]
```

## ALIASES

This cmdlet has the following aliases,
  - None

## DESCRIPTION

The Get-AutoTaskModuleSettings cmdlet gets the saved AutoTask configuration settings
from the local system

By default the configuration file is stored in the following location:
    $env:USERPROFILE\Celerium.AutoTask

## EXAMPLES

### EXAMPLE 1

```powershell
Get-AutoTaskModuleSettings
```

Gets the contents of the configuration file that was created with the
Export-AutoTaskModuleSettings

The default location of the AutoTask configuration file is:
    $env:USERPROFILE\Celerium.AutoTask\config.psd1

### EXAMPLE 2

```powershell
Get-AutoTaskModuleSettings -AutoTaskConfigPath C:\Celerium.AutoTask -AutoTaskConfigFile MyConfig.psd1 -OpenConfigFile
```

Opens the configuration file from the defined location in the default editor

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

### -OpenConfigFile

Opens the AutoTask configuration file

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
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

- [](https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskModuleSettings.html)
