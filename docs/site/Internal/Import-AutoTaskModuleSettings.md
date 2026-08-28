---
external help file: Celerium.AutoTask-help.xml
grand_parent: Internal
Module Name: Celerium.AutoTask
online version: https://celerium.github.io/Celerium.AutoTask/site/Internal/Import-AutoTaskModuleSettings.html
parent: PUT
schema: 2.0.0
title: Import-AutoTaskModuleSettings
---

# Import-AutoTaskModuleSettings

## SYNOPSIS
Imports the AutoTask BaseURI, API, & JSON configuration information to the current session

## SYNTAX

```powershell
Import-AutoTaskModuleSettings [[-AutoTaskConfigPath] <String>] [[-AutoTaskConfigFile] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
The Import-AutoTaskModuleSettings cmdlet imports the AutoTask BaseURI, API, & JSON configuration
information stored in the AutoTask configuration file to the users current session

By default the configuration file is stored in the following location:
    $env:USERPROFILE\Celerium.AutoTask

## EXAMPLES

### EXAMPLE 1
```powershell
Import-AutoTaskModuleSettings
```

Validates that the configuration file created with the Export-AutoTaskModuleSettings cmdlet exists
then imports the stored data into the current users session

The default location of the AutoTask configuration file is:
    $env:USERPROFILE\Celerium.AutoTask\config.psd1

### EXAMPLE 2
```powershell
Import-AutoTaskModuleSettings -AutoTaskConfigPath C:\Celerium.AutoTask -AutoTaskConfigFile MyConfig.psd1
```

Validates that the configuration file created with the Export-AutoTaskModuleSettings cmdlet exists
then imports the stored data into the current users session

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
N/A

## RELATED LINKS

[https://celerium.github.io/Celerium.AutoTask/site/Internal/Import-AutoTaskModuleSettings.html](https://celerium.github.io/Celerium.AutoTask/site/Internal/Import-AutoTaskModuleSettings.html)

