#
# Module manifest for module 'OSDCloudAzure'
#

@{
    RootModule = 'OSDCloudAzure.psm1'
    ModuleVersion = '22.10.19.1'
    CompatiblePSEditions = @('Desktop')
    GUID = 'ded8e967-9fc3-4e54-b4c0-5415790c6d4f'
    Author = 'David Segura'
    CompanyName = 'David Segura'
    Copyright = '(c) 2022 David Segura'
    Description = 'OSDCloudAzure PowerShell Module'
    PowerShellVersion = '5.1'
    FunctionsToExport = @()
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = '*'
    PrivateData = @{
        PSData = @{
            Tags            = @('osd','osdeploy','osdcloud')
            LicenseUri      = 'https://github.com/OSDeploy/OSDCloudAzure/blob/main/LICENSE'
            ProjectUri      = 'https://github.com/OSDeploy/OSDCloudAzure'
            IconUri         = 'https://raw.githubusercontent.com/OSDeploy/OSDCloudAzure/main/OSDCloudAzure.png'
            ReleaseNotes    = 'https://osdcloud.com'
        }
    }
}