---
document type: cmdlet
external help file: Celerium.AutoTask-Help.xml
grand_parent: Internal
HelpUri: https://celerium.github.io/Celerium.AutoTask/site/Internal/Add-AutoTaskBaseURI.html
Locale: en-US
Module Name: Celerium.AutoTask
parent: PUT
PlatyPS schema version: 2024-05-01
title: Add-AutoTaskBaseURI
---

# Add-AutoTaskBaseURI

## SYNOPSIS

Sets the base URI for the AutoTask API connection

## SYNTAX

### AutoDetect (Default)

```
Add-AutoTaskBaseURI [-AutoDetect] [-Version <string>]
```

### CustomUri

```
Add-AutoTaskBaseURI [-BaseURI] <string> [-Version <string>]
```

### DataCenter

```
Add-AutoTaskBaseURI -DataCenter <string> [-Version <string>]
```

## ALIASES

This cmdlet has the following aliases,
  - Set-AutoTaskBaseURI

## DESCRIPTION

The Add-AutoTaskBaseURI cmdlet sets the base URI which is used
to construct the full URI for all API calls

The base URI is the zone url of the AutoTask API without the API version,
such as https://webservices24.autotask.net/atservicesrest

The API version such as /V1.0 is part of each resource path, a base URI
that ends with an API version is accepted & the version is removed

## EXAMPLES

### EXAMPLE 1

```powershell
Add-AutoTaskBaseURI
```

Detects the base URI of the API user that was set by Add-AutoTaskAPIKey

### EXAMPLE 2

```powershell
Add-AutoTaskBaseURI -BaseURI 'https://gateway.celerium.org'
```

The base URI will use https://gateway.celerium.org

### EXAMPLE 3

```powershell
Add-AutoTaskBaseURI -DataCenter 'America West 3'
```

The base URI will use https://webservices24.autotask.net/atservicesrest

## PARAMETERS

### -AutoDetect

Automatically detects the base URI (zone) of the AutoTask API user

The username set by Add-AutoTaskAPIKey is used to make a single unauthenticated
GET request to the AutoTask ZoneInformation endpoint

This is the default when no other parameter is used

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: AutoDetect
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -BaseURI

Sets the base URI for the AutoTask API connection.
Helpful
if using a custom API gateway or an undocumented AutoTask API endpoint

The URL must use https

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: CustomUri
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -DataCenter

Defines the data center (zone) to use which in turn defines which
base API URL is used

https://www.autotask.net/help/developerhelp/Content/APIs/General/API_Zones.htm

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
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Platform
ParameterSets:
- Name: DataCenter
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Version

Defines the API version that is stored with the base URI & used by -AutoDetect

Default value: V1.0

```yaml
Type: System.String
DefaultValue: V1.0
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

{{ Fill in the Description }}

## OUTPUTS

## NOTES

N/A


## RELATED LINKS

- [](https://celerium.github.io/Celerium.AutoTask/site/Internal/Add-AutoTaskBaseURI.html)
