---
document type: cmdlet
external help file: Celerium.AutoTask-Help.xml
grand_parent: Internal
HelpUri: https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskSpecOperation.html
Locale: en-US
Module Name: Celerium.AutoTask
parent: GET
PlatyPS schema version: 2024-05-01
title: Get-AutoTaskSpecOperation
---

# Get-AutoTaskSpecOperation

## SYNOPSIS

Gets every operation from an AutoTask OpenAPI (swagger) spec

## SYNTAX

### File (Default)

```
Get-AutoTaskSpecOperation -JsonSpec <string>
```

### Object

```
Get-AutoTaskSpecOperation -Spec <psobject>
```

## ALIASES

This cmdlet has the following aliases,
  - None

## DESCRIPTION

The Get-AutoTaskSpecOperation cmdlet reads an AutoTask OpenAPI (swagger) spec
and returns one object per operation (HTTP method & path)

The resource is the tag of the operation, such as Companies or CompanyAlertsChild,
and the operation is the part of the operationId after the resource name, such as
Query, QueryItem, CreateEntity, PatchEntity, or DeleteEntity

This function is used by the build\New-AutoTaskResourceMap.ps1 script to create
the resource map of the module & by Show-AutoTaskResource -JsonSpec

## EXAMPLES

### EXAMPLE 1

```powershell
Get-AutoTaskSpecOperation -JsonSpec .\Celerium.AutoTask\AutoTaskAPI-2023.6.json
```

Returns every operation of the spec

### EXAMPLE 2

```powershell
Get-AutoTaskSpecOperation -JsonSpec .\AutoTaskAPI-2023.6.json | Where-Object { $_.Resource -eq 'Companies' }
```

Returns the operations of the Companies resource

## PARAMETERS

### -JsonSpec

Defines the path to the AutoTask OpenAPI (swagger) json file

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: File
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Spec

Defines an AutoTask OpenAPI (swagger) spec that was already converted from JSON

```yaml
Type: System.Management.Automation.PSObject
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Object
  Position: Named
  IsRequired: true
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

### System.Management.Automation.PSObject

{{ Fill in the Description }}

## NOTES

N/A


## RELATED LINKS

- [](https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskSpecOperation.html)
