---
external help file: Celerium.AutoTask-help.xml
grand_parent: Internal
Module Name: Celerium.AutoTask
online version: https://celerium.github.io/Celerium.AutoTask/site/Internal/Remove-AutoTaskModuleSettings.html
parent: DELETE
schema: 2.0.0
title: Remove-AutoTaskModuleSettings
---

# Remove-AutoTaskModuleSettings

## SYNOPSIS
Removes the stored AutoTask configuration folder

## SYNTAX

```powershell
Remove-AutoTaskModuleSettings [[-AutoTaskConfigPath] <String>] [-AndVariables] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
The Remove-AutoTaskModuleSettings cmdlet removes the AutoTask folder and its files
This cmdlet also has the option to remove sensitive AutoTask variables as well

By default configuration files are stored in the following location and will be removed:
    $env:USERPROFILE\Celerium.AutoTask

## EXAMPLES

### EXAMPLE 1
```powershell
Remove-AutoTaskModuleSettings
```

Checks to see if the default configuration folder exists and removes it if it does

The default location of the AutoTask configuration folder is:
    $env:USERPROFILE\Celerium.AutoTask

### EXAMPLE 2
```powershell
Remove-AutoTaskModuleSettings -AutoTaskConfigPath C:\Celerium.AutoTask -AndVariables
```

Checks to see if the defined configuration folder exists and removes it if it does
If sensitive AutoTask variables exist then they are removed as well

The location of the AutoTask configuration folder in this example is:
    C:\Celerium.AutoTask

## PARAMETERS

### -AutoTaskConfigPath
Define the location of the AutoTask configuration folder

By default the configuration folder is located at:
    $env:USERPROFILE\Celerium.AutoTask

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: $(Join-Path -Path $home -ChildPath $(if ($IsWindows -or $PSEdition -eq 'Desktop') {"Celerium.AutoTask"}else{".Celerium.AutoTask"}) )
Accept pipeline input: False
Accept wildcard characters: False
```

### -AndVariables
Define if sensitive AutoTask variables should be removed as well

By default the variables are not removed

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
N/A

## RELATED LINKS

[https://celerium.github.io/Celerium.AutoTask/site/Internal/Remove-AutoTaskModuleSettings.html](https://celerium.github.io/Celerium.AutoTask/site/Internal/Remove-AutoTaskModuleSettings.html)

