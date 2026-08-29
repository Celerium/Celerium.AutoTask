---
external help file: Celerium.AutoTask-help.xml
grand_parent: Internal
Module Name: Celerium.AutoTask
online version: https://celerium.github.io/Celerium.AutoTask/site/Internal/Set-AutoTaskResourceDynamicParameter.html
parent: PUT
schema: 2.0.0
title: Set-AutoTaskResourceDynamicParameter
---

# Set-AutoTaskResourceDynamicParameter

## SYNOPSIS
Helper function for the New-AutoTaskResourceDynamicParameter

## SYNTAX

```powershell
Set-AutoTaskResourceDynamicParameter [[-JsonSpec] <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Set-AutoTaskResourceDynamicParameter cmdlet is a simple helper
function for the New-AutoTaskResourceDynamicParameter cmdlet that creates
a new dynamic parameter for either the resource list or definitions
list inside of swagger json

## EXAMPLES

### EXAMPLE 1
```powershell
Set-AutoTaskResourceDynamicParameter
```

Generates the dynamic parameter for either the resource list or definitions list
inside of swagger json

## PARAMETERS

### -JsonSpec
Defines the path to the swagger json file to use when creating the dynamic parameter

By default the value used is the one defined in the root of the module folder

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: $(Join-Path -Path "$($MyInvocation.MyCommand.Module.ModuleBase)" -ChildPath "AutoTaskAPI-2023.6.json")
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

[https://celerium.github.io/Celerium.AutoTask/site/Internal/Set-AutoTaskResourceDynamicParameter.html](https://celerium.github.io/Celerium.AutoTask/site/Internal/Set-AutoTaskResourceDynamicParameter.html)

[https://webservices24.autotask.net/atservicesrest/swagger/ui/index#](https://webservices24.autotask.net/atservicesrest/swagger/ui/index#)

