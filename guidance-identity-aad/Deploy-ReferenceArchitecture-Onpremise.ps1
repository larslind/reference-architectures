#
# Deploy-ReferenceArchitecture-Onpremise.ps1
#
param(
  [Parameter(Mandatory=$true)]
  $SubscriptionId,
  [Parameter(Mandatory=$false)]
  $Location = "Central US",
)


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

$virtualNetworkTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/vnet-n-subnet/azuredeploy.json")
$virtualMachineTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/multi-vm-n-nic-m-storage/azuredeploy.json")
$virtualMachineExtensionsTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/virtualMachine-extensions/azuredeploy.json")

# Azure Onpremise Parameter Files
$onpremiseVirtualNetworkParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\onpremise\virtualNetwork.parameters.json")
$onpremiseVirtualNetworkDnsParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\onpremise\virtualNetwork-adds-dns.parameters.json")
$onpremiseADDSVirtualMachinesParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\onpremise\virtualMachines-adds.parameters.json")
$onpremiseCreateAddsForestExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\onpremise\create-adds-forest-extension.parameters.json")
$onpremiseAddAddsDomainControllerExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\onpremise\add-adds-domain-controller.parameters.json")
$onpremiseReplicationSiteForestExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\onpremise\create-azure-replication-site.parameters.json")
$onpremiseVirtualNetworkGatewayParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\onpremise\virtualNetworkGateway.parameters.json")
$onpremiseConnectionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\onpremise\connection.parameters.json")


# Azure Onpremise Deployments
$onpremiseNetworkResourceGroupName = "ra-aad-onpremise-rg"

# Login to Azure and select your subscription
Login-AzureRmAccount -SubscriptionId $SubscriptionId | Out-Null

    $onpremiseNetworkResourceGroup = New-AzureRmResourceGroup -Name $onpremiseNetworkResourceGroupName -Location $Location
    Write-Host "Creating onpremise virtual network..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-onpremise-vnet-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName -TemplateUri $virtualNetworkTemplate.AbsoluteUri `
        -TemplateParameterFile $onpremiseVirtualNetworkParametersFile

    Write-Host "Deploying ADDS servers..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-onpremise-adds-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $onpremiseADDSVirtualMachinesParametersFile

    # Remove the Azure DNS entry since the forest will create a DNS forwarding entry.
    Write-Host "Updating virtual network DNS servers..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-onpremise-dns-vnet-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName -TemplateUri $virtualNetworkTemplate.AbsoluteUri `
        -TemplateParameterFile $onpremiseVirtualNetworkDnsParametersFile

    Write-Host "Creating ADDS forest..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-onpremise-adds-forest-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $onpremiseCreateAddsForestExtensionParametersFile

    Write-Host "Creating ADDS domain controller..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-onpremise-adds-dc-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $onpremiseAddAddsDomainControllerExtensionParametersFile
