---
external help file: Celerium.AutoTask-help.xml
grand_parent: Internal
Module Name: Celerium.AutoTask
online version: https://celerium.github.io/Celerium.AutoTask/site/Internal/New-AutoTaskResourceDynamicParameter.html
parent: PUT
schema: 2.0.0
title: New-AutoTaskResourceDynamicParameter
---

# New-AutoTaskResourceDynamicParameter

## SYNOPSIS
Creates a new AutoTask resource dynamic parameter

## SYNTAX

```powershell
New-AutoTaskResourceDynamicParameter [-ParameterType] <String> [[-JsonSpec] <String>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
The New-AutoTaskResourceDynamicParameter cmdlet creates a new dynamic parameter
for either the resource list or definitions list inside of swagger json
by opening the file, reading the contents and converting a custom object

## EXAMPLES

### EXAMPLE 1
```powershell
New-AutoTaskResourceDynamicParameter
```

You will be prompted to select a parameter type and resource

## PARAMETERS

### -ParameterType
Defines the type of resource or definition to use when creating the dynamic parameter

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -JsonSpec
Defines the path to the swagger json file to use when creating the dynamic parameter

By default the value used is the one defined in the root of the module folder

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
N/A

## RELATED LINKS

[https://celerium.github.io/Celerium.AutoTask/site/Internal/New-AutoTaskResourceDynamicParameter.html](https://celerium.github.io/Celerium.AutoTask/site/Internal/New-AutoTaskResourceDynamicParameter.html)

[https://webservices24.autotask.net/atservicesrest/swagger/ui/index#](https://webservices24.autotask.net/atservicesrest/swagger/ui/index#)

