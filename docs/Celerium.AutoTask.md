---
document type: module
Help Version: 1.0.0.0
HelpInfoUri: 
Locale: en-US
Module Guid: c12a74ed-2a5a-4ae3-9b41-991f996e15d6
Module Name: Celerium.AutoTask
PlatyPS schema version: 2024-05-01
title: Celerium.AutoTask Module
parent: Home
---

# Celerium.AutoTask Module

## Description

This module provides a PowerShell wrapper for the AutoTask (Datto|Autotask PSA) REST API. Every resource & operation of the AutoTask OpenAPI spec is supported by generic functions: GET = Get-AutoTaskResource, POST = New-AutoTaskResource, PATCH & PUT = Set-AutoTaskResource, DELETE = Remove-AutoTaskResource. Resource names are validated & tab-completed from the spec. Read (GET & query) requests work as normal. Write (POST, PUT, PATCH, DELETE) functions support -WhatIf & ask for confirmation before a request is sent

## Celerium.AutoTask

### [Add-AutoTaskAPIKey](site/Internal/Add-AutoTaskAPIKey.md)

Sets the API username, secret, & integration code used to authenticate all API calls

### [Add-AutoTaskBaseURI](site/Internal/Add-AutoTaskBaseURI.md)

Sets the base URI for the AutoTask API connection

### [Complete-AutoTaskResource](site/Internal/Complete-AutoTaskResource.md)

Tab-completes AutoTask resource & operation names

### [Export-AutoTaskModuleSettings](site/Internal/Export-AutoTaskModuleSettings.md)

Exports the AutoTask BaseURI, API, & JSON configuration information to file

### [Get-AutoTaskAPIKey](site/Internal/Get-AutoTaskAPIKey.md)

Gets the AutoTask API username, secret, & integration code

### [Get-AutoTaskBaseURI](site/Internal/Get-AutoTaskBaseURI.md)

Shows the AutoTask base URI

### [Get-AutoTaskModuleSettings](site/Internal/Get-AutoTaskModuleSettings.md)

Gets the saved AutoTask configuration settings

### [Get-AutoTaskResource](site/Resource/Get-AutoTaskResource.md)

Gets a resource

### [Get-AutoTaskResourceMap](site/Internal/Get-AutoTaskResourceMap.md)

Gets the resource map of the AutoTask API

### [Get-AutoTaskResourceOperation](site/Internal/Get-AutoTaskResourceOperation.md)

Gets the operations of an AutoTask resource

### [Get-AutoTaskSpecOperation](site/Internal/Get-AutoTaskSpecOperation.md)

Gets every operation from an AutoTask OpenAPI (swagger) spec

### [Import-AutoTaskModuleSettings](site/Internal/Import-AutoTaskModuleSettings.md)

Imports the AutoTask BaseURI, API, & JSON configuration information to the current session

### [Invoke-AutoTaskRequest](site/Internal/Invoke-AutoTaskRequest.md)

Makes an API request to the AutoTask API

### [New-AutoTaskBody](site/Resource/New-AutoTaskBody.md)

Creates a new resource body object

### [New-AutoTaskResource](site/Resource/New-AutoTaskResource.md)

Creates a new resource

### [Remove-AutoTaskAPIKey](site/Internal/Remove-AutoTaskAPIKey.md)

Removes the API username, secret, & integration code from the global variables

### [Remove-AutoTaskBaseURI](site/Internal/Remove-AutoTaskBaseURI.md)

Removes the AutoTask base URI global variable

### [Remove-AutoTaskModuleSettings](site/Internal/Remove-AutoTaskModuleSettings.md)

Removes the stored AutoTask configuration folder

### [Remove-AutoTaskResource](site/Resource/Remove-AutoTaskResource.md)

Deletes a resource

### [Resolve-AutoTaskResource](site/Internal/Resolve-AutoTaskResource.md)

Resolves an AutoTask resource & operation to a request uri

### [Set-AutoTaskResource](site/Resource/Set-AutoTaskResource.md)

Updates a resource

### [Show-AutoTaskResource](site/Resource/Show-AutoTaskResource.md)

Shows the available resources & operations of the AutoTask API

### [Test-AutoTaskAPIKey](site/Internal/Test-AutoTaskAPIKey.md)

Test the AutoTask API username, secret, & integration code
