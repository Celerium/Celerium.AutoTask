---
document type: cmdlet
external help file: Celerium.AutoTask-Help.xml
grand_parent: Internal
HelpUri: https://celerium.github.io/Celerium.AutoTask/site/Internal/Complete-AutoTaskResource.html
Locale: en-US
Module Name: Celerium.AutoTask
parent: GET
PlatyPS schema version: 2024-05-01
title: Complete-AutoTaskResource
---

# Complete-AutoTaskResource

## SYNOPSIS

Tab-completes AutoTask resource & operation names

## SYNTAX

### __AllParameterSets

```
Complete-AutoTaskResource [[-CommandName] <string>] [[-ParameterName] <string>]
 [[-WordToComplete] <string>] [[-CommandAst] <Object>] [[-FakeBoundParameters] <IDictionary>]
```

## ALIASES

This cmdlet has the following aliases,
  - None

## DESCRIPTION

The Complete-AutoTaskResource cmdlet is the argument completer of the -Resource
& -Operation parameters of the public functions

Only the resources & operations that the calling function supports are returned,
such as the resources that can be deleted for Remove-AutoTaskResource

The values come from the resource map that is created from the AutoTask OpenAPI spec

## EXAMPLES

### EXAMPLE 1

```powershell
Complete-AutoTaskResource -CommandName Get-AutoTaskResource -ParameterName Resource -WordToComplete Compan
```

Returns the resources that start with Compan & that Get-AutoTaskResource supports

### EXAMPLE 2

```powershell
Complete-AutoTaskResource -CommandName Get-AutoTaskResource -ParameterName Operation -FakeBoundParameters @{ Resource = 'InvoiceMarkupApiIntegration' }
```

Returns the operations of the InvoiceMarkupApiIntegration resource that Get-AutoTaskResource supports

## PARAMETERS

### -CommandAst

The syntax tree of the command that is being completed

```yaml
Type: System.Object
DefaultValue: ''
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

### -CommandName

The name of the command that is being completed

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

### -FakeBoundParameters

The parameters that were already typed, used to find the resource when an operation is completed

```yaml
Type: System.Collections.IDictionary
DefaultValue: '@{}'
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 4
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ParameterName

The name of the parameter that is being completed, Resource or Operation

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

### -WordToComplete

The text that was typed so far

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.CompletionResult

{{ Fill in the Description }}

## NOTES

N/A


## RELATED LINKS

- [](https://celerium.github.io/Celerium.AutoTask/site/Internal/Complete-AutoTaskResource.html)
