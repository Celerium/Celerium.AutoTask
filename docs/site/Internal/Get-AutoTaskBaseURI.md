---
document type: cmdlet
external help file: Celerium.AutoTask-Help.xml
grand_parent: Internal
HelpUri: https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskBaseURI.html
Locale: en-US
Module Name: Celerium.AutoTask
parent: GET
PlatyPS schema version: 2024-05-01
title: Get-AutoTaskBaseURI
---

# Get-AutoTaskBaseURI

## SYNOPSIS

Shows the AutoTask base URI

## SYNTAX

### Index (Default)

```
Get-AutoTaskBaseURI [-AndApiUri]
```

## ALIASES

This cmdlet has the following aliases,
  - None

## DESCRIPTION

The Get-AutoTaskBaseURI cmdlet shows the AutoTask base URI from
the global variable

## EXAMPLES

### EXAMPLE 1

```powershell
Get-AutoTaskBaseURI
```

Shows the AutoTask base URI value defined in the global variable

### EXAMPLE 2

```powershell
Get-AutoTaskBaseURI -AndApiUri
```

Shows the AutoTask base URI value with the API version uri defined in the global variable

## PARAMETERS

### -AndApiUri

Also include the API version uri, such as /V1.0

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

- [](https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskBaseURI.html)
