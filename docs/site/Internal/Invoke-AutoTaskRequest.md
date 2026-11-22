---
document type: cmdlet
external help file: Celerium.AutoTask-Help.xml
grand_parent: Internal
HelpUri: https://celerium.github.io/Celerium.AutoTask/site/Internal/Invoke-AutoTaskRequest.html
Locale: en-US
Module Name: Celerium.AutoTask
parent: GET
PlatyPS schema version: 2024-05-01
title: Invoke-AutoTaskRequest
---

# Invoke-AutoTaskRequest

## SYNOPSIS

Makes an API request to the AutoTask API

## SYNTAX

### __AllParameterSets

```
Invoke-AutoTaskRequest [[-Method] <string>] [-ResourceURI] <string> [[-UriFilter] <hashtable>]
 [[-Data] <Object>] [-AllResults] [-Raw] [-WriteRequest]
```

## ALIASES

This cmdlet has the following aliases,
  - None

## DESCRIPTION

The Invoke-AutoTaskRequest cmdlet invokes an API request to the AutoTask API

This is an internal function that is used by all public functions

GET requests & the POST query requests (/query & /query/count) are read requests.
Any other request is a write request.
Write requests are never retried

By default only the data of a response is returned, such as the items of a query
or the item of a single resource.
Use -Raw to return the full response

## EXAMPLES

### EXAMPLE 1

```powershell
Invoke-AutoTaskRequest -Method GET -ResourceURI '/V1.0/Companies/0'
```

Gets the company with the ID 0

### EXAMPLE 2

```powershell
Invoke-AutoTaskRequest -Method POST -ResourceURI '/V1.0/Companies/query' -Data '{"filter":[{"op":"eq","field":"isActive","value":true}]}' -AllResults
```

Returns every active company by requesting every page of the query

### EXAMPLE 3

```powershell
Invoke-AutoTaskRequest -Method PATCH -ResourceURI '/V1.0/Companies' -Data @{ id = 12345; phone = '555-555-5555' }
```

Sends a write request with a JSON body

## PARAMETERS

### -AllResults

Returns all items from an endpoint by following the next page url of every page of a query

Ignored for write requests

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

### -Data

Optional object to send as the JSON request body

A string is sent as is and must already be JSON, any other object is converted to JSON

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

### -Method

Defines the type of API method to use

Allowed values:
'GET', 'POST', 'PUT', 'PATCH', 'DELETE'

```yaml
Type: System.String
DefaultValue: GET
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

### -Raw

Returns the full API response object instead of only the data

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

### -ResourceURI

Defines the resource uri (url) path to use when creating the API call, such as /V1.0/Companies/query

The path is appended to the base URI defined by Add-AutoTaskBaseURI

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

### -UriFilter

Hashtable of query string parameters to append to the resource uri, such as @{ search = '{...}' }

The values are url encoded

```yaml
Type: System.Collections.Hashtable
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

### -WriteRequest

Marks the request as a write request so that it is never retried, even when it uses the GET method

Every request that is not a GET request or a POST query request is always a write request

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

- [](https://celerium.github.io/Celerium.AutoTask/site/Internal/Invoke-AutoTaskRequest.html)
