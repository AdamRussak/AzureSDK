- [AzureSDK](#azuresdk)
  * [Azure Storage Explor](#azure-storage-explor)
    + [Pre-requsit](#pre-requsit)
    + [Script General Information](#script-general-information)
    + [How To use:](#how-to-use)

# AzureSDK
*Scripts to use in Azure*

[Azure Blob Explorer](https://github.com/AdamRussak/AzureSDK/blob/master/azure_blob_explorer.ps1)
[Azure Blob Explorer V0.3.1](https://github.com/AdamRussak/AzureSDK/blob/master/azure_blob_explorerV0.3.1.ps1)

### Added in V0.3.1
- Output level Selection in UI
  * Full or Container Level

## Azure Storage Explor
This script will list out all your Blob Storage in to either: CSV/ HTML/ CLI.
The script can be run either on the Subscription (all Storage accounts Under that subscription) or on a selected Storage Account.
the Script will list out: 
- Resource Group Name
- Storage Account Name
- Container Name
- Container Size
- Blob Name
- Blob Size
- - if Blob is a VHD, it will list if Blob is **Leased** or **Unlocked**
### Pre-requsit
- [ ] **Script is using AZ module that need to be installed before using this script**
### Script General Information
  - [ ] List all Blobs in Storage Account
  - [ ] List all Blobs in Subscription
  - [ ] List the Information in 1 of 3 options: CSV, HTML, Command Line Output
### How To use:
  - [ ] Download the link/ Copy Repo
  - [ ] Run the Script
  
