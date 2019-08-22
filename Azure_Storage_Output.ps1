<#
Writen By: Adam Russak
Version: 0.2.6v

.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE
    Another example of how to use this cmdlet
.INPUTS
    Inputs to this cmdlet (if any)
.OUTPUTS
    Output from this cmdlet (if any)
.NOTES
    General notes
.COMPONENT
    The component this cmdlet belongs to
.ROLE
    The role this cmdlet belongs to
.FUNCTIONALITY
    The functionality that best describes this cmdlet


Description:

-- The Script will generate an output with all Blobs in storage account with size and container the blob is in.
-- Output parameters:
    = Container
    = Blob Name
    = Size (KB,GB,TB)

    - Script assume you are connected to Azure
    - Script uses AZ PowerShell Module
    Process:
    ---------------------------------------------------
    - At the start of the script you will need to select
        - 1: Entire Subscriptions
        - 2: Limit To a specific Storage Account
            - if selected specific Storage Account, you will be requerd to suplly the Storage Account Name
    - Second Step
        - 1: CSV Output
        - 2: HTML Output
        - 3: CLI Output

#>
Function Format-FileSize() {
    Param ([object]$BlobSize)
    If ($BlobSize -gt 1TB) {[string]::Format("{0:0.00} TB", $BlobSize / 1TB)}
    ElseIf ($BlobSize -gt 1GB) {[string]::Format("{0:0.00} GB", $BlobSize / 1GB)}
    ElseIf ($BlobSize -gt 1MB) {[string]::Format("{0:0.00} MB", $BlobSize / 1MB)}
    ElseIf ($BlobSize -gt 1KB) {[string]::Format("{0:0.00} kB", $BlobSize / 1KB)}
    ElseIf ($BlobSize -gt 0) {[string]::Format("{0:0.00} B", $BlobSize)}
    Else {""}
    }
