---
document type: cmdlet
external help file: Celerium.AutoTask-Help.xml
grand_parent: Resource
HelpUri: https://celerium.github.io/Celerium.AutoTask/site/Resource/Set-AutoTaskResource.html
Locale: en-US
Module Name: Celerium.AutoTask
parent: PATCH
PlatyPS schema version: 2024-05-01
title: Set-AutoTaskResource
---

# Set-AutoTaskResource

## SYNOPSIS

Updates a resource

## SYNTAX

### __AllParameterSets

```
Set-AutoTaskResource [-Resource] <string> -Data <Object> [-ParentId <long>] [-ID <long>]
 [-Operation <string>] [-WhatIf] [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  - None

## DESCRIPTION

The Set-AutoTaskResource cmdlet updates a resource
in the AutoTask API

By default a PATCH request is sent, which only changes the fields in the data body

This is a write request, it supports -WhatIf & asks for confirmation before the
request is sent (use -Confirm:$false to skip the confirmation).
Write requests are never retried

## EXAMPLES

### EXAMPLE 1

```powershell
Set-AutoTaskResource -Resource Companies -ID 123 -Data @{ phone = '555-555-5555' }
```

Updates the phone number of the company with ID 123 after asking for confirmation

### EXAMPLE 2

```powershell
Get-AutoTaskResource -Resource Companies -ID 123 | Set-AutoTaskResource -Resource Companies -WhatIf
```

Shows the update request of the company that was piped in without sending the request

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

The data body to use when updating the resource

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

### -ID

The ID of the resource to update

The ID is added to the data body as the id field, AutoTask finds the item to update by this field

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

### -Operation

Defines the operation of the resource to use, such as UpdateEntity (PUT) which replaces the item

By default the PatchEntity operation is used, Show-AutoTaskResource lists the operations

```yaml
Type: System.String
DefaultValue: PatchEntity
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

The ID of the parent resource when updating a child resource

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

Defines the name of the resource to update, such as Companies or CompanyNotesChild

Run Show-AutoTaskResource -Method PATCH to list the resources

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

### System.Object

{{ Fill in the Description }}

## OUTPUTS

## NOTES

N/A


## RELATED LINKS

- [](https://celerium.github.io/Celerium.AutoTask/site/Resource/Set-AutoTaskResource.html)
