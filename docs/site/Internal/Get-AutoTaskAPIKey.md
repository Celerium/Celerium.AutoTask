---
document type: cmdlet
external help file: Celerium.AutoTask-Help.xml
grand_parent: Internal
HelpUri: https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskAPIKey.html
Locale: en-US
Module Name: Celerium.AutoTask
parent: GET
PlatyPS schema version: 2024-05-01
title: Get-AutoTaskAPIKey
---

# Get-AutoTaskAPIKey

## SYNOPSIS

Gets the AutoTask API username, secret, & integration code

## SYNTAX

### Index (Default)

```
Get-AutoTaskAPIKey [-AsPlainText]
```

## ALIASES

This cmdlet has the following aliases,
  - None

## DESCRIPTION

The Get-AutoTaskAPIKey cmdlet gets the AutoTask API username, secret, & integration code
from the global variables and returns them as an object

By default the secret is returned as a SecureString

## EXAMPLES

### EXAMPLE 1

```powershell
Get-AutoTaskAPIKey
```

Gets the API values and returns them as an object with the secret as a SecureString

### EXAMPLE 2

```powershell
Get-AutoTaskAPIKey -AsPlainText
```

Gets the API values and returns them as an object with the secret as plain text

## PARAMETERS

### -AsPlainText

Decrypt and return the API secret in plain text

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

- [](https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskAPIKey.html)
