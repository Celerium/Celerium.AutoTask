---
external help file: Celerium.AutoTask-help.xml
grand_parent: Resource
Module Name: Celerium.AutoTask
online version: https://celerium.github.io/Celerium.AutoTask/site/Resource/Get-AutoTaskResource.html
parent: GET
schema: 2.0.0
title: Get-AutoTaskResource
---

# Get-AutoTaskResource

## SYNOPSIS
Gets a resource

## SYNTAX

### ID
```powershell
Get-AutoTaskResource -ID <Int64> [-ChildID <Int64>] -Resource <String> [<CommonParameters>]
```

### SimpleSearch
```powershell
Get-AutoTaskResource [-ID <Int64>] -SimpleSearch <String> [-AllResults] -Resource <String> [<CommonParameters>]
```

### AdvancedSearch
```powershell
Get-AutoTaskResource [-ID <Int64>] -AdvancedSearch <String> [-Method <String>] [-AllResults] -Resource <String>
 [<CommonParameters>]
```

## DESCRIPTION
The Get-AutoTaskResource cmdlet gets a resource from the AutoTask API
by ID or by using a simple or advanced search query

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

## PARAMETERS

### -ID
Defines the ID of the resource to get

```yaml
Type: Int64
Parameter Sets: ID
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: Int64
Parameter Sets: SimpleSearch, AdvancedSearch
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ChildID
Defines the ID of the child resource to get

```yaml
Type: Int64
Parameter Sets: ID
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -SimpleSearch
Defines a simple search query to use when getting the resource

Limited to a single filter such as
"isActive eq true" or "id eq 8765309"

```yaml
Type: String
Parameter Sets: SimpleSearch
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AdvancedSearch
Defines an advanced search query to use when getting the resource

'{
    "MaxRecords":100,
    "filter":\[
        {"op":"eq","field":"IsActive","value":true},
        {"op":"and","items":\[
            {"op":"beginsWith","field":"companyName","value":"D"}
        \]}
    \]
}'

```yaml
Type: String
Parameter Sets: AdvancedSearch
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Method
Defines the type of API method to use

Allowed values:
'GET', 'POST'

```yaml
Type: String
Parameter Sets: AdvancedSearch
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllResults
Returns all items from an endpoint

By default only the first 500 items are returned

```yaml
Type: SwitchParameter
Parameter Sets: SimpleSearch, AdvancedSearch
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Resource
{{ Fill Resource Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
N/A

## RELATED LINKS

[https://celerium.github.io/Celerium.AutoTask/site/Public/Get-AutoTaskResource.html](https://celerium.github.io/Celerium.AutoTask/site/Public/Get-AutoTaskResource.html)

