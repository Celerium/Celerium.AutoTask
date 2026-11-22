---
document type: cmdlet
external help file: Celerium.AutoTask-Help.xml
grand_parent: Resource
HelpUri: https://celerium.github.io/Celerium.AutoTask/site/Resource/Get-AutoTaskResource.html
Locale: en-US
Module Name: Celerium.AutoTask
parent: GET
PlatyPS schema version: 2024-05-01
title: Get-AutoTaskResource
---

# Get-AutoTaskResource

## SYNOPSIS

Gets a resource

## SYNTAX

### Index (Default)

```
Get-AutoTaskResource [-Resource] <string> [-Operation <string>] [-AllResults] [-Raw]
```

### ID

```
Get-AutoTaskResource [-Resource] <string> -ID <long> [-ChildID <long>] [-Operation <string>] [-Raw]
```

### SimpleSearch

```
Get-AutoTaskResource [-Resource] <string> -SimpleSearch <string> [-Operation <string>] [-AllResults]
 [-Raw]
```

### AdvancedSearch

```
Get-AutoTaskResource [-Resource] <string> -AdvancedSearch <string> [-Method <string>]
 [-Operation <string>] [-AllResults] [-Raw]
```

## ALIASES

This cmdlet has the following aliases,
  - None

## DESCRIPTION

The Get-AutoTaskResource cmdlet gets a resource from the AutoTask API
by ID or by using a simple or advanced search query

Every resource of the AutoTask OpenAPI spec is supported, the -Resource parameter
tab-completes the resource names & Show-AutoTaskResource lists them

For a child resource, such as CompanyAlertsChild, the -ID parameter is the ID of the
parent resource & the -ChildID parameter is the ID of the child resource

Without -ID or a search query every item of the resource is queried, the first
500 items are returned unless -AllResults is used

## EXAMPLES

### EXAMPLE 1

```powershell
Get-AutoTaskResource -Resource Companies -ID 8765309
```

Get the company with ID 8765309

### EXAMPLE 2

```powershell
Get-AutoTaskResource -Resource Companies -SimpleSearch "isActive eq true"
```

Gets the first 500 active companies

### EXAMPLE 3

```powershell
Get-AutoTaskResource -Resource Companies -AdvancedSearch '{"MaxRecords":100,"filter":[{"op":"eq","field":"IsActive","value":true},{"op":"and","items":[{"op":"beginsWith","field":"companyName","value":"D"}]}]}'
```

Gets the first 100 active companies with a name starting with "D"

### EXAMPLE 4

```powershell
Get-AutoTaskResource -Resource CompanyAlertsChild -ID 8765309
```

Gets every alert of the company with ID 8765309

### EXAMPLE 5

```powershell
Get-AutoTaskResource -Resource Companies -SimpleSearch "isActive eq true" -Operation QueryCount
```

Gets the number of active companies

### EXAMPLE 6

```powershell
Get-AutoTaskResource -Resource ThresholdApiIntegration
```

Gets the API usage threshold information

## PARAMETERS

### -AdvancedSearch

Defines an advanced search query to use when getting the resource

'{
    "MaxRecords":100,
    "filter":[
        {"op":"eq","field":"IsActive","value":true},
        {"op":"and","items":[
            {"op":"beginsWith","field":"companyName","value":"D"}
        ]}
    ]
}'

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: AdvancedSearch
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -AllResults

Returns all items from an endpoint

By default only the first 500 items are returned

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: AdvancedSearch
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: SimpleSearch
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: Index
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ChildID

Defines the ID of the child resource to get

```yaml
Type: System.Int64
DefaultValue: 0
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ID
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

Defines the ID of the resource to get

For a child resource this is the ID of the parent resource, without -ChildID
every child item of the parent is returned

```yaml
Type: System.Int64
DefaultValue: 0
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ID
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Method

Defines the type of API method to use for an advanced search query

By default a GET request is used unless the request url would be longer
than 2048 characters, then a POST request is used

Allowed values:
'GET', 'POST'

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: AdvancedSearch
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Operation

Defines the operation of the resource to use, such as QueryCount, QueryFieldDefinitions,
or QueryInvoicePdf

By default the operation is selected from the other parameters.
Use this parameter for
the other GET operations of a resource, Show-AutoTaskResource lists the operations

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

### -Raw

Returns the full API response object, such as the items & the page details of a query

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
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

Defines the name of the resource to get, such as Companies or CompanyAlertsChild

Run Show-AutoTaskResource -Method GET to list the resources

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

### -SimpleSearch

Defines a simple search query to use when getting the resource

Limited to a single filter such as
"isActive eq true" or "id eq 8765309"

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: SimpleSearch
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

### System.Int64

{{ Fill in the Description }}

## OUTPUTS

## NOTES

N/A


## RELATED LINKS

- [](https://celerium.github.io/Celerium.AutoTask/site/Resource/Get-AutoTaskResource.html)
