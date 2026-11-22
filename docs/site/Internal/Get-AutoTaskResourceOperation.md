---
document type: cmdlet
external help file: Celerium.AutoTask-Help.xml
grand_parent: Internal
HelpUri: https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskResourceOperation.html
Locale: en-US
Module Name: Celerium.AutoTask
parent: GET
PlatyPS schema version: 2024-05-01
title: Get-AutoTaskResourceOperation
---

# Get-AutoTaskResourceOperation

## SYNOPSIS

Gets the operations of an AutoTask resource

## SYNTAX

### __AllParameterSets

```
Get-AutoTaskResourceOperation [[-Resource] <string>] [[-CommandName] <string>]
```

## ALIASES

This cmdlet has the following aliases,
  - None

## DESCRIPTION

The Get-AutoTaskResourceOperation cmdlet returns the operations from the resource map
and can limit them to one resource and to the operations that a public function supports

Every operation of the AutoTask API is supported by one of the public functions:

    Get-AutoTaskResource    - GET operations & the POST query & count operations
    New-AutoTaskBody        - The QueryFieldDefinitions operation
    New-AutoTaskResource    - The CreateEntity operation & the other POST operations
    Set-AutoTaskResource    - The PATCH & PUT operations
    Remove-AutoTaskResource - The DELETE operations

## EXAMPLES

### EXAMPLE 1

```powershell
Get-AutoTaskResourceOperation -Resource Companies
```

Returns every operation of the Companies resource

### EXAMPLE 2

```powershell
Get-AutoTaskResourceOperation -CommandName Remove-AutoTaskResource
```

Returns every operation that the Remove-AutoTaskResource function supports

## PARAMETERS

### -CommandName

Defines the public function to return the supported operations of

Allowed values:
    'Get-AutoTaskResource', 'New-AutoTaskBody', 'New-AutoTaskResource',
    'Set-AutoTaskResource', 'Remove-AutoTaskResource'

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Resource

Defines the name of the resource to return the operations of, such as Companies

The name is not case sensitive

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

- [](https://celerium.github.io/Celerium.AutoTask/site/Internal/Get-AutoTaskResourceOperation.html)
