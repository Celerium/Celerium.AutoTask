---
external help file: Celerium.AutoTask-help.xml
grand_parent: Resource
Module Name: Celerium.AutoTask
online version: https://celerium.github.io/Celerium.AutoTask/site/Resource/Remove-AutoTaskResource.html
parent: DELETE
schema: 2.0.0
title: Remove-AutoTaskResource
---

# Remove-AutoTaskResource

## SYNOPSIS
Deletes a resource

## SYNTAX

```powershell
Remove-AutoTaskResource [-ID] <Int64> [[-ChildID] <Int64>] [-WhatIf] [-Confirm] -Resource <String>
 [<CommonParameters>]
```

## DESCRIPTION
The Remove-AutoTaskResource cmdlet deletes a resource
in the AutoTask API

## EXAMPLES

### EXAMPLE 1
```powershell
Remove-AutoTaskResource -Resource Companies -ID 123
```

Deletes the company resource with the specified ID

## PARAMETERS

### -ID
The ID of the resource to delete

```yaml
Type: Int64
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: 0
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ChildID
The ID of the child resource to delete

```yaml
Type: Int64
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 0
Accept pipeline input: True (ByPropertyName)
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

[https://celerium.github.io/Celerium.AutoTask/site/Public/Remove-AutoTaskResource.html](https://celerium.github.io/Celerium.AutoTask/site/Public/Remove-AutoTaskResource.html)

