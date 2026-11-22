---
document type: cmdlet
external help file: Celerium.AutoTask-Help.xml
grand_parent: Resource
HelpUri: https://celerium.github.io/Celerium.AutoTask/site/Resource/New-AutoTaskResource.html
Locale: en-US
Module Name: Celerium.AutoTask
parent: POST
PlatyPS schema version: 2024-05-01
title: New-AutoTaskResource
---

# New-AutoTaskResource

## SYNOPSIS

Creates a new resource

## SYNTAX

### __AllParameterSets

```
New-AutoTaskResource [-Resource] <string> -Data <Object> [-ParentId <long>] [-Operation <string>]
 [-WhatIf] [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  - None

## DESCRIPTION

The New-AutoTaskResource cmdlet creates a new resource
in the AutoTask API

This is a write request, it supports -WhatIf & asks for confirmation before the
request is sent (use -Confirm:$false to skip the confirmation).
Write requests are never retried

## EXAMPLES

### EXAMPLE 1

```powershell
New-AutoTaskResource -Resource Companies -Data $Data
```

Creates a new company with the specified data body after asking for confirmation

### EXAMPLE 2

```powershell
New-AutoTaskResource -Resource CompanyNotesChild -ParentId 8765309 -Data $Data -WhatIf
```

Shows the note that would be created for the company with ID 8765309 without sending the request

## PARAMETERS

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
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

### -Data

The data body to use when creating the resource

New-AutoTaskBody -Empty creates an object with every field of a resource

```yaml
Type: System.Object
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Operation

Defines the operation of the resource to use, such as AddContactRecipients

By default the CreateEntity operation is used, Show-AutoTaskResource lists the operations

```yaml
Type: System.String
DefaultValue: CreateEntity
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

### -ParentId

The parent resource ID to use when creating a child resource

```yaml
Type: System.Int64
DefaultValue: 0
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

### -Resource

Defines the name of the resource to create, such as Companies or CompanyNotesChild

Run Show-AutoTaskResource -Method POST to list the resources

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

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
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

### System.Object

{{ Fill in the Description }}

## OUTPUTS

## NOTES

N/A


## RELATED LINKS

- [](https://celerium.github.io/Celerium.AutoTask/site/Resource/New-AutoTaskResource.html)
