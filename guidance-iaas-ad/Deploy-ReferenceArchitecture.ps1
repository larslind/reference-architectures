#
# Deploy_ReferenceArchitecture.ps1
#
param(
  [Parameter(Mandatory=$true)]
  $SubscriptionId,
  [Parameter(Mandatory=$false)]
  $Location = "West US 2"
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
# Template to configure AD for ADFS
$virtualMachineExtensionsTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/virtualMachine-extensions/azuredeploy.json")
$virtualMachineExtensionsParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\adfs\configure-ad-for-adfs.parameters.json")

# ADFS Templates
$loadBalancerTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/loadBalancer-backend-n-vm/azuredeploy.json")
$loadBalancerParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\loadBalancer-adfs.parameters.json")

$adResourceGroupName = "ra-ad-ad-rg"
$adfsResourceGroupName = "ra-ad-adfs-rg"

# Login to Azure and select your subscription
Login-AzureRmAccount -SubscriptionId $SubscriptionId | Out-Null

#This works, but commented out for now so we can test the ADFS deployment.
#Write-Host "Configuring AD for ADFS..."
#New-AzureRmResourceGroupDeployment -Name "ra-ad-configure-ad-for-adfs-deployment" -ResourceGroupName $adResourceGroupName `
#    -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $virtualMachineExtensionsParametersFile

# Create the resource group
Write-Host "Creating ADFS resource group..."
$adfsResourceGroup = New-AzureRmResourceGroup -Name $adfsResourceGroupName -Location $Location

Write-Host "Deploying load balancer..."
New-AzureRmResourceGroupDeployment -Name "ra-ad-adfs-deployment" -ResourceGroupName $adfsResourceGroup.ResourceGroupName `
    -TemplateUri $loadBalancerTemplate.AbsoluteUri -TemplateParameterFile $loadBalancerParametersFile
