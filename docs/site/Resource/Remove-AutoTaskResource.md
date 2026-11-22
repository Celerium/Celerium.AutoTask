---
document type: cmdlet
external help file: Celerium.AutoTask-Help.xml
grand_parent: Resource
HelpUri: https://celerium.github.io/Celerium.AutoTask/site/Resource/Remove-AutoTaskResource.html
Locale: en-US
Module Name: Celerium.AutoTask
parent: DELETE
PlatyPS schema version: 2024-05-01
title: Remove-AutoTaskResource
---

# Remove-AutoTaskResource

## SYNOPSIS

Deletes a resource

## SYNTAX

### __AllParameterSets

```
Remove-AutoTaskResource [-Resource] <string> -ID <long> [-ChildID <long>] [-Operation <string>]
 [-WhatIf] [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  - None

## DESCRIPTION

The Remove-AutoTaskResource cmdlet deletes a resource
in the AutoTask API

For a child resource, such as CompanyNotesChild, the -ID parameter is the ID of the
parent resource & the -ChildID parameter is the ID of the child resource to delete

This is a write request, it supports -WhatIf & asks for confirmation before the
request is sent (use -Confirm:$false to skip the confirmation).
Write requests are never retried

## EXAMPLES

### EXAMPLE 1

```powershell
Remove-AutoTaskResource -Resource ActionTypes -ID 123
```

Deletes the action type with the specified ID after asking for confirmation

### EXAMPLE 2

```powershell
Remove-AutoTaskResource -Resource CompanyToDosChild -ID 8765309 -ChildID 123 -WhatIf
```

Shows the delete request of the to-do with ID 123 of the company with ID 8765309 without sending the request

## PARAMETERS

### -ChildID

The ID of the child resource to delete

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
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

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

### -ID

The ID of the resource to delete

For a child resource this is the ID of the parent resource

```yaml
Type: System.Int64
DefaultValue: 0
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Operation

Defines the operation of the resource to use, such as DeleteContactRecipient

By default the DeleteEntity operation is used, Show-AutoTaskResource lists the operations

```yaml
Type: System.String
DefaultValue: DeleteEntity
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

Defines the name of the resource to delete, such as Companies or CompanyNotesChild

Run Show-AutoTaskResource -Method DELETE to list the resources

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

### System.Int64

{{ Fill in the Description }}

## OUTPUTS

## NOTES

N/A


## RELATED LINKS

- [](https://celerium.github.io/Celerium.AutoTask/site/Resource/Remove-AutoTaskResource.html)
