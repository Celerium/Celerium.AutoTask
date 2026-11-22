---
document type: cmdlet
external help file: Celerium.AutoTask-Help.xml
grand_parent: Internal
HelpUri: https://celerium.github.io/Celerium.AutoTask/site/Internal/Export-AutoTaskModuleSettings.html
Locale: en-US
Module Name: Celerium.AutoTask
parent: PUT
PlatyPS schema version: 2024-05-01
title: Export-AutoTaskModuleSettings
---

# Export-AutoTaskModuleSettings

## SYNOPSIS

Exports the AutoTask BaseURI, API, & JSON configuration information to file

## SYNTAX

### Set (Default)

```
Export-AutoTaskModuleSettings [[-AutoTaskConfigPath] <string>] [[-AutoTaskConfigFile] <string>]
```

## ALIASES

This cmdlet has the following aliases,
  - None

## DESCRIPTION

The Export-AutoTaskModuleSettings cmdlet exports the AutoTask BaseURI, API, & JSON configuration information to file

Making use of PowerShell's System.Security.SecureString type, exporting module settings encrypts your API secret &
integration code in a format that can only be unencrypted with the your Windows account as this encryption is tied
to your user principal.
This means that you cannot copy your configuration file to another computer or user account
and expect it to work

On Linux & macOS the SecureString is NOT encrypted, it is recommended to use the AUTOTASK_BASE_URI,
AUTOTASK_API_USERNAME, AUTOTASK_API_SECRET, & AUTOTASK_API_INTEGRATION_CODE environment variables
or a secret store instead

## EXAMPLES

### EXAMPLE 1

```powershell
Export-AutoTaskModuleSettings
```

Validates that the BaseURI, API, and JSON depth are set then exports their values
to the current user's AutoTask configuration file located at:
    $env:USERPROFILE\Celerium.AutoTask\config.psd1

### EXAMPLE 2

```powershell
Export-AutoTaskModuleSettings -AutoTaskConfigPath C:\Celerium.AutoTask -AutoTaskConfigFile MyConfig.psd1
```

Validates that the BaseURI, API, and JSON depth are set then exports their values
to the current user's AutoTask configuration file located at:
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

- [](https://celerium.github.io/Celerium.AutoTask/site/Internal/Export-AutoTaskModuleSettings.html)
