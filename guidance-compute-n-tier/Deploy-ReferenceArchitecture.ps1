#
# Deploy_ReferenceArchitecture.ps1
#
param(
  [Parameter(Mandatory=$true)]
  $SubscriptionId,
  [Parameter(Mandatory=$false)]
  $Location = "East US 2"
)

$OSType = "Linux"

$ErrorActionPreference = "Stop"

$templateRootUriString = $env:TEMPLATE_ROOT_URI
if ($templateRootUriString -eq $null) {
  $templateRootUriString = "https://raw.githubusercontent.com/larslind/template-building-blocks/master/"
}

if (![System.Uri]::IsWellFormedUriString($templateRootUriString, [System.UriKind]::Absolute)) {
  throw "Invalid value for TEMPLATE_ROOT_URI: $env:TEMPLATE_ROOT_URI"
}

Write-Host
Write-Host "Using $templateRootUriString to locate templates"
Write-Host

Write-Host
Write-Host "Using $PSScriptRoot to locate parameters"
Write-Host

# Deployer templates for respective resources
$templateRootUri = New-Object System.Uri -ArgumentList @($templateRootUriString)
$virtualNetworkTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, 'templates/buildingBlocks/vnet-n-subnet/azuredeploy.json')
$loadBalancedVmSetTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, 'templates/buildingBlocks/loadBalancer-backend-n-vm/azuredeploy.json')
$virtualMachineTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, 'templates/buildingBlocks/multi-vm-n-nic-m-storage/azuredeploy.json')
$networkSecurityGroupTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, 'templates/buildingBlocks/networkSecurityGroups/azuredeploy.json')
$availabilitySetTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, 'templates/resources/Microsoft.Compute/virtualMachines/availabilitySet-new.json')

# Template parameters for respective deployments
$virtualNetworkNodesParametersFile = [System.IO.Path]::Combine($PSScriptRoot, 'parameters', $OSType.ToLower(), 'virtualNetworkNodes.parameters.json')
$virtualNetworkMgmtParametersFile = [System.IO.Path]::Combine($PSScriptRoot, 'parameters', $OSType.ToLower(), 'virtualNetworkManagement.parameters.json')
$businessTierParametersFile = [System.IO.Path]::Combine($PSScriptRoot, 'parameters', $OSType.ToLower(), 'businessTier.parameters.json')
$dataTierParametersFile = [System.IO.Path]::Combine($PSScriptRoot, 'parameters', $OSType.ToLower(), 'dataTier.parameters.json')
$webTierParametersFile = [System.IO.Path]::Combine($PSScriptRoot, 'parameters', $OSType.ToLower(), 'webTier.parameters.json')
$managementTierJumpboxParametersFile = [System.IO.Path]::Combine($PSScriptRoot, 'parameters', $OSType.ToLower(), 'managementTierJumpbox.parameters.json')
$managementTierOpsParametersFile = [System.IO.Path]::Combine($PSScriptRoot, 'parameters', $OSType.ToLower(), 'managementTierOps.parameters.json')
$networkSecurityGroupParametersFile = [System.IO.Path]::Combine($PSScriptRoot, 'parameters', $OSType.ToLower(), 'networkSecurityGroups.parameters.json')
$availabilitySetParametersFile = [System.IO.Path]::Combine($PSScriptRoot, 'parameters', $OSType.ToLower(), 'availabilitySet.parameters.json')

$resourceGroupName = "ra-ntier-cassandra-rg"

# Login to Azure and select your subscription
Login-AzureRmAccount -SubscriptionId $SubscriptionId | Out-Null

# Create the resource group
$resourceGroup = New-AzureRmResourceGroup -Name $resourceGroupName -Location $Location

Write-Host "Deploying virtual network for nodes..."
New-AzureRmResourceGroupDeployment -Name "ra-ntier-nodes-vnet-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $virtualNetworkTemplate.AbsoluteUri -TemplateParameterFile $virtualNetworkNodesParametersFile

Write-Host "Deploying virtual network for management..."
New-AzureRmResourceGroupDeployment -Name "ra-ntier-mgmt-vnet-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $virtualNetworkTemplate.AbsoluteUri -TemplateParameterFile $virtualNetworkMgmtParametersFile    

Write-Host "Deploying availability set for data tier..."
New-AzureRmResourceGroupDeployment -Name "ra-ntier-data-avset-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $availabilitySetTemplate.AbsoluteUri -TemplateParameterFile $availabilitySetParametersFile

Write-Host "Deploying business tier..."
New-AzureRmResourceGroupDeployment -Name "ra-ntier-biz-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $loadBalancedVmSetTemplate.AbsoluteUri -TemplateParameterFile $businessTierParametersFile

Write-Host "Deploying data tier..."
New-AzureRmResourceGroupDeployment -Name "ra-ntier-data-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $dataTierParametersFile

Write-Host "Deploying web tier..."
New-AzureRmResourceGroupDeployment -Name "ra-ntier-web-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $loadBalancedVmSetTemplate.AbsoluteUri -TemplateParameterFile $webTierParametersFile

Write-Host "Deploying jumpbox in management tier..."
New-AzureRmResourceGroupDeployment -Name "ra-ntier-mgmt-jb-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $managementTierJumpboxParametersFile

Write-Host "Deploying operations center in management tier..."
New-AzureRmResourceGroupDeployment -Name "ra-ntier-mgmt-ops-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $managementTierOpsParametersFile

Write-Host "Deploying network security group"
New-AzureRmResourceGroupDeployment -Name "ra-ntier-nsg-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $networkSecurityGroupTemplate.AbsoluteUri -TemplateParameterFile $networkSecurityGroupParametersFile
