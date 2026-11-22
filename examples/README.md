<h1 align="center">
  <br>
  <a href="http://Celerium.org"><img src="https://raw.githubusercontent.com/Celerium/Celerium.AutoTask/refs/heads/main/.github/images/PoSHGallery_Celerium.AutoTask.png" alt="_CeleriumDemo" width="200"></a>
  <br>
  Celerium.AutoTask_Examples
  <br>
</h1>

---

## Examples

- :book: Project documentation can be found on [Github Pages](https://celerium.github.io/Celerium.AutoTask/)
- :book: AutoTask's REST API documentation can be found in the [AutoTask REST API guide](https://www.autotask.net/help/developerhelp/Content/APIs/REST/REST_API_Home.htm)

Every example in this folder only uses read-only requests (GET requests & POST queries) and needs version 2.0.0 or later of the module.

|Script                                                                |Description                                                                       |
|----------------------------------------------------------------------|----------------------------------------------------------------------------------|
|[Invoke-CompanyReportExample.ps1](Invoke-CompanyReportExample.ps1)    |Returns the active companies with their company type & the number of contacts    |

```posh
# The API values can also come from Export-AutoTaskModuleSettings or the AUTOTASK_* environment variables
.\Invoke-CompanyReportExample.ps1 -ApiUsername 'api@example.com' -ApiSecret (Read-Host -AsSecureString) -ApiIntegrationCode '12345' -Verbose
```

### Legacy examples

The [Legacy](Legacy) folder contains examples from version 1.x of the module that **create, update, & delete** data in AutoTask.
They are kept for reference, are not tested, and should only be run against a test (sandbox) AutoTask instance.
