---
external help file: Celerium.AutoTask-help.xml
grand_parent: Resource
Module Name: Celerium.AutoTask
online version: https://celerium.github.io/Celerium.AutoTask/site/Resource/New-AutoTaskResource.html
parent: POST
schema: 2.0.0
title: New-AutoTaskResource
---

# New-AutoTaskResource

## SYNOPSIS
Creates a new resource

## SYNTAX

```powershell
New-AutoTaskResource [[-ParentId] <String>] [-Data] <Object> [-WhatIf] [-Confirm] -Resource <String>
 [<CommonParameters>]
```

## DESCRIPTION
The New-AutoTaskResource cmdlet creates a new resource
in the AutoTask API

## EXAMPLES

### EXAMPLE 1
```powershell
New-AutoTaskResource -Resource Companies -Data $data
```

Creates a new resource for the company with the specified data body

## PARAMETERS

### -ParentId
The parent resource ID to use when creating a child resource

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Data
The data body to use when creating the resource

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByValue)
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

[https://celerium.github.io/Celerium.AutoTask/site/Resource/New-AutoTaskResource.html](https://celerium.github.io/Celerium.AutoTask/site/Resource/New-AutoTaskResource.html)

