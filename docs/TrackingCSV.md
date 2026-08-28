---
title: Tracking CSV
parent: Home
nav_order: 2
---

# Tracking CSV

When updating the documentation for this project, the tracking CSV plays a huge part in organizing of the markdown documents. Any new functions or endpoints should be added to the tracking CSV when publishing an updated module or documentation version.

{: .warning }
I recommend downloading the CSV from the link provided rather then viewing the table below.

[Tracking CSV](https://github.com/Celerium/Celerium.AutoTask/blob/master/docs/endpoints.csv)

---

## CSV markdown table

|Category|EndpointUri              |Method|Function                            |Example                    |Complete|Notes                                                                          |
|--------|-------------------------|------|------------------------------------|---------------------------|--------|-------------------------------------------------------------------------------|
|Internal|                         |GET   |Invoke-AutoTaskRequest              |N/A                        |Yes     |                                                                               |
|Internal|                         |PUT   |New-AutoTaskResourceDynamicParameter|N/A                        |Yes     |                                                                               |
|Internal|                         |PUT   |Set-AutoTaskResourceDynamicParameter|N/A                        |Yes     |                                                                               |
|Internal|                         |PUT   |Add-AutoTaskAPIKey                  |N/A                        |Yes     |                                                                               |
|Internal|                         |GET   |Get-AutoTaskAPIKey                  |N/A                        |Yes     |                                                                               |
|Internal|                         |DELETE|Remove-AutoTaskAPIKey               |N/A                        |Yes     |                                                                               |
|Internal|                         |GET   |Test-AutoTaskAPIKey                 |N/A                        |Yes     |                                                                               |
|Internal|                         |PUT   |Add-AutoTaskBaseURI                 |N/A                        |Yes     |                                                                               |
|Internal|                         |GET   |Get-AutoTaskBaseURI                 |N/A                        |Yes     |                                                                               |
|Internal|                         |DELETE|Remove-AutoTaskBaseURI              |N/A                        |Yes     |                                                                               |
|Internal|                         |PUT   |Export-AutoTaskModuleSettings       |N/A                        |Yes     |                                                                               |
|Internal|                         |GET   |Get-AutoTaskModuleSettings          |N/A                        |Yes     |                                                                               |
|Internal|                         |PUT   |Import-AutoTaskModuleSettings       |N/A                        |Yes     |                                                                               |
|Internal|                         |PUT   |Initialize-AutoTaskModuleSettings   |N/A                        |Yes     |                                                                               |
|Internal|                         |DELETE|Remove-AutoTaskModuleSettings       |N/A                        |Yes     |                                                                               |
|Resource|See Show-AutoTaskResource|GET   |Get-AutoTaskResource                |Invoke-ContactGroupsExample|Yes     |Support other methods                                                          |
|Resource|See Show-AutoTaskResource|PUT   |New-AutoTaskBody                    |Invoke-ContactGroupsExample|Yes     |                                                                               |
|Resource|See Show-AutoTaskResource|POST  |New-AutoTaskResource                |Invoke-ContactGroupsExample|Yes     |                                                                               |
|Resource|See Show-AutoTaskResource|DELETE|Remove-AutoTaskResource             |Invoke-ContactGroupsExample|Yes     |                                                                               |
|Resource|See Show-AutoTaskResource|PATCH |Set-AutoTaskResource                |Invoke-ContactGroupsExample|Yes     |                                                                               |
|Resource|                         |GET   |Show-AutoTaskResource               |N/A                        |Yes     |Shows avaliable resources that can be used with the dynamic -Resource parameter|
