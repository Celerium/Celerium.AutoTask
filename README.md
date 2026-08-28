<h1 align="center">
  <br>
  <a href="https://AutoTask.com"><img src="https://raw.githubusercontent.com/Celerium/Celerium.AutoTask/refs/heads/main/.github/images/PoSHGallery_Celerium.AutoTask.png" alt="Celerium.AutoTask" width="200"></a>
  <br>
  Celerium.AutoTask
  <br>
</h1>

[![Az_Pipeline][Az_Pipeline-shield]][Az_Pipeline-url]
[![GitHub_Pages][GitHub_Pages-shield]][GitHub_Pages-url]

[![PoshGallery_Version][PoshGallery_Version-shield]][PoshGallery_Version-url]
[![PoshGallery_Platforms][PoshGallery_Platforms-shield]][PoshGallery_Platforms-url]
[![PoshGallery_Downloads][PoshGallery_Downloads-shield]][PoshGallery_Downloads-url]
[![codeSize][codeSize-shield]][codeSize-url]

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]

[![GitHub_License][GitHub_License-shield]][GitHub_License-url]

<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://AutoTask.com">
    <img src="https://raw.githubusercontent.com/Celerium/Celerium.AutoTask/refs/heads/main/.github/images/PoSHGitHub_Celerium.AutoTask.png" alt="Logo">
  </a>

  <p align="center">
    <a href="https://www.powershellgallery.com/packages/Celerium.AutoTask" target="_blank">PowerShell Gallery</a>
    ·
    <a href="https://github.com/Celerium/Celerium.AutoTask/issues/new/choose" target="_blank">Report Bug</a>
    ·
    <a href="https://github.com/Celerium/Celerium.AutoTask/issues/new/choose" target="_blank">Request Feature</a>
  </p>
</div>

---

## Thanks

