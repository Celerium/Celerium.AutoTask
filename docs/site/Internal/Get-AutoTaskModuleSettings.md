---
external help file: Celerium.AutoTask-help.xml
grand_parent: Internal
Module Name: Celerium.AutoTask
online version: https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskModuleSettings.html
parent: GET
schema: 2.0.0
title: Get-AutoTaskModuleSettings
---

# Get-AutoTaskModuleSettings

## SYNOPSIS
Gets the saved AutoTask configuration settings

## SYNTAX

```powershell
Get-AutoTaskModuleSettings [[-AutoTaskConfigPath] <String>] [[-AutoTaskConfigFile] <String>] [-OpenConfigFile]
 [<CommonParameters>]
```

## DESCRIPTION
The Get-AutoTaskModuleSettings cmdlet gets the saved AutoTask configuration settings
from the local system

By default the configuration file is stored in the following location:
    $env:USERPROFILE\Celerium.AutoTask

## EXAMPLES

### EXAMPLE 1
```powershell
Get-AutoTaskModuleSettings
```

Gets the contents of the configuration file that was created with the
Export-AutoTaskModuleSettings

The default location of the AutoTask configuration file is:
    $env:USERPROFILE\Celerium.AutoTask\config.psd1

### EXAMPLE 2
```powershell
Get-AutoTaskModuleSettings -AutoTaskConfigPath C:\Celerium.AutoTask -AutoTaskConfigFile MyConfig.psd1 -OpenConfFile
```

Opens the configuration file from the defined location in the default editor

The location of the AutoTask configuration file in this example is:
    C:\Celerium.AutoTask\MyConfig.psd1

## PARAMETERS

### -AutoTaskConfigPath
Define the location to store the AutoTask configuration file

By default the configuration file is stored in the following location:
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

### -AutoTaskConfigFile
Define the name of the AutoTask configuration file

By default the configuration file is named:
    config.psd1

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Config.psd1
Accept pipeline input: False
Accept wildcard characters: False
```

### -OpenConfigFile
Opens the AutoTask configuration file

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

[https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskModuleSettings.html](https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskModuleSettings.html)

