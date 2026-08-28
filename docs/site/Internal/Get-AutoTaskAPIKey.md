---
external help file: Celerium.AutoTask-help.xml
grand_parent: Internal
Module Name: Celerium.AutoTask
online version: https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskAPIKey.html
parent: GET
schema: 2.0.0
title: Get-AutoTaskAPIKey
---

# Get-AutoTaskAPIKey

## SYNOPSIS
Gets the AutoTask API key

## SYNTAX

```powershell
Get-AutoTaskAPIKey [-AsPlainText] [<CommonParameters>]
```

## DESCRIPTION
The Get-AutoTaskAPIKey cmdlet gets the AutoTask API key from
the global variable and returns it as an object

## EXAMPLES

### EXAMPLE 1
```powershell
Get-AutoTaskAPIKey
```

Gets the Api keys and returns them as an object.
The
API secret key is returned as a secure string

### EXAMPLE 2
```powershell
Get-AutoTaskAPIKey -AsPlainText
```

Gets the Api keys and returns them as an object.
The
API secret key is returned as plain text

## PARAMETERS

### -AsPlainText
Decrypt and return the API key in plain text

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
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

[https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskAPIKey.html](https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskAPIKey.html)