Big thanks to Kevin Tegelaar [AutoTaskAPI](https://github.com/KelvinTegelaar/AutotaskAPI) for being the basis of what I used to create this module. I have learned a lot from his work and it has been a great help in understanding how to interact with AutoTask and API's overall.

## About The Project

The [Celerium.AutoTask](https://www.powershellgallery.com/packages/Celerium.AutoTask) PowerShell wrapper offers the ability to read, create, update, delete much of the data within AutoTask's CRM platform. This module serves to abstract away the details of interacting with AutoTask's API endpoints in such a way that is consistent with PowerShell nomenclature. This gives system administrators and PowerShell developers a convenient and familiar way of using AutoTask's API to create documentation scripts, automation, and integrations.

- :book: **Celerium.AutoTask** project documentation can be found on [Github Pages](https://celerium.github.io/Celerium.AutoTask/)
- :book: AutoTask's REST API documentation can be found [here](https://ww24.autotask.net/DeveloperHelp/Content/APIs/REST/REST_API_Home.htm)

AutoTask features a REST API that makes use of common HTTP request methods. In order to maintain PowerShell best practices, only approved verbs are used.

- DELETE -> `Remove-`
- GET -> `Get-`
- POST/PATCH -> `Set`-
- PUT -> `New-`

Additionally, PowerShell's `verb-noun` nomenclature is respected. Each noun is prefixed with `AutoTask` in an attempt to prevent naming problems.

For example, one might access the /Companies endpoint by running the following PowerShell command with the appropriate parameters:

```posh
Get-AutoTaskResource -Resource Companies -SimpleSearch "isActive eq true"
or
Get-AutoTaskResource -Resource Companies -ID 12345
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Install

This module can be installed directly from the [PowerShell Gallery](https://www.powershellgallery.com/packages/Celerium.AutoTask) with the following command:

```posh
Install-Module -Name Celerium.AutoTask
```

- :information_source: This module supports PowerShell 5.0+ and *should* work in PowerShell Core.
- :information_source: If you are running an older version of PowerShell, or if PowerShellGet is unavailable, you can manually download the *main* branch and place the latest version of *Celerium.AutoTask* from the build folder into the *(default)* `C:\Program Files\WindowsPowerShell\Modules` folder.

**Celerium.AutoTask** project documentation can be found on [Github Pages](https://celerium.github.io/Celerium.AutoTask/)

- A full list of functions can be retrieved by running `Get-Command -Module Celerium.AutoTask`.
- Help info and a list of parameters can be found by running `Get-Help <command name>`, such as:

```posh
Get-Help Get-AutoTaskResource
Get-Help Get-AutoTaskResource -Full
```

```posh
Show-AutoTaskResource
```

The `Show-AutoTaskResource` function will return a list of all the available API resources and their corresponding endpoint URIs. It will also show which HTTP methods are supported for each resource and is very helpful when determining what values are available with the dynamic -Resource parameter.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Initial Setup

After installing this module, you will need to configure your *API data* that is used to talk with the AutoTask API.

1. Run `Add-AutoTaskAPIKey -ApiIntegrationCode 8675309 -ApiUsername 8675309 -ApiSecretKey 8675309`
   - It will prompt you to enter your API keys if you do not specify it
   <br>

2. Run `Add-AutoTaskBaseURI` or `Add-AutoTaskBaseURI -DataCenter {DCName}`
   - `Add-AutoTaskBaseURI` will attempt to auto-detect your AutoTask data center based on your API username
   - If you have your own API gateway or proxy, you may put in your own custom URI by specifying the `-BaseUri` parameter:
      - `Add-AutoTaskBaseURI -BaseUri http://myapi.gateway.celerium.org`
      <br>

3. [**optional**] Run `Export-AutoTaskModuleSettings`
   - This will create a config file at `%UserProfile%\Celerium.AutoTask` that holds the *base uri* & *API data* information.
   - Next time you run `Import-Module -Name Celerium.AutoTask`, this configuration file will automatically be loaded.
   - :warning: Exporting module settings encrypts your API access token in a format that can **only be unencrypted by the user principal** that encrypted the secret. It makes use of .NET DPAPI, which for Windows uses reversible encrypted tied to your user principal. This means that you **cannot copy** your configuration file to another computer or user account and expect it to work.
   - :warning: However in Linux\Unix operating systems the secret keys are more obfuscated than encrypted so it is recommend to use a more secure & cross-platform storage method.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Usage

Calling an API resource is as simple as running `<MethodType>-AutoTaskResource`

- The following is a table of supported functions and their corresponding API resources:
- Example scripts can be found in the [examples](https://github.com/Celerium/Celerium.AutoTask/tree/main/examples) folder of this repository.

|Category|EndpointUri              |Method|Function                            |Example                    |
|--------|-------------------------|------|------------------------------------|---------------------------|
|Resource|See Show-AutoTaskResource|GET   |Get-AutoTaskResource                |Invoke-ContactGroupsExample|
|Resource|See Show-AutoTaskResource|PUT   |New-AutoTaskBody                    |Invoke-ContactGroupsExample|
|Resource|See Show-AutoTaskResource|POST  |New-AutoTaskResource                |Invoke-ContactGroupsExample|
|Resource|See Show-AutoTaskResource|DELETE|Remove-AutoTaskResource             |Invoke-ContactGroupsExample|
|Resource|See Show-AutoTaskResource|PATCH |Set-AutoTaskResource                |Invoke-ContactGroupsExample|
|Resource|                         |GET   |Show-AutoTaskResource               |N/A                        |

The `Show-AutoTaskResource` function will return a list of all the available API resources and their corresponding endpoint URIs. It will also show which HTTP methods are supported for each resource.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Contributing

Contributions are what makes the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

See the [CONTRIBUTING](https://github.com/Celerium/Celerium.AutoTask/blob/master/.github/CONTRIBUTING.md) guide for more information about contributing.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## License

Distributed under the MIT license. See [LICENSE](https://github.com/Celerium/Celerium.AutoTask/blob/master/LICENSE) for more information.

[![GitHub_License][GitHub_License-shield]][GitHub_License-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->

[Az_Pipeline-shield]:               https://img.shields.io/azure-devops/build/AzCelerium/Celerium.AutoTask/18?style=for-the-badge&label=DevOps_Build
[Az_Pipeline-url]:                  https://dev.azure.com/AzCelerium/Celerium.AutoTask/_build?definitionId=18

[GitHub_Pages-shield]:              https://img.shields.io/github/actions/workflow/status/celerium/Celerium.AutoTask/pages%2Fpages-build-deployment?style=for-the-badge&label=GitHub%20Pages
[GitHub_Pages-url]:                 https://github.com/Celerium/Celerium.AutoTask/actions/workflows/pages/pages-build-deployment

[GitHub_License-shield]:            https://img.shields.io/github/license/celerium/Celerium.AutoTask?style=for-the-badge
[GitHub_License-url]:               https://github.com/Celerium/Celerium.AutoTask/blob/master/LICENSE

[PoshGallery_Version-shield]:       https://img.shields.io/powershellgallery/v/Celerium.AutoTask?include_prereleases&style=for-the-badge
[PoshGallery_Version-url]:          https://www.powershellgallery.com/packages/Celerium.AutoTask

[PoshGallery_Platforms-shield]:     https://img.shields.io/powershellgallery/p/Celerium.AutoTask?style=for-the-badge
[PoshGallery_Platforms-url]:        https://www.powershellgallery.com/packages/Celerium.AutoTask

[PoshGallery_Downloads-shield]:     https://img.shields.io/powershellgallery/dt/Celerium.AutoTask?style=for-the-badge
[PoshGallery_Downloads-url]:        https://www.powershellgallery.com/packages/Celerium.AutoTask

[codeSize-shield]:                  https://img.shields.io/github/repo-size/celerium/Celerium.AutoTask?style=for-the-badge
[codeSize-url]:                     https://github.com/Celerium/Celerium.AutoTask

[contributors-shield]:              https://img.shields.io/github/contributors/celerium/Celerium.AutoTask?style=for-the-badge
[contributors-url]:                 https://github.com/Celerium/Celerium.AutoTask/graphs/contributors

[forks-shield]:                     https://img.shields.io/github/forks/celerium/Celerium.AutoTask?style=for-the-badge
[forks-url]:                        https://github.com/Celerium/Celerium.AutoTask/network/members

[stars-shield]:                     https://img.shields.io/github/stars/celerium/Celerium.AutoTask?style=for-the-badge
[stars-url]:                        https://github.com/Celerium/Celerium.AutoTask/stargazers

[issues-shield]:                    https://img.shields.io/github/issues/Celerium/Celerium.AutoTask?style=for-the-badge
[issues-url]:                       https://github.com/Celerium/Celerium.AutoTask/issues
