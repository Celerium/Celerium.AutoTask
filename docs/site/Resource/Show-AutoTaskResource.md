---
external help file: Celerium.AutoTask-help.xml
grand_parent: Resource
Module Name: Celerium.AutoTask
online version: https://celerium.github.io/Celerium.AutoTask/site/Resource/Show-AutoTaskResource.html
parent: GET
schema: 2.0.0
title: Show-AutoTaskResource
---

# Show-AutoTaskResource

## SYNOPSIS
Shows available values from the dynamically generated
resource parameter

## SYNTAX

### All (Default)
```powershell
Show-AutoTaskResource [-Name <String>] [-Method <String>] [-JsonSpec <String>] [<CommonParameters>]
```

### UniqueOnly
```powershell
Show-AutoTaskResource [-Name <String>] [-Method <String>] [-UniqueOnly] [-JsonSpec <String>]
 [<CommonParameters>]
```

## DESCRIPTION
The Show-AutoTaskResource cmdlet shows available values
from the dynamically generated resource parameter

By default all available values are show

## EXAMPLES

### EXAMPLE 1
```powershell
Show-AutoTaskResource
```

Show all available values from the dynamically generated resource parameter

### EXAMPLE 2
```powershell
Show-AutoTaskResource -Name Companies
```

Shows available values on the Companies* resources

### EXAMPLE 3
```powershell
Show-AutoTaskResource -Name Companies -Method GET
```

Shows available values for the GET method on the Companies* resource

## PARAMETERS

### -Name
Defines the name of the resource to limit the output to

This is a wildcard search and will return all resources
that start with the provided value

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Method
Defines the type of API method to show available values for

Allowed values:
'GET', 'PUT', 'POST', 'PATCH', 'DELETE'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UniqueOnly
Returns only unique resource names

```yaml
Type: SwitchParameter
Parameter Sets: UniqueOnly
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -JsonSpec
Defines the path to the swagger json file to use when creating
the dynamic parameter

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $(Join-Path -Path "$($MyInvocation.MyCommand.Module.ModuleBase)" -ChildPath "AutoTaskAPI-v1-2023.6.json")
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

[https://celerium.github.io/Celerium.AutoTask/site/Resource/Show-AutoTaskResource.html](https://celerium.github.io/Celerium.AutoTask/site/Resource/Show-AutoTaskResource.html)

