#
# Deploy_ReferenceArchitecture.ps1
#
param(
  [Parameter(Mandatory=$true)]
  $SubscriptionId,
  [Parameter(Mandatory=$false)]
  $Location = "West US 2",
  [switch]$InstallActiveDirectory,
  [switch]$InstallAdfs,
  [switch]$InstallAdfsProxy
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

# Templates
$templateRootUri = New-Object System.Uri -ArgumentList @($templateRootUriString)
$loadBalancerTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/loadBalancer-backend-n-vm/azuredeploy.json")
$virtualMachineExtensionsTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/virtualMachine-extensions/azuredeploy.json")

# Template to configure ADFS
$configureAdForAdfsExtensionsParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\adfs\configure-ad-for-adfs.parameters.json")

# ADFS Template Parameters
$adfsLoadBalancerParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\loadBalancer-adfs.parameters.json")
$installAdfsExtensionsParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\adfs\install-adfs-farm.parameters.json")
$addAdfsExtensionsParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\adfs\add-adfs-farm-node.parameters.json")

# ADFS Proxy Template Parameters
$adfsProxyLoadBalancerParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\loadBalancer-adfs-proxy.parameters.json")
$installAdfsProxyExtensionsParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\adfs-proxy\install-adfs-proxy-application.parameters.json")
$addAdfsProxyExtensionsParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\adfs-proxy\add-adfs-proxy.parameters.json")

$adResourceGroupName = "ra-ad-ad-rg"
$adfsResourceGroupName = "ra-ad-adfs-rg"
$adfsProxyResourceGroupName = "ra-ad-adfs-proxy-rg"

# Login to Azure and select your subscription
Login-AzureRmAccount -SubscriptionId $SubscriptionId | Out-Null

if ($InstallAdfs) {
    Write-Host "Configuring AD for ADFS..."
    New-AzureRmResourceGroupDeployment -Name "ra-ad-configure-ad-for-adfs-deployment" -ResourceGroupName $adResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $configureAdForAdfsExtensionsParametersFile

    Write-Host "Creating ADFS resource group..."
    $adfsResourceGroup = New-AzureRmResourceGroup -Name $adfsResourceGroupName -Location $Location

    Write-Host "Deploying ADFS load balancer..."
    New-AzureRmResourceGroupDeployment -Name "ra-ad-adfs-deployment" -ResourceGroupName $adfsResourceGroup.ResourceGroupName `
        -TemplateUri $loadBalancerTemplate.AbsoluteUri -TemplateParameterFile $adfsLoadBalancerParametersFile

    Write-Host "Installing Primary ADFS Server..."
    New-AzureRmResourceGroupDeployment -Name "ra-ad-install-adfs-deployment" -ResourceGroupName $adfsResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $installAdfsExtensionsParametersFile

    Write-Host "Adding ADFS Servers..."
    New-AzureRmResourceGroupDeployment -Name "ra-ad-add-adfs-deployment" -ResourceGroupName $adfsResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $addAdfsExtensionsParametersFile
}

if ($InstallAdfsProxy) {
    Write-Host "Creating ADFS Proxy resource group..."
    $adfsProxyResourceGroup = New-AzureRmResourceGroup -Name $adfsProxyResourceGroupName -Location $Location

    Write-Host "Deploying ADFS Proxy load balancer..."
    New-AzureRmResourceGroupDeployment -Name "ra-ad-adfs-deployment" -ResourceGroupName $adfsProxyResourceGroup.ResourceGroupName `
        -TemplateUri $loadBalancerTemplate.AbsoluteUri -TemplateParameterFile $adfsProxyLoadBalancerParametersFile

    Write-Host "Installing Primary ADFS Proxy Server..."
    New-AzureRmResourceGroupDeployment -Name "ra-ad-install-adfs-proxy-deployment" -ResourceGroupName $adfsProxyResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $installAdfsProxyExtensionsParametersFile

    Write-Host "Adding ADFS Proxy Servers..."
    New-AzureRmResourceGroupDeployment -Name "ra-ad-add-adfs-proxy-deployment" -ResourceGroupName $adfsProxyResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $addAdfsProxyExtensionsParametersFile
}