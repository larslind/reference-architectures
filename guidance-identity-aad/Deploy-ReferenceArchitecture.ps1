#
# Deploy_ReferenceArchitecture.ps1
#
param(
  [Parameter(Mandatory=$true)]
  $SubscriptionId,

  [Parameter(Mandatory=$false)]
  $Location = "eastus",

  [Parameter(Mandatory=$false)]
  [ValidateSet("Windows", "Linux")]
  $OSType = "Windows",

  [Parameter(Mandatory=$true)]
  [ValidateSet("onpremise", "ntier")]
  $Mode
)

$ErrorActionPreference = "Stop"

$templateRootUriString = $env:TEMPLATE_ROOT_URI
if ($templateRootUriString -eq $null) {
  $templateRootUriString = "https://raw.githubusercontent.com/mspnp/template-building-blocks/master/"
}
if (![System.Uri]::IsWellFormedUriString($templateRootUriString, [System.UriKind]::Absolute)) {
  throw "Invalid value for TEMPLATE_ROOT_URI: $env:TEMPLATE_ROOT_URI"
}
Write-Host
Write-Host "Using $templateRootUriString to locate templates"
Write-Host

$templateRootUri = New-Object System.Uri -ArgumentList @($templateRootUriString)
$virtualNetworkTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, 'templates/buildingBlocks/vnet-n-subnet/azuredeploy.json')
$virtualMachineTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, 'templates/buildingBlocks/multi-vm-n-nic-m-storage/azuredeploy.json')
$virtualMachineExtensionsTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/virtualMachine-extensions/azuredeploy.json")
$loadBalancedVmSetTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, 'templates/buildingBlocks/loadBalancer-backend-n-vm/azuredeploy.json')
$networkSecurityGroupTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, 'templates/buildingBlocks/networkSecurityGroups/azuredeploy.json')

# Login to Azure and select your subscription
Login-AzureRmAccount -SubscriptionId $SubscriptionId | Out-Null

if ($Mode -eq "onpremise") {
	# Azure Onpremise Parameter Files
	$onpremiseVirtualNetworkParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\onpremise\virtualNetwork.parameters.json")
	$onpremiseVirtualNetworkDnsParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\onpremise\virtualNetwork-adds-dns.parameters.json")
	$onpremiseADDSVirtualMachinesParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\onpremise\virtualMachines-adds.parameters.json")
	$onpremiseCreateAddsForestExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\onpremise\create-adds-forest-extension.parameters.json")
	$onpremiseAddAddsDomainControllerExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\onpremise\add-adds-domain-controller.parameters.json")
	$onpremisJoinDomainExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\onpremise\virtualMachines-adc-joindomain.parameters.json")

	$azureAdcVirtualMachinesParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\onpremise\virtualMachines-adc.parameters.json")



	$onpremiseNetworkResourceGroupName = "ra-aad-onpremise-rg"

	# Azure Onpremise Deployments
    $onpremiseNetworkResourceGroup = New-AzureRmResourceGroup -Name $onpremiseNetworkResourceGroupName -Location $Location
    Write-Host "Creating onpremise virtual network..."
    New-AzureRmResourceGroupDeployment -Name "ra-aad-onpremise-vnet-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName -TemplateUri $virtualNetworkTemplate.AbsoluteUri `
        -TemplateParameterFile $onpremiseVirtualNetworkParametersFile

    Write-Host "Deploying AD Connect servers..."
    New-AzureRmResourceGroupDeployment -Name "ra-aad-onpremise-adc-deployment" `
		-ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $azureAdcVirtualMachinesParametersFile

    Write-Host "Deploying ADDS servers..."
    New-AzureRmResourceGroupDeployment -Name "ra-aad-onpremise-adds-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $onpremiseADDSVirtualMachinesParametersFile

    # Remove the Azure DNS entry since the forest will create a DNS forwarding entry.
    Write-Host "Updating virtual network DNS servers..."
    New-AzureRmResourceGroupDeployment -Name "ra-aad-onpremise-dns-vnet-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName -TemplateUri $virtualNetworkTemplate.AbsoluteUri `
        -TemplateParameterFile $onpremiseVirtualNetworkDnsParametersFile

    Write-Host "Creating ADDS forest..."
    New-AzureRmResourceGroupDeployment -Name "ra-aad-onpremise-adds-forest-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $onpremiseCreateAddsForestExtensionParametersFile

    Write-Host "Creating ADDS domain controller..."
    New-AzureRmResourceGroupDeployment -Name "ra-aad-onpremise-adds-dc-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $onpremiseAddAddsDomainControllerExtensionParametersFile

    Write-Host "Join AD Connect servers to Domain......"
    New-AzureRmResourceGroupDeployment -Name "ra-aad-onpremise-adds-dc-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $onpremisJoinDomainExtensionParametersFile
}
elseif ($Mode -eq "ntier") {

	$resourceGroupName = "ra-aad-ntier-rg"

	# Template parameters for respective deployments
	$virtualNetworkParametersFile = [System.IO.Path]::Combine($PSScriptRoot, 'parameters', $OSType.ToLower(), 'virtualNetwork.parameters.json')
	$businessTierParametersFile = [System.IO.Path]::Combine($PSScriptRoot, 'parameters', $OSType.ToLower(), 'businessTier.parameters.json')
	$dataTierParametersFile = [System.IO.Path]::Combine($PSScriptRoot, 'parameters', $OSType.ToLower(), 'dataTier.parameters.json')
	$webTierParametersFile = [System.IO.Path]::Combine($PSScriptRoot, 'parameters', $OSType.ToLower(), 'webTier.parameters.json')
	$managementTierParametersFile = [System.IO.Path]::Combine($PSScriptRoot, 'parameters', $OSType.ToLower(), 'managementTier.parameters.json')
	$networkSecurityGroupParametersFile = [System.IO.Path]::Combine($PSScriptRoot, 'parameters', $OSType.ToLower(), 'networkSecurityGroups.parameters.json')


	# Login to Azure and select your subscription
	Login-AzureRmAccount -SubscriptionId $SubscriptionId | Out-Null

	# Create the resource group
	$resourceGroup = New-AzureRmResourceGroup -Name $resourceGroupName -Location $Location

	Write-Host "Deploying virtual network..."
	New-AzureRmResourceGroupDeployment -Name "ra-aad-ntier-vnet-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
		-TemplateUri $virtualNetworkTemplate.AbsoluteUri -TemplateParameterFile $virtualNetworkParametersFile

	Write-Host "Deploying business tier..."
	New-AzureRmResourceGroupDeployment -Name "ra-aad-ntier-biz-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
		-TemplateUri $loadBalancedVmSetTemplate.AbsoluteUri -TemplateParameterFile $businessTierParametersFile

	Write-Host "Deploying data tier..."
	New-AzureRmResourceGroupDeployment -Name "ra-aad-ntier-data-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
		-TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $dataTierParametersFile

	Write-Host "Deploying web tier..."
	New-AzureRmResourceGroupDeployment -Name "ra-aad-ntier-web-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
		-TemplateUri $loadBalancedVmSetTemplate.AbsoluteUri -TemplateParameterFile $webTierParametersFile

	Write-Host "Deploying management tier..."
	New-AzureRmResourceGroupDeployment -Name "ra-aad-ntier-mgmt-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
		-TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $managementTierParametersFile

	Write-Host "Deploying network security group"
	New-AzureRmResourceGroupDeployment -Name "ra-aad-ntier-nsg-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
		-TemplateUri $networkSecurityGroupTemplate.AbsoluteUri -TemplateParameterFile $networkSecurityGroupParametersFile
}
