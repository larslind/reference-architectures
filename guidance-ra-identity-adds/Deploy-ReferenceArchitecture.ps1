#
# Deploy_ReferenceArchitecture.ps1
#
param(
  [Parameter(Mandatory=$true)]
  $SubscriptionId,
  [Parameter(Mandatory=$true)]
  $Location,
  [Parameter(Mandatory=$true)]
  [ValidateSet("Onpremise", "Infrastructure", "AzureADDS")]
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

$loadBalancerTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/loadBalancer-backend-n-vm/azuredeploy.json")
$virtualNetworkTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/vnet-n-subnet/azuredeploy.json")
$virtualMachineTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/multi-vm-n-nic-m-storage/azuredeploy.json")
$dmzTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/dmz/azuredeploy.json")
$virtualNetworkGatewayTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/vpn-gateway-vpn-connection/azuredeploy.json")
$virtualMachineExtensionsTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/virtualMachine-extensions/azuredeploy.json")

# Azure Onpremise Parameter Files
$onpremiseVirtualNetworkParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\virtualNetwork-onpremise.parameters.json")
$onpremiseADDSVirtualMachinesParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\virtualMachines-onpremise.parameters.json")
$onpremiseRRASVirtualMachinesParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\virtualMachines-onpremise-rras.parameters.json")
$installAddsExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\create-adds-forest-extension.parameters.json")

# Azure ADDS Parameter Files
$virtualNetworkGatewayParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\virtualNetworkGateway.parameters.json")
$virtualNetworkParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\virtualNetwork.parameters.json")
$virtualNetworkOnpremiseDnsParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\virtualNetwork-with-onpremise-dns.parameters.json")
$virtualNetworkOnpremiseAndAzureDnsParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\virtualNetwork-with-onpremise-and-azure-dns.parameters.json")
$webLoadBalancerParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\loadBalancer-web.parameters.json")
$bizLoadBalancerParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\loadBalancer-biz.parameters.json")
$dataLoadBalancerParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\loadBalancer-data.parameters.json")
$managementParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\virtualMachines-mgmt.parameters.json")
$privateDmzParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\dmz-private.parameters.json")
$publicDmzParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\dmz-public.parameters.json")
$addsVirtualMachinesParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\virtualMachines-adds.parameters.json")

# Azure Onpremise Deployments
$onpremiseNetworkResourceGroupName = "ra-adds-onpremise-rg"

# Azure ADDS Deployments
$networkResourceGroupName = "ra-adds-network-rg"
$workloadResourceGroupName = "ra-adds-wl-rg"
$securityResourceGroupName = "ra-adds-security-rg"
$addsResourceGroupName = "ra-adds-adds-rg"

# Login to Azure and select your subscription
Login-AzureRmAccount -SubscriptionId $SubscriptionId | Out-Null

if ($Mode -eq "Onpremise") {
    $onpremiseNetworkResourceGroup = New-AzureRmResourceGroup -Name $onpremiseNetworkResourceGroupName -Location $Location
    Write-Host "Creating Onpremise virtual network..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-onpremise-vnet-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName -TemplateUri $virtualNetworkTemplate.AbsoluteUri `
        -TemplateParameterFile $onpremiseVirtualNetworkParametersFile

    Write-Host "Deploying ADDS servers..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-onpremise-adds-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $onpremiseVirtualNetworkParametersFile

    Write-Host "Deploying RRAS server..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-onpremise-rras-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $onpremiseRRASVirtualMachinesParametersFile

    Write-Host "Creating ADDS forest..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-onpremise-adds-forest-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $onpremiseRRASVirtualMachinesParametersFile
}
elseif ($Mode -eq "Infrastructure") {
    Write-Host "Creating ADDS resource group..."
    $networkResourceGroup = New-AzureRmResourceGroup -Name $networkResourceGroupName -Location $Location

    # Deploy network infrastructure
    Write-Host "Deploying virtual network..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-vnet-deployment" -ResourceGroupName $networkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualNetworkTemplate.AbsoluteUri -TemplateParameterFile $virtualNetworkParametersFile

    Write-Host "Deploying private DMZ..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-dmz-private-deployment" -ResourceGroupName $networkResourceGroup.ResourceGroupName `
        -TemplateUri $dmzTemplate.AbsoluteUri -TemplateParameterFile $privateDmzParametersFile

    Write-Host "Deploying public DMZ..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-dmz-public-deployment" -ResourceGroupName $networkResourceGroup.ResourceGroupName `
        -TemplateUri $dmzTemplate.AbsoluteUri -TemplateParameterFile $publicDmzParametersFile

    Write-Host "Deploying Virtual Network Gateway..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-dmz-public-deployment" -ResourceGroupName $networkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualNetworkGatewayTemplate.AbsoluteUri -TemplateParameterFile $virtualNetworkGatewayParametersFile

    # Deploy workload tiers
    Write-Host "Creating workload resource group..."
    $workloadResourceGroup = New-AzureRmResourceGroup -Name $workloadResourceGroupName -Location $Location

    Write-Host "Deploying web load balancer..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-web-deployment" -ResourceGroupName $workloadResourceGroup.ResourceGroupName `
        -TemplateUri $loadBalancerTemplate.AbsoluteUri -TemplateParameterFile $webLoadBalancerParametersFile

    Write-Host "Deploying biz load balancer..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-biz-deployment" -ResourceGroupName $workloadResourceGroup.ResourceGroupName `
        -TemplateUri $loadBalancerTemplate.AbsoluteUri -TemplateParameterFile $bizLoadBalancerParametersFile

    Write-Host "Deploying data load balancer..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-data-deployment" -ResourceGroupName $workloadResourceGroup.ResourceGroupName `
        -TemplateUri $loadBalancerTemplate.AbsoluteUri -TemplateParameterFile $dataLoadBalancerParametersFile

    # Deploy security infrastructure
    Write-Host "Creating security resource group..."
    $securityResourceGroup = New-AzureRmResourceGroup -Name $securityResourceGroupName -Location $Location

    Write-Host "Deploying jumpbox..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-jumpbox-deployment" -ResourceGroupName $securityResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $managementParametersFile
}
elseif ($Mode -eq "AzureADDS") {
    $networkResourceGroup = Get-AzureRmResourceGroup -Name $networkResourceGroupName
    # Update DNS server to point to onpremise
    Write-Host "Updating virtual network DNS..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-vnet-onpremise-dns-deployment" -ResourceGroupName $networkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualNetworkTemplate.AbsoluteUri -TemplateParameterFile $virtualNetworkOnpremiseDnsParametersFile

    # Deploy AD tier
    Write-Host "Creating ADDS resource group..."
    $addsResourceGroup = New-AzureRmResourceGroup -Name $addsResourceGroupName -Location $Location

    Write-Host "Deploying ADDS servers..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-adds-deployment" -ResourceGroupName $addsResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $addsVirtualMachinesParametersFile

    # Update DNS server to point to onpremise and azure
    Write-Host "Updating virtual network DNS..."
    New-AzureRmResourceGroupDeployment -Name "ra-adds-vnet-onpremise-azure-dns-deployment" -ResourceGroupName $networkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualNetworkTemplate.AbsoluteUri -TemplateParameterFile $virtualNetworkOnpremiseAndAzureDnsParametersFile
}