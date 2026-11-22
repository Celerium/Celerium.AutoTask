---
document type: cmdlet
external help file: Celerium.AutoTask-Help.xml
grand_parent: Internal
HelpUri: https://celerium.github.io/Celerium.AutoTask/site/Internal/Remove-AutoTaskModuleSettings.html
Locale: en-US
Module Name: Celerium.AutoTask
parent: DELETE
PlatyPS schema version: 2024-05-01
title: Remove-AutoTaskModuleSettings
---

# Remove-AutoTaskModuleSettings

## SYNOPSIS

Removes the stored AutoTask configuration folder

## SYNTAX

### Destroy (Default)

```
Remove-AutoTaskModuleSettings [[-AutoTaskConfigPath] <string>] [-AndVariables] [-WhatIf] [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  - None

## DESCRIPTION

The Remove-AutoTaskModuleSettings cmdlet removes the AutoTask folder and its files
This cmdlet also has the option to remove sensitive AutoTask variables as well

By default configuration files are stored in the following location and will be removed:
    $env:USERPROFILE\Celerium.AutoTask

## EXAMPLES

### EXAMPLE 1

```powershell
Remove-AutoTaskModuleSettings
```

Checks to see if the default configuration folder exists and removes it if it does

The default location of the AutoTask configuration folder is:
    $env:USERPROFILE\Celerium.AutoTask

### EXAMPLE 2

```powershell
Remove-AutoTaskModuleSettings -AutoTaskConfigPath C:\Celerium.AutoTask -AndVariables
```

Checks to see if the defined configuration folder exists and removes it if it does
If sensitive AutoTask variables exist then they are removed as well

The location of the AutoTask configuration folder in this example is:
    C:\Celerium.AutoTask

## PARAMETERS

### -AndVariables

Define if sensitive AutoTask variables should be removed as well

By default the variables are not removed

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

### -AutoTaskConfigPath

Define the location of the AutoTask configuration folder

By default the configuration folder is located at:
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

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
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

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
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

- [](https://celerium.github.io/Celerium.AutoTask/site/Internal/Remove-AutoTaskModuleSettings.html)
