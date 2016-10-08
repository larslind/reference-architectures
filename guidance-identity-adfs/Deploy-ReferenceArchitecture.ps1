#
# Deploy_ReferenceArchitecture.ps1
#
param(
  [Parameter(Mandatory=$true)]
  $SubscriptionId,

  [Parameter(Mandatory=$true)]
  $Location,
  
  [Parameter(Mandatory=$false)]
  [ValidateSet("Prepare", "Onpremise", "Infrastructure", "CreateVpn", "AzureADDS", "AdfsVm", "Adfs", "ProxyVm", "Proxy1", "Proxy2", "Workload", "PrivateDmz")]
  $Mode = "Prepare"
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
$referenceArchitectureRootUri = New-Object System.Uri -ArgumentList @("https://raw.githubusercontent.com/mspnp/reference-architectures/master/")

$onPremiseVirtualNetworkGatewayTemplate = New-Object System.Uri -ArgumentList @($referenceArchitectureRootUri, "guidance-identity-adfs/templates/onpremise/virtualNetworkGateway.json")
$onPremiseConnectionTemplate = New-Object System.Uri -ArgumentList @($referenceArchitectureRootUri, "guidance-identity-adfs/templates/onpremise/connection.json")

$loadBalancerTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/loadBalancer-backend-n-vm/azuredeploy.json")
$virtualNetworkTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/vnet-n-subnet/azuredeploy.json")
$virtualMachineTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/multi-vm-n-nic-m-storage/azuredeploy.json")
$dmzTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/dmz/azuredeploy.json")
$virtualNetworkGatewayTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/vpn-gateway-vpn-connection/azuredeploy.json")
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

# Azure ADDS Parameter Files
$azureVirtualNetworkOnpremiseAndAzureDnsParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\virtualNetwork-with-onpremise-and-azure-dns.parameters.json")
$azureAddsVirtualMachinesParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\virtualMachines-adds.parameters.json")
$azureAddAddsDomainControllerExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\add-adds-domain-controller.parameters.json")
$gmsaExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\gmsa.parameters.json")
$joinAddsVmsToDomainExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\adds-domain-join.parameters.json")

# Azure ADFS Parameter Files
$adfsLoadBalancerParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\loadBalancer-adfs.parameters.json")
$azureAdfsFarmDomainJoinExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\adfs-farm-domain-join.parameters.json")
$azureAdfsFarmFirstExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\adfs-farm-first.parameters.json")
$azureAdfsFarmRestExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\adfs-farm-rest.parameters.json")

# Azure ADFS Proxy Parameter Files
$adfsproxyLoadBalancerParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\loadBalancer-adfsproxy.parameters.json")
$azureAdfsproxyFarmFirstExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\adfsproxy-farm-first.parameters.json")
$azureAdfsproxyFarmRestExtensionParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\adfsproxy-farm-rest.parameters.json")


$azureVirtualNetworkGatewayParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\virtualNetworkGateway.parameters.json")
$azureVirtualNetworkParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\virtualNetwork.parameters.json")
$webLoadBalancerParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\loadBalancer-web.parameters.json")
$bizLoadBalancerParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\loadBalancer-biz.parameters.json")
$dataLoadBalancerParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\loadBalancer-data.parameters.json")
$managementParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\virtualMachines-mgmt.parameters.json")
$privateDmzParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\dmz-private.parameters.json")
$publicDmzParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\azure\dmz-public.parameters.json")


# Azure Onpremise Deployments
$onpremiseNetworkResourceGroupName = "ra-adfs-onpremise-rg"

# Azure ADDS Deployments
$azureNetworkResourceGroupName = "ra-adfs-network-rg"
$workloadResourceGroupName = "ra-adfs-workload-rg"
$securityResourceGroupName = "ra-adfs-security-rg"
$addsResourceGroupName = "ra-adfs-adds-rg"
$adfsResourceGroupName = "ra-adfs-adfs-rg"
$adfsproxyResourceGroupName = "ra-adfs-proxy-rg"

# Login to Azure and select your subscription
Login-AzureRmAccount -SubscriptionId $SubscriptionId | Out-Null

##########################################################################
# Deploy On premises network and on premise ADDS
##########################################################################

if ($Mode -eq "Onpremise" -Or $Mode -eq "Prepare") {
    $onpremiseNetworkResourceGroup = New-AzureRmResourceGroup -Name $onpremiseNetworkResourceGroupName -Location $Location
    Write-Host "Creating onpremise virtual network..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-onpremise-vnet-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName -TemplateUri $virtualNetworkTemplate.AbsoluteUri `
        -TemplateParameterFile $onpremiseVirtualNetworkParametersFile

    Write-Host "Deploying ADDS servers..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-onpremise-adds-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $onpremiseADDSVirtualMachinesParametersFile

    # Remove the Azure DNS entry since the forest will create a DNS forwarding entry.
    Write-Host "Updating virtual network DNS servers..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-onpremise-dns-vnet-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName -TemplateUri $virtualNetworkTemplate.AbsoluteUri `
        -TemplateParameterFile $onpremiseVirtualNetworkDnsParametersFile

    Write-Host "Creating ADDS forest..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-onpremise-adds-forest-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $onpremiseCreateAddsForestExtensionParametersFile

    Write-Host "Creating ADDS domain controller..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-onpremise-adds-dc-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $onpremiseAddAddsDomainControllerExtensionParametersFile
}

##########################################################################
# Deploy Vnet and VPN Infrastructure in cloud
##########################################################################

if ($Mode -eq "Infrastructure" -Or $Mode -eq "Prepare") {
    Write-Host "Creating ADDS resource group..."
    $azureNetworkResourceGroup = New-AzureRmResourceGroup -Name $azureNetworkResourceGroupName -Location $Location

    # Deploy network infrastructure
    Write-Host "Deploying virtual network..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-vnet-deployment" -ResourceGroupName $azureNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualNetworkTemplate.AbsoluteUri -TemplateParameterFile $azureVirtualNetworkParametersFile

    # Deploy security infrastructure
    Write-Host "Creating security resource group..."
    $securityResourceGroup = New-AzureRmResourceGroup -Name $securityResourceGroupName -Location $Location

    Write-Host "Deploying jumpbox..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-jumpbox-deployment" -ResourceGroupName $securityResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $managementParametersFile
}

if ($Mode -eq "CreateVpn" -Or $Mode -eq "Prepare") {
    $onpremiseNetworkResourceGroup = Get-AzureRmResourceGroup -Name $onpremiseNetworkResourceGroupName
    $azureNetworkResourceGroup = Get-AzureRmResourceGroup -Name $azureNetworkResourceGroupName

    Write-Host "Deploying Onpremise Virtual Network Gateway..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-onpremise-vpn-gateway-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $onPremiseVirtualNetworkGatewayTemplate.AbsoluteUri -TemplateParameterFile $onpremiseVirtualNetworkGatewayParametersFile

    Write-Host "Deploying Azure Virtual Network Gateway..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-vpn-gateway-deployment" -ResourceGroupName $azureNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualNetworkGatewayTemplate.AbsoluteUri -TemplateParameterFile $azureVirtualNetworkGatewayParametersFile

    Write-Host "Creating Onpremise connection..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-onpremise-connection-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $onPremiseConnectionTemplate.AbsoluteUri -TemplateParameterFile $onpremiseConnectionParametersFile
}

##########################################################################
# Deploy ADDS replication site in cloud
##########################################################################

if ($Mode -eq "AzureADDS" -Or $Mode -eq "Prepare") {
    # Add the replication site.
    $onpremiseNetworkResourceGroup = Get-AzureRmResourceGroup -Name $onpremiseNetworkResourceGroupName
    Write-Host "Creating ADDS replication site..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-site-replication-deployment" `
        -ResourceGroupName $onpremiseNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $onpremiseReplicationSiteForestExtensionParametersFile

    # Deploy AD tier
    Write-Host "Creating ADDS resource group..."
    $addsResourceGroup = New-AzureRmResourceGroup -Name $addsResourceGroupName -Location $Location

    Write-Host "Deploying ADDS servers..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-adds-deployment" -ResourceGroupName $addsResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $azureAddsVirtualMachinesParametersFile

    # Join the domain
    Write-Host "Joining ADDS Vms to domain..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-adds-join-domain-deployment" `
        -ResourceGroupName $addsResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $joinAddsVmsToDomainExtensionParametersFile

    # Create DCs
    Write-Host "Creating ADDS domain controllers..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-adds-dc-deployment" `
        -ResourceGroupName $addsResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $azureAddAddsDomainControllerExtensionParametersFile

    $azureNetworkResourceGroup = Get-AzureRmResourceGroup -Name $azureNetworkResourceGroupName
    # Update DNS server to point to onpremise and azure
    Write-Host "Updating virtual network DNS..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-vnet-onpremise-azure-dns-deployment" `
        -ResourceGroupName $azureNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $virtualNetworkTemplate.AbsoluteUri -TemplateParameterFile $azureVirtualNetworkOnpremiseAndAzureDnsParametersFile

    Write-Host "Create group management service account and DNS record for ADFS..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-adds-create-gmsa-and-dns-entry-for-adfs-deployment" `
        -ResourceGroupName $addsResourceGroup.ResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $gmsaExtensionParametersFile
}

##########################################################################
# Deploy ADFS Farm in cloud
##########################################################################

if ($Mode -eq "AdfsVm") {
    # Create ADFS resoure group, loadbancer and VMs, then join Domain

    Write-Host "Creating ADFS resource group..."
    $adfsResourceGroup = New-AzureRmResourceGroup -Name $adfsResourceGroupName -Location $Location

    Write-Host "Deploying adfs load balancer..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-adfs-deployment" -ResourceGroupName $adfsResourceGroup.ResourceGroupName `
        -TemplateUri $loadBalancerTemplate.AbsoluteUri -TemplateParameterFile $adfsLoadBalancerParametersFile

    Write-Host "Joining ADFS Vms to domain..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-adfs-farm-join-domain-deployment" `
        -ResourceGroupName $adfsResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $azureAdfsFarmDomainJoinExtensionParametersFile
}

if ($Mode -eq "Adfs") {
	#Deploy ADFS service in the VMs

	Write-Host  
    Write-Host "Please install certificate to all adfs VMs ..."
	Write-Host  
	Write-Host -NoNewLine 'Press any key to continue install ADFS services...'
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

    Write-Host "Creating the first ADFS farm node ..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-adfs-farm-first-node-deployment" `
        -ResourceGroupName $adfsResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $azureAdfsFarmFirstExtensionParametersFile

    Write-Host "Creating the rest ADFS farm nodes ..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-adfs-farm-rest-node-deployment" `
        -ResourceGroupName $adfsResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $azureAdfsFarmRestExtensionParametersFile
	
	# To test the adfs deployment:
	Write-Host  "browse to https://adfs.contoso.com/adfs/ls/idpinitiatedsignon.htm from jumpbox to test the adfs installation"
}

##########################################################################
# Deploy ADFS Web Application Proxy Farm in cloud
##########################################################################
if ($Mode -eq "ProxyVm") {
    # Create Web Application Proxy resoure group, loadbancer and VMs, and pubic DMZ

    Write-Host "Creating Adfs Proxy resource group..."
    $adfsproxyResourceGroup = New-AzureRmResourceGroup -Name $adfsproxyResourceGroupName -Location $Location

    Write-Host "Deploying Adfs proxy load balancer..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-adfs-deployment" -ResourceGroupName $adfsproxyResourceGroup.ResourceGroupName `
        -TemplateUri $loadBalancerTemplate.AbsoluteUri -TemplateParameterFile $adfsproxyLoadBalancerParametersFile

    # Deploy Public DMZ for ADFS Web Application Proxy
    $azureNetworkResourceGroup = Get-AzureRmResourceGroup -Name $azureNetworkResourceGroupName

    Write-Host "Deploying public DMZ..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-dmz-public-deployment" -ResourceGroupName $azureNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $dmzTemplate.AbsoluteUri -TemplateParameterFile $publicDmzParametersFile
}


if ($Mode -eq "Proxy1") {
	# Install the first Adfs Web Appication Proxy in the VM proxy1
	Write-Host  
    Write-Host "Please install certificate to all adfs proxy VMs ..."
	Write-Host  
	Write-Host -NoNewLine 'Press any key to continue install ADFS web application proxy ...'
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

    Write-Host "Creating the first ADFS proxy farm node ..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-proxy-farm-first-node-deployment" `
        -ResourceGroupName $adfsproxyResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $azureAdfsproxyFarmFirstExtensionParametersFile

	# To test the adfs deployment:
	Write-Host  "browse to https://adfs.contoso.com/adfs/ls/idpinitiatedsignon.htm from your development machine to test the adfs proxy installation"
}

if ($Mode -eq "Proxy2") {
	# Install the Adfs Web Appication Proxy in the rest VMs (proxy2 ..., )

	Write-Host  
	Write-Host  "browse to https://adfs.contoso.com/adfs/ls/idpinitiatedsignon.htm from your development machine to test the adfs proxy installation before continueing deploy the rest proxy servers"
	Write-Host  
	Write-Host -NoNewLine 'Press any key to continue creating the rest ADFS web application proxy...'
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

    New-AzureRmResourceGroupDeployment -Name "ra-adfs-proxy-farm-rest-node-deployment" `
        -ResourceGroupName $adfsproxyResourceGroupName `
        -TemplateUri $virtualMachineExtensionsTemplate.AbsoluteUri -TemplateParameterFile $azureAdfsproxyFarmRestExtensionParametersFile
	
	# To test the adfs deployment:
	Write-Host  "browse to https://adfs.contoso.com/adfs/ls/idpinitiatedsignon.htm from your development machine to test the adfs proxy installation"
}

##########################################################################
# Deployment workload and Private Dmz in cloud (optional for this guidance)
##########################################################################

if ($Mode -eq "Workload") {
    # Deploy workload tiers: RG, web, biz, and data

    Write-Host "Creating workload resource group..."
    $workloadResourceGroup = New-AzureRmResourceGroup -Name $workloadResourceGroupName -Location $Location

    Write-Host "Deploying web load balancer..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-web-deployment" -ResourceGroupName $workloadResourceGroup.ResourceGroupName `
        -TemplateUri $loadBalancerTemplate.AbsoluteUri -TemplateParameterFile $webLoadBalancerParametersFile

    Write-Host "Deploying biz load balancer..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-biz-deployment" -ResourceGroupName $workloadResourceGroup.ResourceGroupName `
        -TemplateUri $loadBalancerTemplate.AbsoluteUri -TemplateParameterFile $bizLoadBalancerParametersFile

    Write-Host "Deploying data load balancer..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-data-deployment" -ResourceGroupName $workloadResourceGroup.ResourceGroupName `
        -TemplateUri $loadBalancerTemplate.AbsoluteUri -TemplateParameterFile $dataLoadBalancerParametersFile
}

if ($Mode -eq "PrivateDmz") {
    # Deploy Pirvate DMZs
    $azureNetworkResourceGroup = Get-AzureRmResourceGroup -Name $azureNetworkResourceGroupName

    Write-Host "Deploying private DMZ..."
    New-AzureRmResourceGroupDeployment -Name "ra-adfs-dmz-private-deployment" -ResourceGroupName $azureNetworkResourceGroup.ResourceGroupName `
        -TemplateUri $dmzTemplate.AbsoluteUri -TemplateParameterFile $privateDmzParametersFile
}

##########################################################################
# Install certificate to ADFS VMs and ADFS Web Application Proxy VMs (manual step)
##########################################################################
#  Manual steps to create a fake root certificate and and use it to create adfs.contoso.com.pfx
#  1. Log on your developer machine (note: adfs boxes are domain joined, proxy boxes are not domain joined)
#  2. Download makecert.exe to 
#        C:/temp/makecert.exe 
#  3. Create my fake root certificate authority use command prompt
#        makecert -sky exchange -pe -a sha256 -n "CN=MyFakeRootCertificateAuthority" -r -sv MyFakeRootCertificateAuthority.pvk MyFakeRootCertificateAuthority.cer -len 2048
#  4. Verify that the foloiwng files are created
# 	     C:/temp/MyFakeRootCertificateAuthority.cer
# 	     C:/temp/MyFakeRootCertificateAuthority.pvk
#  5. Run command prompt as admin to use my fake root certificate authority to generate a certificate for adfs.contoso.com
#        makecert -sk pkey -iv MyFakeRootCertificateAuthority.pvk -a sha256 -n "CN=adfs.contoso.com , CN=enterpriseregistration.contoso.com" -ic MyFakeRootCertificateAuthority.cer -sr localmachine -ss my -sky exchange -pe
#  6. Start MMC certificates console, expand to /Certificates (Local Computer)/Personal/Certificate/adfs.contoso.com and export the certificate with the private key to 
#        C:/temp/adfs.contoso.com.pfx
# ###############################################
# Install certificate to the ADFS and ADFS Proxy VMs:
# 1. Make sure you have a certificate adfs.contoso.com.pfx either self created or signed by VerifSign, Go Daddy, DigiCert, and etc.
# 2. RDP to the each ADFS VM adfs1, adfs2, ...and each ADFS Proxy VM proxy1, proxy2, ...
# 3. Copy to c:\temp the following file
#		c:\temp\adfs.contoso.com.pfx 
#       c:\MyFakeRootCertificateAuthority.cer  (if you created the above cert yourself )
# 4. Run the following command prompt as admin:
#    	certutil.exe -privatekey -importPFX my C:\temp\adfs.contoso.com.pfx NoExport
#	    certutil.exe -addstore Root C:\temp\MyFakeRootCertificateAuthority.cer 
# 5. Start MMC, Add Certificates Snap-in, sellect Computer account, and verify that the following certificate is installed:
#      \Certificates (Local Computer)\Personal\Certificates\adfs.contoso.com
#      \Certificates (Local Computer)\Trusted Root Certification Authorities\Certificates\MyFakeRootCertificateAuthority 
##########################################################################
