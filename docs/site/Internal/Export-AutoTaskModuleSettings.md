---
external help file: Celerium.AutoTask-help.xml
grand_parent: Internal
Module Name: Celerium.AutoTask
online version: https://celerium.github.io/Celerium.AutoTask/site/Internal/Export-AutoTaskModuleSettings.html
parent: PUT
schema: 2.0.0
title: Export-AutoTaskModuleSettings
---

# Export-AutoTaskModuleSettings

## SYNOPSIS
Exports the AutoTask BaseURI, API, & JSON configuration information to file

## SYNTAX

```powershell
Export-AutoTaskModuleSettings [[-AutoTaskConfigPath] <String>] [[-AutoTaskConfigFile] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
The Export-AutoTaskModuleSettings cmdlet exports the AutoTask BaseURI, API, & JSON configuration information to file

Making use of PowerShell's System.Security.SecureString type, exporting module settings encrypts your API key in a format
that can only be unencrypted with the your Windows account as this encryption is tied to your user principal
This means that you cannot copy your configuration file to another computer or user account and expect it to work

## EXAMPLES

### EXAMPLE 1
```powershell
Export-AutoTaskModuleSettings
```

Validates that the BaseURI, API, and JSON depth are set then exports their values
to the current user's AutoTask configuration file located at:
    $env:USERPROFILE\Celerium.AutoTask\config.psd1

### EXAMPLE 2
```powershell
Export-AutoTaskModuleSettings -AutoTaskConfigPath C:\Celerium.AutoTask -AutoTaskConfigFile MyConfig.psd1
```

Validates that the BaseURI, API, and JSON depth are set then exports their values
to the current user's AutoTask configuration file located at:
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

[https://celerium.github.io/Celerium.AutoTask/site/Internal/Export-AutoTaskModuleSettings.html](https://celerium.github.io/Celerium.AutoTask/site/Internal/Export-AutoTaskModuleSettings.html)

