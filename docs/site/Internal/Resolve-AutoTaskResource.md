---
document type: cmdlet
external help file: Celerium.AutoTask-Help.xml
grand_parent: Internal
HelpUri: https://celerium.github.io/Celerium.AutoTask/site/Internal/Resolve-AutoTaskResource.html
Locale: en-US
Module Name: Celerium.AutoTask
parent: GET
PlatyPS schema version: 2024-05-01
title: Resolve-AutoTaskResource
---

# Resolve-AutoTaskResource

## SYNOPSIS

Resolves an AutoTask resource & operation to a request uri

## SYNTAX

### __AllParameterSets

```
Resolve-AutoTaskResource [-Resource] <string> [-Operation] <string> [[-CommandName] <string>]
 [[-PathValue] <Object[]>]
```

## ALIASES

This cmdlet has the following aliases,
  - None

## DESCRIPTION

The Resolve-AutoTaskResource cmdlet finds an operation of a resource in the resource map
and replaces the placeholders of its path, such as {parentId} & {id}, with the provided values

An error is thrown when the resource or the operation does not exist, when the public function
does not support the operation, or when the number of values does not match the placeholders

## EXAMPLES

### EXAMPLE 1

```powershell
Resolve-AutoTaskResource -Resource Companies -Operation QueryItem -PathValue 12345
```

Returns the GET method & the /V1.0/Companies/12345 resource uri

### EXAMPLE 2

```powershell
Resolve-AutoTaskResource -Resource CompanyAlertsChild -Operation QueryItem -PathValue 12345, 67
```

Returns the GET method & the /V1.0/Companies/12345/Alerts/67 resource uri

## PARAMETERS

### -CommandName

Defines the public function that makes the request, only the operations that the
function supports are allowed

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Operation

Defines the name of the operation, such as Query, QueryItem, CreateEntity, PatchEntity, or DeleteEntity

Show-AutoTaskResource lists the operations of every resource

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PathValue

Defines the values of the path placeholders in the order that they appear in the path

For a child resource the first value is the parent ID & the second value is the child ID

```yaml
Type: System.Object[]
DefaultValue: '@()'
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 3
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Resource

Defines the name of the resource, such as Companies or CompanyAlertsChild

The name is not case sensitive

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
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

- [](https://celerium.github.io/Celerium.AutoTask/site/Internal/Resolve-AutoTaskResource.html)
