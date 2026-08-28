---
external help file: Celerium.AutoTask-help.xml
grand_parent: Internal
Module Name: Celerium.AutoTask
online version: https://celerium.github.io/Celerium.AutoTask/site/Internal/Add-AutoTaskBaseURI.html
parent: PUT
schema: 2.0.0
title: Add-AutoTaskBaseURI
---

# Add-AutoTaskBaseURI

## SYNOPSIS
Sets the base URI for the AutoTask API connection

## SYNTAX

### AutoDetect (Default)
```powershell
Add-AutoTaskBaseURI [-AutoDetect] [-Version <String>] [<CommonParameters>]
```

### CustomUri
```powershell
Add-AutoTaskBaseURI [-Version <String>] -BaseUri <String> [<CommonParameters>]
```

### Datacenter
```powershell
Add-AutoTaskBaseURI [-Version <String>] [-DataCenter <String>] [<CommonParameters>]
```

## DESCRIPTION
The Add-AutoTaskBaseURI cmdlet sets the base URI which is used
to construct the full URI for all API calls

## EXAMPLES

### EXAMPLE 1
```powershell
Add-AutoTaskBaseURI
```

Attempts to automatically detect the base URI for the AutoTask API connection

### EXAMPLE 2
```powershell
Add-AutoTaskBaseURI -BaseUri 'https://gateway.celerium.org'
```

The base URI will use https://gateway.celerium.org

### EXAMPLE 3
```powershell
Add-AutoTaskBaseURI -DataCenter 'America West 3'
```

The base URI will use https://webservices24.autotask.net/atservicesrest/v1.0

## PARAMETERS

### -AutoDetect
Attempts to automatically detect the base URI for the AutoTask API connection

```yaml
Type: SwitchParameter
Parameter Sets: AutoDetect
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Version
Defines the API version to use when constructing the full URI for all API calls

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $((Invoke-RestMethod -Uri "https://webservices2.autotask.net/atservicesrest/VersionInformation").apiVersions | Select-Object -Last 1)
Accept pipeline input: False
Accept wildcard characters: False
```

### -BaseUri
Sets the base URI for the AutoTask API connection.
Helpful
if using a custom API gateway or an undocumented AutoTask API endpoint

```yaml
Type: String
Parameter Sets: CustomUri
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -DataCenter
Defines the data center (platform) to use which in turn defines which
base API URL is used

https://ww24.autotask.net/DeveloperHelp/Content/APIs/General/API_Zones.htm

Allowed values are:
America East                    https://webservices3.autotask.net/atservicesrest
America East 2                  https://webservices14.autotask.net/atservicesrest
America East 3                  https://webservices22.autotask.net/atservicesrest
America West                    https://webservices5.autotask.net/atservicesrest
America West 2                  https://webservices15.autotask.net/atservicesrest
America West 3                  https://webservices24.autotask.net/atservicesrest
America West 4                  https://webservices25.autotask.net/atservicesrest
Australia / New Zealand         https://webservices6.autotask.net/atservicesrest
Australia 2                     https://webservices26.autotask.net/atservicesrest
Australia 3                     https://webservices29.autotask.net/atservicesrest
Deutsch German                  https://webservices18.autotask.net/atservicesrest
Deutsch Pre-Release             https://prde.autotask.net/atservicesrest
Español Pre-Release             https://pres.autotask.net/atservicesrest
Español Spanish                 https://webservices12.autotask.net/atservicesrest
EU1 (English Europe and Asia)   https://webservices19.autotask.net/atservicesrest
Limited Release                 https://webservices1.autotask.net/atservicesrest
Pre-release                     https://webservices2.autotask.net/atservicesrest
UK                              https://webservices4.autotask.net/atservicesrest
UK Limited Release              https://webservices17.autotask.net/atservicesrest
UK Pre-release                  https://webservices11.autotask.net/atservicesrest
UK2                             https://webservices16.autotask.net/atservicesrest
UK3                             https://webservices28.autotask.net/atservicesrest

```yaml
Type: String
Parameter Sets: Datacenter
Aliases: Platform

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

[https://celerium.github.io/Celerium.AutoTask/site/Internal/Add-AutoTaskBaseURI.html](https://celerium.github.io/Celerium.AutoTask/site/Internal/Add-AutoTaskBaseURI.html)

