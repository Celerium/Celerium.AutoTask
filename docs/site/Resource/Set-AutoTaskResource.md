---
external help file: Celerium.AutoTask-help.xml
grand_parent: Resource
Module Name: Celerium.AutoTask
online version: https://celerium.github.io/Celerium.AutoTask/site/Resource/Set-AutoTaskResource.html
parent: PATCH
schema: 2.0.0
title: Set-AutoTaskResource
---

# Set-AutoTaskResource

## SYNOPSIS
Updates a resource

## SYNTAX

```powershell
Set-AutoTaskResource [-ParentId <Int64>] [-ID <Int64>] -Data <Object> [-WhatIf] [-Confirm] -Resource <String>
 [<CommonParameters>]
```

## DESCRIPTION
The Set-AutoTaskResource cmdlet updates a resource
in the AutoTask API

## EXAMPLES

### EXAMPLE 1
```powershell
Set-AutoTaskResource -Resource Companies -ID 123 -Data $data
```

Updates the company resource with the specified ID

## PARAMETERS

### -ParentId
The ID of the parent resource to update

```yaml
Type: Int64
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ID
The ID of the resource to update

```yaml
Type: Int64
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Data
The data body to use when updating the resource

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
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

[https://celerium.github.io/Celerium.AutoTask/site/Resource/Set-AutoTaskResource.html](https://celerium.github.io/Celerium.AutoTask/site/Resource/Set-AutoTaskResource.html)

