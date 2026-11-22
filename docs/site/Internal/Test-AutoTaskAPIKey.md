---
document type: cmdlet
external help file: Celerium.AutoTask-Help.xml
grand_parent: Internal
HelpUri: https://celerium.github.io/Celerium.AutoTask/site/Internal/Test-AutoTaskAPIKey.html
Locale: en-US
Module Name: Celerium.AutoTask
parent: GET
PlatyPS schema version: 2024-05-01
title: Test-AutoTaskAPIKey
---

# Test-AutoTaskAPIKey

## SYNOPSIS

Test the AutoTask API username, secret, & integration code

## SYNTAX

### Test (Default)

```
Test-AutoTaskAPIKey [[-BaseURI] <string>]
```

## ALIASES

This cmdlet has the following aliases,
  - None

## DESCRIPTION

The Test-AutoTaskAPIKey cmdlet tests the base URI & API values that
are defined by the Add-AutoTaskBaseURI & Add-AutoTaskAPIKey cmdlets

Helpful when needing to validate general functionality or when using
RMM deployment tools

The test makes a single read-only GET query that only asks for the ID of one company

A 200 status code means the base URI & API values are valid.
A 401 status code means
the API values were not accepted & a 403 status code means the API user is not
allowed to read companies

## EXAMPLES

### EXAMPLE 1

```powershell
Test-AutoTaskAPIKey
```

Tests the base URI & API values that are defined by the
Add-AutoTaskBaseURI & Add-AutoTaskAPIKey cmdlets

### EXAMPLE 2

```powershell
Test-AutoTaskAPIKey -BaseURI https://myapi.gateway.celerium.org
```

Tests the defined base URI & the API values that were defined by
the Add-AutoTaskAPIKey cmdlet

The full test uri in this example is:
    https://myapi.gateway.celerium.org/V1.0/Companies/query?search=...

## PARAMETERS

### -BaseURI

Define the base URI for the AutoTask API connection
using AutoTask's URI or a custom URI

By default the value used is the one defined by the
Add-AutoTaskBaseURI function

```yaml
Type: System.String
DefaultValue: $AutoTaskModuleBaseUri
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

- [](https://celerium.github.io/Celerium.AutoTask/site/Internal/Test-AutoTaskAPIKey.html)
