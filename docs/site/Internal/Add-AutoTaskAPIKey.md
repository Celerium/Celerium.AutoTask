---
external help file: Celerium.AutoTask-help.xml
grand_parent: Internal
Module Name: Celerium.AutoTask
online version: https://celerium.github.io/Celerium.AutoTask/site/Internal/Add-AutoTaskAPIKey.html
parent: PUT
schema: 2.0.0
title: Add-AutoTaskAPIKey
---

# Add-AutoTaskAPIKey

## SYNOPSIS
Sets your API key used to authenticate all API calls

## SYNTAX

### AsPlainText (Default)
```powershell
Add-AutoTaskAPIKey -ApiUsername <String> [-ApiSecretKey <String>] -ApiIntegrationCode <String>
 [<CommonParameters>]
```

### AsSecureString
```powershell
Add-AutoTaskAPIKey -ApiUsername <String> [-ApiKeySecureString <SecureString>] -ApiIntegrationCode <String>
 [<CommonParameters>]
```

## DESCRIPTION
The Add-AutoTaskAPIKey cmdlet sets your API key which is used to
authenticate all API calls made to AutoTask

AutoTask API keys can be generated via the AutoTask web interface
    Resources \> API User \> Credentials

## EXAMPLES

### EXAMPLE 1
```powershell
Add-AutoTaskAPIKey -ApiUsername 'Celerium@Celerium.org' -ApiIntegrationCode '12345'
```

Prompts to enter in the API secret key which will be stored as a SecureString

### EXAMPLE 2
```powershell
Add-AutoTaskAPIKey -ApiUsername 'Celerium@Celerium.org' -ApiIntegrationCode '12345' -ApiSecretKey '12345'
```

Converts the string to a SecureString and stores it in the global variable

## PARAMETERS

### -ApiUsername
Plain text API username

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ApiSecretKey
Plain text API secret key

If not defined the cmdlet will prompt you to enter the API secret key which
will be stored as a SecureString

```yaml
Type: String
Parameter Sets: AsPlainText
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ApiKeySecureString
Input a SecureString object containing the API key

```yaml
Type: SecureString
Parameter Sets: AsSecureString
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ApiIntegrationCode
Plain text API integration code

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
N/A

## RELATED LINKS

[https://celerium.github.io/Celerium.AutoTask/site/Internal/Add-AutoTaskAPIKey.html](https://celerium.github.io/Celerium.AutoTask/site/Internal/Add-AutoTaskAPIKey.html)