function ConnectionCheck {
    try {
        $all_subscriptions = Get-AzSubscription
        $title = "Azure subscriptions"
        $message = "Please pick a subscription"
        $all_subscriptions = Get-AzSubscription
        $fileChoices = @()
        for ($i=0; $i -lt $all_subscriptions.Count; $i++) {
            $fileChoices += [System.Management.Automation.Host.ChoiceDescription]("$($all_subscriptions[$i].Name) &$($i+1)")
        }
        Clear-Host
        $result = $host.ui.PromptForChoice($title, $message, $fileChoices, 0)
        Set-AzContext -Subscription $($all_subscriptions[$result].Name)
    }
    catch {
        Connect-AzAccount
        $title = "Azure subscriptions"
        $message = "Please pick a subscription"
        $all_subscriptions = Get-AzSubscription
        $fileChoices = @()
        for ($i=0; $i -lt $all_subscriptions.Count; $i++) {
            $fileChoices += [System.Management.Automation.Host.ChoiceDescription]("$($all_subscriptions[$i].Name) &$($i+1)")
        }
        Clear-Host
        $result = $host.ui.PromptForChoice($title, $message, $fileChoices, 0)
        Set-AzContext -Subscription $($all_subscriptions[$result].Name)
    }
    finally {
        Clear-Host
        $subOutput = (Get-AzContext).Subscription.Name
        "Current Subscription is $subOutput"
    }
}
function SubscriptionBlobSearch {
    $storageAcc = Get-AzStorageAccount
    $list = foreach ($Storage in $storageAcc) {
        $SASkey = (Get-AzStorageAccountKey -ResourceGroupName $Storage.ResourceGroupName -AccountName $Storage.storageAccountName).Value[0]
        $destinationContext = New-AzStorageContext -StorageAccountName $Storage.storageAccountName -StorageAccountKey $SASkey
        $Containers = Get-AzStorageContainer -Context $destinationContext
        ForEach ($CList in $Containers) {
            $BlobList = (Get-AzStorageBlob -Context $destinationContext -Container $CList.Name)
            if ($null -ne $BlobList) {
                $length = 0
                $BlobList | ForEach-Object {$length = $length + $_.Length}
                $containerSize = Format-FileSize($length)
                [PSCustomObject]@{
                    "Resource Group" = $Storage.ResourceGroupName
                    "Storage Account" = $Storage.storageAccountName
                    "Container" = $CList.name
                    "Blob Name" =  " "
                    "Size" = " "
                    "Total Container Size" = $containerSize
                    "Status" = " "
                }
                ForEach ($Blob in $BlobList){
                    $blobname = (Get-AzStorageBlob -Context $destinationContext -Container $CList.Name) | Where-Object{$_.Name -like $blob.Name}
                    $BlobSize = Format-FileSize($Blob.Length)
                    if ($Blob.Name.EndsWith(".vhd")) {
                        if ($Blob.ICloudBlob.Properties.LeaseStatus -eq "Locked") {
                            [PSCustomObject]@{
                                "Resource Group" = $storage.ResourceGroupName
                                "Storage Account" = $storage.storageAccountName
                                "Container" = $CList.name
                                "Blob Name" = $blobname.Name
                                "Size" = $BlobSize
                                "Total Container Size" = " "
                                "Status" = "Leased"
                            }
                        }
                        elseif ($Blob.ICloudBlob.Properties.LeaseStatus -eq "Unlocked") {
                            [PSCustomObject]@{
                                "Resource Group" = $storage.ResourceGroupName
                                "Storage Account" = $storage.storageAccountName
                                "Container" = $CList.name
                                "Blob Name" = $blobname.Name
                                "Size" = $BlobSize
                                "Total Container Size" = " "
                                "Status" = "Unlocked"
                            }
                        }
                    }
                    else {
                        [PSCustomObject]@{
                            "Resource Group" = $storage.ResourceGroupName
                            "Storage Account" = $storage.storageAccountName
                            "Container" = $CList.name
                            "Blob Name" = $blobname.Name
                            "Size" = $BlobSize
                            "Total Container Size" = " "
                            "Status" = " "
                        }
                    }
                }
            }
            if ($null -eq $BlobList) {
                if ($EmptyContainerAcction -like "Ignor") {
                    [PSCustomObject]@{
                        "Resource Group" = $storage.ResourceGroupName
                        "Storage Account" = $storage.storageAccountName
                        "Container" = $CList.Name
                        "Blob Name" = "Empty Container"
                        "Size" = " "
                        "Total Container Size" = " "
                        "Status" = " "
                    }
                }
            if ($EmptyContainerAcction -like "Remove") {
                Remove-AzStorageContainer -Name $CList.Name -Context $destinationContext -Force
                [PSCustomObject]@{
                    "Resource Group" = $storage.ResourceGroupName
                    "Storage Account" = $storage.storageAccountName
                    "Container" = $CList.Name
                    "Blob Name" = "Empty Container"
                    "Size" = "Deleted"
                    "Total Container Size" = "Deleted"
                    "Status" = " "
                }
            }
            if ($EmptyContainerAcction -like "Prompt") {
                Remove-AzStorageContainer -Name $CList.Name -Context $destinationContext -Confirm
                $removeCheck = (Get-AzStorageContainer -Name $CList.name -Context $destinationContext).Name
                if ($CList.name -notlike $removeCheck) {
                    [PSCustomObject]@{
                        "Resource Group" = $storage.ResourceGroupName
                        "Storage Account" = $storage.storageAccountName
                        "Container" = $CList.Name
                        "Blob Name" = "Empty Container"
                        "Size" = "Deleted"
                        "Total Container Size" = "Deleted"
                        "Status" = " "
                    }
                }
                if ($CList.name -like $removeCheck) {
                    [PSCustomObject]@{
                        "Resource Group" = $storage.ResourceGroupName
                        "Storage Account" = $storage.storageAccountName
                        "Container" = $CList.Name
                        "Blob Name" = "Empty Container"
                        "Size" = " "
                        "Total Container Size" = " "
                        "Status" = " "
                    }
                }
            }
        }
    }
    }
    return $list
}
function SpecificStorageAccount {
    Clear-Host
    $title = "Azure Storage Account"
    $message = "Please pick a Storage Account"
    $all_subscriptions = Get-AzStorageAccount
    $fileChoices = @()
    for ($i=0; $i -lt $all_subscriptions.Count; $i++) {
        $fileChoices += [System.Management.Automation.Host.ChoiceDescription]("$($all_subscriptions[$i].StorageAccountName) &$($i+1)")
    }
    Clear-Host
    $result2 = $host.ui.PromptForChoice($title, $message, $fileChoices, 0)
    $storageAccInput = $($all_subscriptions[$result2].StorageAccountName)
    $storageAcc = Get-AzStorageAccount
    $LimitSearch2 = $storageAcc | Where-Object{$_.storageAccountName -like $storageAccInput}
    $SASkey = (Get-AzStorageAccountKey -ResourceGroupName $LimitSearch2.ResourceGroupName -AccountName $storageAccInput).Value[0]
    $destinationContext = New-AzStorageContext -StorageAccountName $storageAccInput -StorageAccountKey $SASkey
    $Containers = Get-AzStorageContainer -Context $destinationContext
    $list = ForEach ($CList in $Containers) {
        $BlobList = (Get-AzStorageBlob -Context $destinationContext -Container $CList.Name)
        if ($null -ne $BlobList) {
            $length = 0
            $BlobList | ForEach-Object {$length = $length + $_.Length}
            $containerSize = Format-FileSize($length)
            [PSCustomObject]@{
                "Resource Group" = $LimitSearch2.ResourceGroupName
                "Storage Account" = $LimitSearch2.storageAccountName
                "Container" = $CList.name
                "Blob Name" =  "-"
                "Size" = "-"
                "Total Container Size" = $containerSize
                "Status" = "-"
            }
            ForEach ($Blob in $BlobList){
                $blobname = (Get-AzStorageBlob -Context $destinationContext -Container $CList.Name) | Where-Object{$_.Name -like $blob.Name}
                $bloburl = $blobname.ICloudBlob.uri.AbsoluteUri
                $containerName = $bloburl.Split("{/}")[3]
                $BlobSize = Format-FileSize($Blob.Length)
                if ($Blob.Name.EndsWith(".vhd")) {
                    if ($Blob.ICloudBlob.Properties.LeaseStatus -eq "Locked") {
                        [PSCustomObject]@{
                            "Resource Group" = $LimitSearch2.ResourceGroupName
                            "Storage Account" = $LimitSearch2.storageAccountName
                            "Container" = $containerName
                            "Blob Name" = $blobname.Name
                            "Size" = $BlobSize
                            "Total Container Size" = "-"
                            "Status" = "Leased"
                        }
                    }
                    if ($Blob.ICloudBlob.Properties.LeaseStatus -eq "Unlocked") {
                        [PSCustomObject]@{
                            "Resource Group" = $LimitSearch2.ResourceGroupName
                            "Storage Account" = $LimitSearch2.storageAccountName
                            "Container" = $containerName
                            "Blob Name" = $blobname.Name
                            "Size" = $BlobSize
                            "Total Container Size" = "-"
                            "Status" = "Unlocked"
                        }
                    }
                }
                else {
                    [PSCustomObject]@{
                        "Resource Group" = $LimitSearch2.ResourceGroupName
                        "Storage Account" = $LimitSearch2.storageAccountName
                        "Container" = $containerName
                        "Blob Name" = $blobname.Name
                        "Size" = $BlobSize
                        "Total Container Size" = "-"
                        "Status" = "-"
                    }
                }
            }
        }
        if ($null -eq $BlobList) {
            if ($EmptyContainerAcction -like "Ignor") {
                [PSCustomObject]@{
                    "Resource Group" = $LimitSearch2.ResourceGroupName
                    "Storage Account" = $LimitSearch2.storageAccountName
                    "Container" = $CList.Name
                    "Blob Name" = "Empty Container"
                    "Size" = "-"
                    "Total Container Size" = "-"
                    "Status" = "-"
                }
            }
            if ($EmptyContainerAcction -like "Remove") {
                Remove-AzStorageContainer -Name $CList.Name -Context $destinationContext -Force
                [PSCustomObject]@{
                    "Resource Group" = $LimitSearch2.ResourceGroupName
                    "Storage Account" = $LimitSearch2.storageAccountName
                    "Container" = $CList.Name
                    "Blob Name" = "Empty Container"
                    "Size" = "Deleted"
                    "Total Container Size" = "Deleted"
                    "Status" = "-"
                }
            }
            if ($EmptyContainerAcction -like "Prompt") {
                Remove-AzStorageContainer -Name $CList.Name -Context $destinationContext -Confirm
                $removeCheck = (Get-AzStorageContainer -Name $CList.name -Context $destinationContext).Name
                if ($CList.name -notlike $removeCheck) {
                    [PSCustomObject]@{
                        "Resource Group" = $LimitSearch2.ResourceGroupName
                        "Storage Account" = $LimitSearch2.storageAccountName
                        "Container" = $CList.Name
                        "Blob Name" = "Empty Container"
                        "Size" = "Deleted"
                        "Total Container Size" = "Deleted"
                        "Status" = "-"
                    }
                }
                if ($CList.name -like $removeCheck) {
                    [PSCustomObject]@{
                        "Resource Group" = $LimitSearch2.ResourceGroupName
                        "Storage Account" = $LimitSearch2.storageAccountName
                        "Container" = $CList.Name
                        "Blob Name" = "Empty Container"
                        "Size" = "-"
                        "Total Container Size" = "-"
                        "Status" = "-"
                    }
                }
            }
        }
    }
return $list
}
function header{
 $style = @"
 <style>
 body{
 font-family: Verdana, Geneva, Arial, Helvetica, sans-serif;
 }

 table{
  border-collapse: collapse;
  border: none;
  font: 10pt Verdana, Geneva, Arial, Helvetica, sans-serif;
  color: black;
  margin-bottom: 10px;
 }

 table td{
  font-size: 10px;
  padding-left: 0px;
  padding-right: 20px;
  text-align: center;
 }

 table th{
  font-size: 10px;
  font-weight: bold;
  padding-left: 0px;
  padding-right: 20px;
  text-align: center;
 }

 h2{
  clear: both; font-size: 130%;color:#00134d;
 }

 p{
  margin-left: 10px; font-size: 12px;
 }

 table.list{
  float: left;
 }

 table tr:nth-child(even){background: #e6f2ff;}
 table tr:nth-child(odd) {background: #FFFFFF;}

 div.column {width: 320px; float: left;}
 div.first {padding-right: 20px; border-right: 1px grey solid;}
 div.second {margin-left: 30px;}

 table{
  margin-left: 10px;
 }
 ?>
 </style>
"@

 return [string] $style
 }
function QueryLimits {
      param (
            [string]$Title = 'Search Limits Menu'
      )
      Clear-Host
      Write-Host "Welcome to $Title"

      Write-Host "1: Entire Subscriptions"
      Write-Host "2: Limit To a specific Storage Account"
      Write-Host "Q: Press 'Q' to quit."
 }
function EmptyContainers {

    Clear-Host
    Write-Host "Select Empty Container Acction"

    Write-Host "1: Ignor"
    Write-Host "2: Auto Remove -- There will be no furture wornings"
    Write-Host "3: Prompt Approval Before removal"
    Write-Host "Q: Press 'Q' to quit."
}
function Output {
     param (
           [string]$Title = 'Output Selection Menu'
     )
     Clear-Host
     Write-Host "Welcome to $Title"

     Write-Host "1: CSV Output"
     Write-Host "2: HTML Output"
     Write-Host "3: CLI Output"
     Write-Host "Q: Press 'Q' to quit."
}
ConnectionCheck
QueryLimits
$input = Read-Host "Please select The Query Limits"
switch ($input) {
    '1' {
        EmptyContainers
        $QueryLimits = "Subscriptions"
            $input3 = Read-Host "Please Select Empty Container Acction"
            switch ($input3)
            {
                '1' {
                    Write-Host "Ignor Empty Container was Selected"
                    $EmptyContainerAcction = "Ignor"
                }'2' {
                    Write-Host "Auto Remove Empty Container was Selected"
                    $EmptyContainerAcction = "Remove"
                }'3' {
                    Write-Host "Prompt for Approval Before removing Empty Container was Selected"
                    $EmptyContainerAcction = "Prompt"
                }'q' {
                return
                }
            }
     }'2' {
        EmptyContainers
       $QueryLimits = "Storage Account"
       $input3 = Read-Host "Please Select Empty Container Acction"
       switch ($input3)
       {
           '1' {
               Write-Host "Ignor Empty Container was Selected"
               $EmptyContainerAcction = "Ignor"
           }'2' {
               Write-Host "Auto Remove Empty Container was Selected"
               $EmptyContainerAcction = "Remove"
           }'3' {
               Write-Host "Prompt for Approval Before removing Empty Container was Selected"
               $EmptyContainerAcction = "Prompt"
           }'q' {
           return
           }
       }
     }'q' {
       return
       }
}
Output
$input2 = Read-Host "Please select The Output Format"
switch ($input2) {
    '1' {
        Write-Host "CSV output Selected"
        $Outputmethod = "CSV"
     }'2' {
       Write-Host "HTML output Selected"
       $Outputmethod = "HTML"
     }'3'{
        Write-Host "CLI output Selected"
        $Outputmethod = "CLI"
     }'q' {
       return
       }
}
if ($QueryLimits -like "Subscriptions") {
    if ($Outputmethod -like "HTML") {
        #Report Title
        $TitleHeader = (Get-AzContext).Subscription.Name
        $title = "<h2>Blobs List and Size on Subscription $TitleHeader</h2>"
        $sortBy = "Storage Account"
        $filending = Get-Date -Format yyMMddH
        if (!(Test-Path -Path ((Get-ChildItem env:userprofile).value+"\Documents\AzureBlob"))) {
           New-Item -Path ((Get-ChildItem env:userprofile).value+"\Documents\AzureBlob") -ItemType Directory
           Clear-Host
        }
        $repPath=(Get-ChildItem env:userprofile).value+"\Documents\AzureBlob\Storage_" + "${filending}.html"
        SubscriptionBlobSearch | Sort-Object -Property @{Expression=$sortBy;Descending=$true} | ConvertTo-Html -Head $(header) -PreContent $title | Set-Content -Path $repPath -ErrorAction Stop
    }
    elseif ($Outputmethod -like "CSV") {
        $filending = Get-Date -Format yyMMddH
        if (!(Test-Path -Path ((Get-ChildItem env:userprofile).value+"\Documents\AzureBlob"))) {
           New-Item -Path ((Get-ChildItem env:userprofile).value+"\Documents\AzureBlob") -ItemType Directory
           Clear-Host
        }
        #export to CSV
        $repPath=(Get-ChildItem env:userprofile).value+"\Documents\AzureBlob\Storage_" + "${filending}.xls"
        SubscriptionBlobSearch | Export-Csv -Path $repPath -Delimiter `t -Encoding ASCII -NoTypeInformation
    }
    elseif ($Outputmethod -like "CLI") {
        SubscriptionBlobSearch
    }
}
if ($QueryLimits -like "Storage Account") {
    if ($Outputmethod -like "HTML") {
        $filending = Get-Date -Format yyMMddH
        if (!(Test-Path -Path ((Get-ChildItem env:userprofile).value+"\Documents\AzureBlob"))) {
           New-Item -Path ((Get-ChildItem env:userprofile).value+"\Documents\AzureBlob") -ItemType Directory
           Clear-Host
        }
        #Report Title
        $TitleHeader = (Get-AzContext).Subscription.Name
        $title = "<h2>Blobs List and Size on Subscription $TitleHeader</h2>"
        $sortBy = "Storage Account"
        $repPath=(Get-ChildItem env:userprofile).value+"\Documents\AzureBlob\Storage_" + "${filending}.html"
        SpecificStorageAccount | Sort-Object -Property @{Expression=$sortBy;Descending=$true} | ConvertTo-Html -Head $(header) -PreContent $title | Set-Content -Path $repPath -ErrorAction Stop
    }
    elseif ($Outputmethod -like "CSV") {
        $filending = Get-Date -Format yyMMddH
        if (!(Test-Path -Path ((Get-ChildItem env:userprofile).value+"\Documents\AzureBlob"))) {
           New-Item -Path ((Get-ChildItem env:userprofile).value+"\Documents\AzureBlob") -ItemType Directory
           Clear-Host
        }
        #export to CSV
        $repPath=(Get-ChildItem env:userprofile).value+"\Documents\AzureBlob\Storage_" + "${filending}.xls"
        SpecificStorageAccount | Export-Csv -Path $repPath -Delimiter `t -Encoding ASCII -NoTypeInformation
    }
    elseif ($Outputmethod -like "CLI") {
        SpecificStorageAccount
    }
}