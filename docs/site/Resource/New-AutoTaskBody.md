---
external help file: Celerium.AutoTask-help.xml
grand_parent: Resource
Module Name: Celerium.AutoTask
online version: https://celerium.github.io/Celerium.AutoTask/site/Resource/New-AutoTaskBody.html
parent: PUT
schema: 2.0.0
title: New-AutoTaskBody
---

# New-AutoTaskBody

## SYNOPSIS
Creates a new resource body object

## SYNTAX

```powershell
New-AutoTaskBody [-Empty] [-WhatIf] [-Confirm] -Resource <String> [<CommonParameters>]
```

## DESCRIPTION
The New-AutoTaskBody cmdlet creates a new resource body
for the AutoTask API

Helpful when working with resource queries, modifications,
and creating filters for advanced searches

## EXAMPLES

### EXAMPLE 1
```powershell
New-AutoTaskBody -Resource ContactGroups
```

Creates a template showing all available fields with their types and picklist values

### EXAMPLE 2
```powershell
New-AutoTaskBody -Resource Companies -Empty
```

Creates a new resource body for the company with no content

## PARAMETERS

### -Empty
Creates a new resource body with no content

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

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Resource
{{ Fill Resource Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
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

[https://celerium.github.io/Celerium.AutoTask/site/Public/New-AutoTaskBody.html](https://celerium.github.io/Celerium.AutoTask/site/Public/New-AutoTaskBody.html)

