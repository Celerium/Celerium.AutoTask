---
document type: cmdlet
external help file: Celerium.AutoTask-Help.xml
grand_parent: Internal
HelpUri: https://celerium.github.io/Celerium.AutoTask/site/Internal/Add-AutoTaskAPIKey.html
Locale: en-US
Module Name: Celerium.AutoTask
parent: PUT
PlatyPS schema version: 2024-05-01
title: Add-AutoTaskAPIKey
---

# Add-AutoTaskAPIKey

## SYNOPSIS

Sets the API username, secret, & integration code used to authenticate all API calls

## SYNTAX

### AsPlainText (Default)

```
Add-AutoTaskAPIKey -ApiUsername <string> -ApiIntegrationCode <string> [-ApiSecretKey <string>]
```

### AsSecureString

```
Add-AutoTaskAPIKey -ApiUsername <string> -ApiKeySecureString <securestring>
 -ApiIntegrationCode <string>
```

## ALIASES

This cmdlet has the following aliases,
  - Set-AutoTaskAPIKey

## DESCRIPTION

The Add-AutoTaskAPIKey cmdlet sets the API username, secret, & integration code which
are used to authenticate all API calls made to the AutoTask API

The username & integration code are stored in memory as plain text & the secret is
stored in memory as a SecureString

AutoTask API users & their credentials are created in the AutoTask web interface
    Admin > Resources (Users) > New API User

The API tracking identifier of the API user is the integration code

## EXAMPLES

### EXAMPLE 1

```powershell
Add-AutoTaskAPIKey -ApiUsername 'api@example.com' -ApiIntegrationCode '12345'
```

Prompts to enter in the API secret which will be stored as a SecureString

### EXAMPLE 2

```powershell
Add-AutoTaskAPIKey -ApiUsername 'api@example.com' -ApiIntegrationCode '12345' -ApiSecretKey '12345'
```

Converts the secret to a SecureString and stores the values in global variables

### EXAMPLE 3

```powershell
'12345' | Add-AutoTaskAPIKey -ApiUsername 'api@example.com' -ApiIntegrationCode '12345'
```

The secret is passed in from the pipeline

## PARAMETERS

### -ApiIntegrationCode

Defines the API integration code (tracking identifier) of the API user

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ApiKeySecureString

Input a SecureString object containing the secret of the API user

```yaml
Type: System.Security.SecureString
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: AsSecureString
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ApiSecretKey

Defines the secret (password) of the API user as plain text

If neither ApiSecretKey nor ApiKeySecureString is defined the cmdlet will prompt you
to enter the secret which will be stored as a SecureString

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: AsPlainText
  Position: Named
  IsRequired: false
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ApiUsername

Defines the username of the API user

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
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

### System.String

{{ Fill in the Description }}

## OUTPUTS

## NOTES

N/A


## RELATED LINKS

- [](https://celerium.github.io/Celerium.AutoTask/site/Internal/Add-AutoTaskAPIKey.html)
