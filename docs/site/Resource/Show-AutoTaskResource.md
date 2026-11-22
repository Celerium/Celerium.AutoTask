---
document type: cmdlet
external help file: Celerium.AutoTask-Help.xml
grand_parent: Resource
HelpUri: https://celerium.github.io/Celerium.AutoTask/site/Resource/Show-AutoTaskResource.html
Locale: en-US
Module Name: Celerium.AutoTask
parent: GET
PlatyPS schema version: 2024-05-01
title: Show-AutoTaskResource
---

# Show-AutoTaskResource

## SYNOPSIS

Shows the available resources & operations of the AutoTask API

## SYNTAX

### All (Default)

```
Show-AutoTaskResource [[-Name] <string>] [-Method <string>] [-JsonSpec <string>]
```

### UniqueOnly

```
Show-AutoTaskResource [[-Name] <string>] [-Method <string>] [-UniqueOnly] [-JsonSpec <string>]
```

## ALIASES

This cmdlet has the following aliases,
  - None

## DESCRIPTION

The Show-AutoTaskResource cmdlet shows the resources & operations that can be
used with the -Resource & -Operation parameters of the public functions

By default all available values are shown.
The values come from the resource map
that is created from the AutoTask OpenAPI spec when the module is built

GET     -> Get-AutoTaskResource (POST Query & QueryCount operations as well)
POST    -> New-AutoTaskResource
PATCH   -> Set-AutoTaskResource (PUT operations as well)
DELETE  -> Remove-AutoTaskResource

## EXAMPLES

### EXAMPLE 1

```powershell
Show-AutoTaskResource
```

Show all available resources & operations

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

### -JsonSpec

Defines the path to an AutoTask OpenAPI (swagger) json file to read the
resources from instead of the resource map of the module

```yaml
Type: System.String
DefaultValue: ''
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

### -Method

Defines the type of API method to show available values for

Allowed values:
'GET', 'PUT', 'POST', 'PATCH', 'DELETE'

```yaml
Type: System.String
DefaultValue: ''
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

### -Name

Defines the name of the resource to limit the output to

This is a wildcard search and will return all resources
that start with the provided value

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -UniqueOnly

Returns only unique resource names

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: UniqueOnly
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

## OUTPUTS

## NOTES

N/A


## RELATED LINKS

- [](https://celerium.github.io/Celerium.AutoTask/site/Resource/Show-AutoTaskResource.html)
