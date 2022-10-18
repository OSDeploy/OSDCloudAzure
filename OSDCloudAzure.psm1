function Connect-OSDCloudAzure {
    [CmdletBinding()]
    param (
        [System.Management.Automation.SwitchParameter]
        $UseDeviceAuthentication
    )
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Green "Connect-OSDCloudAzure"

    if ($env:SystemDrive -eq 'X:') {
        $UseDeviceAuthentication = $true
        $OSDCloudLogs = "$env:SystemDrive\OSDCloud\Logs"
        if (-not (Test-Path $OSDCloudLogs)) {
            New-Item $OSDCloudLogs -ItemType Directory -Force | Out-Null
        }
    }
    osdcloud-InstallModuleAzureAD
    osdcloud-InstallModuleAzAccounts
        #Connect-AzAccount
        #Get-AzSubscription
        #Set-AzContext
        #Get-AzContext
        #Get-AzAccessToken
    osdcloud-InstallModuleAzKeyVault
    osdcloud-InstallModuleAzResources
    osdcloud-InstallModuleAzStorage
    osdcloud-InstallModuleMSGraphAuthentication
    osdcloud-InstallModuleMSGraphDeviceManagement

    if ($UseDeviceAuthentication) {
        Connect-AzAccount -UseDeviceAuthentication -AuthScope Storage -ErrorAction Stop
    }
    else {
        Connect-AzAccount -AuthScope Storage -ErrorAction Stop
    }

    $Global:AzSubscription = Get-AzSubscription

    if (($Global:AzSubscription).Count -ge 2) {
        $i = $null
        $Results = foreach ($Item in $Global:AzSubscription) {
            $i++
    
            $ObjectProperties = @{
                Number  = $i
                Name    = $Item.Name
                Id      = $Item.Id
            }
            New-Object -TypeName PSObject -Property $ObjectProperties
        }
    
        $Results | Select-Object -Property Number, Name, Id | Format-Table | Out-Host
    
        do {
            $SelectReadHost = Read-Host -Prompt "Select an Azure Subscription by Number"
        }
        until (((($SelectReadHost -ge 0) -and ($SelectReadHost -in $Results.Number))))
    
        $Results = $Results | Where-Object {$_.Number -eq $SelectReadHost}
    
        $Global:AzContext = Set-AzContext -Subscription $Results.Id
    }
    else {
        $Global:AzContext = Get-AzContext
    }

    if ($Global:AzContext) {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Green 'Welcome to Azure OSDCloud!'
        $Global:AzAccount = $Global:AzContext.Account
        $Global:AzEnvironment = $Global:AzContext.Environment
        $Global:AzTenantId = $Global:AzContext.Tenant
        $Global:AzSubscription = $Global:AzContext.Subscription

        Write-Host -ForegroundColor Cyan        'Account:           ' $Global:AzAccount
        Write-Host -ForegroundColor Cyan        'AzEnvironment:     ' $Global:AzEnvironment
        Write-Host -ForegroundColor Cyan        'AzTenantId:        ' $Global:AzTenantId
        Write-Host -ForegroundColor Cyan        'AzSubscription:    ' $Global:AzSubscription
        if ($null -eq $Global:AzContext.Subscription) {
            Write-Warning 'You do not have access to an Azure Subscriptions'
            Write-Warning 'This is likely due to not having rights to Azure Resources or Azure Storage'
            Write-Warning 'Contact your Azure administrator to resolve this issue'
            Break
        }

        #Write-Host ''
        #Write-Host -ForegroundColor DarkGray    'Azure Context:             $Global:AzContext'
        #Write-Host -ForegroundColor DarkGray    'Access Tokens:             $Global:Az*AccessToken'
        #Write-Host -ForegroundColor DarkGray    'Headers:                   $Global:Az*Headers'
        #Write-Host ''

        if ($OSDCloudLogs) {
            #Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Logging $OSDCloudLogs\AzSubscription.json"
            $Global:AzSubscription | ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzSubscription.json" -Encoding ascii -Width 2000 -Force

            #Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Logging $OSDCloudLogs\AzContext.json"
            $Global:AzContext | ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzContext.json" -Encoding ascii -Width 2000 -Force
        }
        #=================================================
        #	AAD Graph
        #=================================================
        Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Generating AadGraph Access Tokens"
        $Global:AzAadGraphAccessToken = Get-AzAccessToken -ResourceTypeName AadGraph
        $Global:AzAadGraphHeaders = @{
            'Authorization' = 'Bearer ' + $Global:AzAadGraphAccessToken.Token
            'Content-Type'  = 'application/json'
            'ExpiresOn'     = $Global:AzAadGraphAccessToken.ExpiresOn
        }
        if ($OSDCloudLogs) {
            #Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Logging $OSDCloudLogs\AzAadGraphAccessToken.json"
            $Global:AzAadGraphAccessToken | ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzAadGraphAccessToken.json" -Encoding ascii -Width 2000 -Force

            #Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Logging $OSDCloudLogs\AzAadGraphHeaders.json"
            $Global:AzAadGraphHeaders | ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzAadGraphHeaders.json" -Encoding ascii -Width 2000 -Force
        }
        #=================================================
        #	Azure KeyVault
        #=================================================
        Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Generating KeyVault Access Tokens"
        $Global:AzKeyVaultAccessToken = Get-AzAccessToken -ResourceTypeName KeyVault
        $Global:AzKeyVaultHeaders = @{
            'Authorization' = 'Bearer ' + $Global:AzKeyVaultAccessToken.Token
            'Content-Type'  = 'application/json'
            'ExpiresOn'     = $Global:AzKeyVaultAccessToken.ExpiresOn
        }
        if ($OSDCloudLogs) {
            #Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Logging $OSDCloudLogs\AzKeyVaultAccessToken.json"
            $Global:AzKeyVaultAccessToken | ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzKeyVaultAccessToken.json" -Encoding ascii -Width 2000 -Force

            #Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Logging $OSDCloudLogs\AzKeyVaultHeaders.json"
            $Global:AzKeyVaultHeaders | ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzKeyVaultHeaders.json" -Encoding ascii -Width 2000 -Force
        }
        #=================================================
        #	Azure MSGraph
        #=================================================
        Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Generating MSGraph Access Tokens"
        $Global:AzMSGraphAccessToken = Get-AzAccessToken -ResourceTypeName MSGraph
        $Global:AzMSGraphHeaders = @{
            'Authorization' = 'Bearer ' + $Global:AzMSGraphAccessToken.Token
            'Content-Type'  = 'application/json'
            'ExpiresOn'     = $Global:AzMSGraphHeaders.ExpiresOn
        }
        if ($OSDCloudLogs) {
            #Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Logging $OSDCloudLogs\AzMSGraphAccessToken.json"
            $Global:AzMSGraphAccessToken | ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzMSGraphAccessToken.json" -Encoding ascii -Width 2000 -Force

            #Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Logging $OSDCloudLogs\AzMSGraphHeaders.json"
            $Global:AzMSGraphHeaders | ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzMSGraphHeaders.json" -Encoding ascii -Width 2000 -Force
        }
        #=================================================
        #	Azure Storage
        #=================================================
        Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Generating Storage Access Tokens"
        $Global:AzStorageAccessToken = Get-AzAccessToken -ResourceTypeName Storage
        $Global:AzStorageHeaders = @{
            'Authorization' = 'Bearer ' + $Global:AzStorageAccessToken.Token
            'Content-Type'  = 'application/json'
            'ExpiresOn'     = $Global:AzStorageHeaders.ExpiresOn
        }
        if ($OSDCloudLogs) {
            #Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Logging $OSDCloudLogs\AzStorageAccessToken.json"
            $Global:AzStorageAccessToken | ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzStorageAccessToken.json" -Encoding ascii -Width 2000 -Force

            #Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Logging $OSDCloudLogs\AzStorageHeaders.json"
            $Global:AzStorageHeaders | ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzStorageHeaders.json" -Encoding ascii -Width 2000 -Force
        }
        #=================================================
        #	AzureAD
        #=================================================
        #$Global:MgGraph = Connect-MgGraph -AccessToken $Global:AzMSGraphAccessToken.Token -Scopes DeviceManagementConfiguration.Read.All,DeviceManagementServiceConfig.Read.All,DeviceManagementServiceConfiguration.Read.All
        Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Connecting to AzureAD"
        $Global:AzureAD = Connect-AzureAD -AadAccessToken $Global:AzAadGraphAccessToken.Token -AccountId $Global:AzContext.Account.Id
    }
    else {
        Write-Warning "Unable to get AzContext"
    }
}
function Get-OSDCloudAzureResources {
    [CmdletBinding()]
    param ()
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Green "Get-OSDCloudAzureResources"

    if ($env:SystemDrive -eq 'X:') {
        $OSDCloudLogs = "$env:SystemDrive\OSDCloud\Logs"
        if (-not (Test-Path $OSDCloudLogs)) {
            New-Item $OSDCloudLogs -ItemType Directory -Force | Out-Null
        }
    }

    if ($Global:AzureAD -or $Global:MgGraph) {
        #Write-Host -ForegroundColor DarkGray    'Storage Accounts:          $Global:AzStorageAccounts'
        $Global:AzStorageAccounts = Get-AzStorageAccount
        if ($OSDCloudLogs) {
            #Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) $OSDCloudLogs\AzStorageAccounts.json"
            $Global:AzStorageAccounts | ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzStorageAccounts.json" -Encoding ascii -Width 2000 -Force
        }
    
        #Write-Host -ForegroundColor DarkGray    'OSDCloud Storage Accounts: $Global:AzOSDCloudStorageAccounts'
        $Global:AzOSDCloudStorageAccounts = Get-AzStorageAccount | Where-Object {$_.Tags.ContainsKey('OSDCloud')}
        #$Global:AzOSDCloudStorageAccounts = Get-AzResource -ResourceType 'Microsoft.Storage/storageAccounts'
        #$Global:AzOSDCloudStorageAccounts = Get-AzResource -ResourceType 'Microsoft.Storage/storageAccounts' | Where-Object {$_.Tags.ContainsKey('OSDCloud')}
        if ($OSDCloudLogs) {
            #Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) $OSDCloudLogs\AzOSDCloudStorageAccounts.json"
            $Global:AzOSDCloudStorageAccounts | ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzOSDCloudStorageAccounts.json" -Encoding ascii -Width 2000 -Force
        }
    
        $Global:AzStorageContext = @{}
        $Global:AzOSDCloudBlobAutopilotFile = @()
        $Global:AzOSDCloudBlobBootImage = @()
        $Global:AzOSDCloudBlobImage = @()
        $Global:AzOSDCloudBlobDriverPack = @()
        $Global:AzOSDCloudBlobPackage = @()
        $Global:AzOSDCloudBlobScript = @()
    
        if ($Global:AzOSDCloudStorageAccounts) {
            #Write-Host -ForegroundColor DarkGray    'Storage Contexts:          $Global:AzStorageContext'
            #Write-Host -ForegroundColor DarkGray    'Blob Windows Images:       $Global:AzOSDCloudBlobImage'
            #Write-Host ''
            Update-AzConfig -DisplayBreakingChangeWarning $false
            Write-Host -ForegroundColor Cyan "Searching Azure Storage for OSDCloud Resources"
            foreach ($Item in $Global:AzOSDCloudStorageAccounts) {
                $Global:AzCurrentStorageContext = New-AzStorageContext -StorageAccountName $Item.StorageAccountName
                $Global:AzStorageContext."$($Item.StorageAccountName)" = $Global:AzCurrentStorageContext
                #Get-AzStorageBlobByTag -TagFilterSqlExpression ""osdcloudimage""=""win10ltsc"" -Context $StorageContext
                #Get-AzStorageBlobByTag -Context $Global:AzCurrentStorageContext
        
                $AzOSDCloudStorageContainers = Get-AzStorageContainer -Context $Global:AzCurrentStorageContext
                if ($OSDCloudLogs) {
                    #Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) $OSDCloudLogs\AzOSDCloudStorageContainers.json"
                    $Global:AzOSDCloudStorageContainers | ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzOSDCloudStorageContainers.json" -Encoding ascii -Width 2000 -Force
                }
            
                if ($AzOSDCloudStorageContainers) {
                    foreach ($Container in $AzOSDCloudStorageContainers) {
                        if ($Container.Name -like "provision*") {
                            #Provision Containers apply to all deployments in the selected Storage Account
                            Write-Host -ForegroundColor DarkGray "OSDCloud Provision Container: $($Item.StorageAccountName)/$($Container.Name)"
                            $Global:AzOSDCloudBlobAutopilotFile += Get-AzStorageBlob -Context $Global:AzCurrentStorageContext -Container $Container.Name -Blob AutoPilotConfigurationFile.json -ErrorAction Ignore
                            $Global:AzOSDCloudBlobPackage += Get-AzStorageBlob -Context $Global:AzCurrentStorageContext -Container $Container.Name -Blob *.ppkg -ErrorAction Ignore
                            $Global:AzOSDCloudBlobScript += Get-AzStorageBlob -Context $Global:AzCurrentStorageContext -Container $Container.Name -Blob Invoke*.ps1 -ErrorAction Ignore
                        }
                        elseif ($Container.Name -like "bootimage*") {
                            Write-Host -ForegroundColor DarkGray "OSDCloud BootImage Container: $($Item.StorageAccountName)/$($Container.Name)"
                            $Global:AzOSDCloudBlobBootImage += Get-AzStorageBlob -Context $Global:AzCurrentStorageContext -Container $Container.Name -Blob *.iso -ErrorAction Ignore
                        }
                        elseif ($Container.Name -like "driverpack*") {
                            Write-Host -ForegroundColor DarkGray "OSDCloud DriverPack Container: $($Item.StorageAccountName)/$($Container.Name)"
                            $Global:AzOSDCloudBlobDriverPack += Get-AzStorageBlob -Context $Global:AzCurrentStorageContext -Container $Container.Name -Blob *.cab -ErrorAction Ignore
                            $Global:AzOSDCloudBlobDriverPack += Get-AzStorageBlob -Context $Global:AzCurrentStorageContext -Container $Container.Name -Blob *.exe -ErrorAction Ignore
                            $Global:AzOSDCloudBlobDriverPack += Get-AzStorageBlob -Context $Global:AzCurrentStorageContext -Container $Container.Name -Blob *.msi -ErrorAction Ignore
                            $Global:AzOSDCloudBlobDriverPack += Get-AzStorageBlob -Context $Global:AzCurrentStorageContext -Container $Container.Name -Blob *.zip -ErrorAction Ignore
                        }
                        elseif ($Container.Name -like "temp*") {
                            #Temp Containers are not used and should be where you store content that will not be used in a Container Task Sequence
                            Write-Host -ForegroundColor DarkGray "OSDCloud Temp Container: $($Item.StorageAccountName)/$($Container.Name)"
                        }
                        else {
                            Write-Host -ForegroundColor DarkGray "OSDCloud Image Container: $($Item.StorageAccountName)/$($Container.Name)"
                            $Global:AzOSDCloudBlobImage += Get-AzStorageBlob -Context $Global:AzCurrentStorageContext -Container $Container.Name -Blob *.esd -ErrorAction Ignore | Where-Object {$_.Length -gt 3000000000}
                            $Global:AzOSDCloudBlobImage += Get-AzStorageBlob -Context $Global:AzCurrentStorageContext -Container $Container.Name -Blob *.iso -ErrorAction Ignore | Where-Object {$_.Length -gt 3000000000}
                            $Global:AzOSDCloudBlobImage += Get-AzStorageBlob -Context $Global:AzCurrentStorageContext -Container $Container.Name -Blob *.wim -ErrorAction Ignore | Where-Object {$_.Length -gt 3000000000}

                            $Global:AzOSDCloudBlobAutopilotFile += Get-AzStorageBlob -Context $Global:AzCurrentStorageContext -Container $Container.Name -Blob AutoPilotConfigurationFile.json -ErrorAction Ignore
                            $Global:AzOSDCloudBlobPackage += Get-AzStorageBlob -Context $Global:AzCurrentStorageContext -Container $Container.Name -Blob *.ppkg -ErrorAction Ignore
                            $Global:AzOSDCloudBlobScript += Get-AzStorageBlob -Context $Global:AzCurrentStorageContext -Container $Container.Name -Blob Invoke*.ps1 -ErrorAction Ignore
                        }
                    }
                }
            }
            if ($OSDCloudLogs) {
                $Global:AzStorageContext | ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzStorageContext.json" -Encoding ascii -Width 2000 -Force
                $Global:AzOSDCloudBlobAutopilotFile | ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzOSDCloudBlobAutopilotFile.json" -Encoding ascii -Width 2000 -Force
                $Global:AzOSDCloudBlobBootImage| ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzOSDCloudBlobBootImage.json" -Encoding ascii -Width 2000 -Force
                $Global:AzOSDCloudBlobDriverPack | ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzOSDCloudBlobDriverPack.json" -Encoding ascii -Width 2000 -Force
                $Global:AzOSDCloudBlobImage | ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzOSDCloudBlobImage.json" -Encoding ascii -Width 2000 -Force
                $Global:AzOSDCloudBlobPackage | ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzOSDCloudBlobPackage.json" -Encoding ascii -Width 2000 -Force
                $Global:AzOSDCloudBlobScript | ConvertTo-Json | Out-File -FilePath "$OSDCloudLogs\AzOSDCloudBlobScript.json" -Encoding ascii -Width 2000 -Force
            }
            if ($null -eq $Global:AzOSDCloudBlobImage) {
                Write-Warning 'Unable to find a WIM on any of the OSDCloud Azure Storage Containers'
                Write-Warning 'Make sure you have a WIM Windows Image in the OSDCloud Azure Storage Container'
                Write-Warning 'Make sure this user has the Azure Storage Blob Data Reader role to the OSDCloud Container'
                Write-Warning 'You may need to execute Get-OSDCloudAzureResources then Start-OSDCloudAzure'
                Break
            }
        }
        else {
            Write-Warning 'Unable to find any Azure Storage Accounts'
            Write-Warning 'Make sure the OSDCloud Azure Storage Account has an OSDCloud Tag'
            Write-Warning 'Make sure this user has the Azure Reader role on the OSDCloud Azure Storage Account'
            Break
        }
    }
    else {
        Write-Warning 'Unable to connect to AzureAD'
        Write-Warning 'You may need to execute Connect-OSDCloudAzure then Start-OSDCloudAzure'
        Break
    }
}
function Initialize-OSDCloudAzure {
    [CmdletBinding()]
    param ()

    if ($env:SystemDrive -eq 'X:') {
        $Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-OSDCloud.log"
        $null = Start-Transcript -Path (Join-Path "$env:SystemRoot\Temp" $Transcript) -ErrorAction Ignore
        Invoke-Expression -Command (Invoke-RestMethod -Uri functions.osdcloud.com)
        osdcloud-StartWinPE -OSDCloud -Azure
        Connect-OSDCloudAzure
        Get-OSDCloudAzureResources
        $null = Stop-Transcript -ErrorAction Ignore

        if ($Global:AzOSDCloudBlobImage) {
            Write-Host -ForegroundColor DarkGray '========================================================================='
            Write-Host -ForegroundColor Green 'Start-OSDCloudAzure'
            & "$($MyInvocation.MyCommand.Module.ModuleBase)\Projects\OSDCloudAzure\MainWindow.ps1"
            Start-Sleep -Seconds 2
    
            if ($Global:StartOSDCloud.AzOSDCloudImage) {
                Write-Host -ForegroundColor DarkGray '========================================================================='
                Write-Host -ForegroundColor Green "Invoke-OSDCloud ... Starting in 5 seconds..."
                Start-Sleep -Seconds 5
                Invoke-OSDCloud
            }
            else {
                Write-Warning "Unable to get a Windows Image from OSDCloudAzure to handoff to Invoke-OSDCloud"
            }
        }
        else {
            Write-Warning 'Unable to find resources to OSDCloudAzure'
        }
    }
    else {
        Write-Warning "OSDCloudAzure must be run from WinPE"
    }
}
Export-ModuleMember -Function @('Connect-OSDCloudAzure','Get-OSDCloudAzureResources','Initialize-OSDCloudAzure')