---
external help file: Celerium.AutoTask-help.xml
grand_parent: Internal
Module Name: Celerium.AutoTask
online version: https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskBaseURI.html
parent: GET
schema: 2.0.0
title: Get-AutoTaskBaseURI
---

# Get-AutoTaskBaseURI

## SYNOPSIS
Shows the AutoTask base URI

## SYNTAX

```powershell
Get-AutoTaskBaseURI [-AndApiUri] [<CommonParameters>]
```

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

Shows the AutoTask base URI value with the default Api version uri defined in the global variable

## PARAMETERS

### -AndApiUri
Also include the default Api version uri

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

[https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskBaseURI.html](https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskBaseURI.html)

