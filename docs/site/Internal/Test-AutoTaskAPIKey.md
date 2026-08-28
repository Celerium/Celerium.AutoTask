---
external help file: Celerium.AutoTask-help.xml
grand_parent: Internal
Module Name: Celerium.AutoTask
online version: https://celerium.github.io/Celerium.AutoTask/site/Internal/Test-AutoTaskAPIKey.html
parent: GET
schema: 2.0.0
title: Test-AutoTaskAPIKey
---

# Test-AutoTaskAPIKey

## SYNOPSIS
Test the AutoTask API key

## SYNTAX

```powershell
Test-AutoTaskAPIKey [[-BaseUri] <String>] [<CommonParameters>]
```

## DESCRIPTION
The Test-AutoTaskAPIKey cmdlet tests the base URI & API key that
are defined in the Get-AutoTaskBaseURI & Get-AutoTaskAPIKey cmdlets

Helpful when needing to validate general functionality or when using
RMM deployment tools

## EXAMPLES

### EXAMPLE 1
```powershell
Test-AutoTaskAPIKey
```

Tests the base URI & API key that are defined in the
Get-AutoTaskBaseURI & Get-AutoTaskAPIKey cmdlets

### EXAMPLE 2
```powershell
Test-AutoTaskAPIKey -BaseUri http://myapi.gateway.celerium.org
```

Tests the defined base URI & API key that was defined in
the Get-AutoTaskAPIKey cmdlet

The full base uri test path in this example is:
    http://myapi.gateway.celerium.org/Companies/query

## PARAMETERS

### -BaseUri
Define the base URI for the AutoTask API connection
using AutoTask's URI or a custom URI

By default the value used is the one defined by the
Get-AutoTaskBaseURI function

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: $AutoTaskModuleBaseUriComplete
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
N/A

## RELATED LINKS

[https://celerium.github.io/Celerium.AutoTask/site/Internal/Test-AutoTaskAPIKey.html](https://celerium.github.io/Celerium.AutoTask/site/Internal/Test-AutoTaskAPIKey.html)

