# Deploying a multiple VMs to Azure

This reference architecture (RA) deploys multiple virtual machine (VM) instances to Azure. This reference architecture implements the proven best practices for [running multiple VMs on Azure for scalability and availability][guidance].

![[0]][0]

## Deployment components

This reference architecture is deployed using a set of Azure Resource Manager templates that we've designed to be a set of building blocks.  

The templates use a set of [parameter files][root-parameters] to define the resources that will be deployed. For this deployment, there is one set of parameter files for [Windows][root-parameters-windows] and another set for [Linux][root-parameters-linux]. You can deploy the reference architecture as is by following the instructions in the [Deploying this Reference Architecture](#deploying-this-reference-architecture) section. 

For more information on how to modify this reference architecture deployment by editing the parameter files, it's best to first read the [Understanding this Reference Architecture Deployment](#understanding-this-reference-architecture-deployement) section, and then the [Customizing this Reference Architecture Deployment](#customizing-this-deployment) section.

## Deploying this reference architecture

The [Github folder][root] includes the files for deploying using the Azure Portal, Powershell, and Bash. This folder includes the parameter files for both Windows and Linux, a [Powershell script][solution-psscript], a [Bash script][solution-shscript], and a Visual Studio project file.

The reference architecture can be deployed using several methods:

### **Portal**

1. Click the button below.

	<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Freference-architectures%2Fmaster%2Fguidance-compute-multi-vm%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/></a>

2. Once the link has opened in the Azure portal, you must enter values for some of the settings: 
    - The **Resource group** name is already defined in the parameter file, so select **Use Existing** and enter `ra-single-vm-rg` in the text box.
    - Select the region from the **Location** drop down box.
    - Do not edit the **Template Root Uri** or the **Parameter Root Uri** text boxes.
    - Select the **Os Type** from the drop down box, **windows** or **linux**.
    - Review the terms and conditions, then click the **I agree to the terms and conditions stated above** checkbox.
    - Click on the **Purchase** button.

3. Wait for the deployment to complete.

### **PowerShell**
1. Download the files from [Github][github-folder] and place them in a local directory.

2. If you want to deploy Windows VMs, navigate to the `\parameters\windows\` folder and edit the `loadBalancerParameters.json` file. Decide on an administrator user name and add the value to the  `"adminUsername"` property, then decide on a password and add the value to the `"adminPassword"`property. If you want to deploy Linux VMs, do the same thing in the `\parameters\linux` directory. Save your edits.

3. Open a [PowerShell console][azure-powershell-download] and navigate to the local directory where you placed the solution components.

4. Run the cmdlet below, substituting your Azure subscription ID for `<id>`, the region for `<location>`, and the Os type you'd like to deploy for `<linux|windows>`. 

````
.\Deploy-ReferenceArchitecture -SubscriptionId <id> -Location <location> -OSType <linux|windows> -ResourceGroupName ra-single-vm-rg
````

### **Bash**
1. Download the files from [Github][github-folder] and place them in a local directory. 

2. If you want to deploy Windows VMs, navigate to the `\parameters\windows\` folder and edit the `loadBalancerParameters.json` file. Decide on an administrator user name and add the value to the  `"adminUsername"` property, then decide on a password and add the value to the `"adminPassword"`property. If you want to deploy Linux VMs, do the same thing in the `\parameters\linux` directory. Save your edits.

3. Open a bash console and navigate to the local directory where you placed the solution components.

4. Run the command below, substituting your Azure subscription ID for `<id>`, the region for `<location>`, and the Os type you'd like to deploy for `<linux|windows>`.

````
sh deploy-reference-architecture.sh -s <subscription id> -l <location> -o <linux|windows> -r ra-single-vm-rg
````

## Understanding this reference architecture deployment

This reference architecture is deployed using a set of [building block templates][bb-templates] and corresponding parameter files. The building block templates are designed to make it easy to deploy resources that are commonly deployed together. For example, virtual machines are typically deployed with a load balancer, so there is a building block template to deploy both at the same time. The parameter files contain the properties to specify the actual resources to be deployed.

This source folder includes files for three deployment methods: an [Azure Resource Manager template][solution-arm], an [Azure Powershell script][solution-psscript], and a [Bash script][solution-shscript]. If you look at each of these files, you'll see that they each contain references to some of the [building block templates][bb-templates] on Github, as well as the parameter files used by the building block templates. 

Note that each file references a different location for the parameter files: 

|Deployment Method|Parameter File Location|
|----------|-----------------------|
|[Azure Resource Manager template][solution-arm]|GitHub or other public URI|
|[Azure Powershell script][solution-psscript]|`\parameters` folder relative to script file|
|[Bash script][solution-shscript]|`\parameters` folder relative to script file|

Regardless of where the parameters are located, each `\parameters` folder contains a separate folder for Windows VM parameter files and another for Linux VM parameter files:

````
    \parameters\windows\<parameter files>
    \parameters\linux\<parameter files>
````

This reference architecture includes a VNet, a NSG, and two VMs as shown in the diagram above. Let's take a look at each of the parameter files and the values of the properties used to deploy this reference architecture.

> Note that the building block templates deploy all resources into a single resource group. 

------------------------------
### **Virtual network (VNet)**

The `virtualNetwork.parameters.json` ([windows][vnet-windows-parameters] / [linux][vnet-linux-parameters]) file is used by the [vnet-n-subnet][bb-vnet] template. This file includes a single parameter: `virtualNetworkSettings`.

#### `virtualNetworkSettings` parameter for `\windows` and `\linux`:

````json
  "parameters": {
    "virtualNetworkSettings": {
      "value": {
        "name": "ra-multi-vm-vnet",
        "resourceGroup": "ra-multi-vm-rg",
        "addressPrefixes": [
          "10.0.0.0/16"
        ],
        "subnets": [
          {
            "name": "ra-multi-vm-sn",
            "addressPrefix": "10.0.1.0/24"
          }
        ],
        "dnsServers": [ ]
      }
    }
  }
````

- `"name"` specifies the name to be assigned to the VNet. This name is used both to define the name of the VNet in the Azure environment and as a reference for other resources in the other templates.

- `"resourceGroup"` specifies the name of the Resource Group that the VNet will be assigned to. The value of this property must agree with the value specified in the Azure Resource Manager UI, [Azure Powershell script][solution-psscript], or [Bash script][solution-shscript].

- The `"addressPrefixes"` array specifies CIDR address blocks for the VNet. In this RA there's only a single address block for the VNet: `10.0.0.0/16`. 

- `"subnets"` is an array of objects for specifying subnets. The [network recommendation][guidance-network] for [running multiple VMs on Azure][guidance] is to place all VMs on the same subnet, so one subnet is defined here. The subnet object has the following properties:

    - `name` defines the name of the subnet. It is also used as reference for other resources in the deployment templates.

    - The `addressPrefix` sub-property specifies the CIDR address block for the subnet. Note that the address block specified for the subnet (`10.0.1.0/24`) must be fall within the address block specified for the VNet (`10.0.0.0/16`).

- `"dnsServers"` is an array of elements which defines the IP addresses of private DNS servers for the VNet. The array for this RA is empty to specify that Azure-managed DNS should be used for name resolution.

-------------------------------
### Network security group (NSG)

A [security consideration][guidance-security] for [running multiple VMs on Azure][guidance] is to restrict traffic to the VMs to only the protocols and ports needed. This RA implements this consideration using an NSG to restrict traffic to each of the VMs. The `networkSecurityGroups.parameters.json` ([windows][nsg-windows-parameters]/[linux][nsg-linux-parameters]) parameter file is used by the [networkSecurityGroups][bb-nsg] template to deploy it. This file includes two parameters: `virtualNetworkSettings` and `networkSecurityGroupsSettings`. 

#### `virtualNetworkSettings` parameter for `\windows` and `\linux`:

````json
    "virtualNetworkSettings": {
      "value": {
        "name": "ra-multi-vm-vnet",
        "resourceGroup": "ra-multi-vm-rg"
      }
    }
````

- `"name"` references the VNet name that was specified above to specify that this NSG applies to it.

- `resourceGroup` references the name of the resource group. 

#### `networkSecurityGroupsSettings` parameter for `\windows`:

````json
    "networkSecurityGroupsSettings": {
      "value": [
        {
          "name": "ra-multi-vm-nsg",
          "subnets": [
            "ra-multi-vm-sn"
          ],
          "networkInterfaces": [
          ],
          "securityRules": [
            {
              "name": "default-allow-rdp",
              "direction": "Inbound",
              "priority": 100,
              "sourceAddressPrefix": "*",
              "destinationAddressPrefix": "*",
              "sourcePortRange": "*",
              "destinationPortRange": "3389",
              "access": "Allow",
              "protocol": "Tcp"
            },
            {
              "name": "default-allow-http",
              "protocol": "Tcp",
              "sourcePortRange": "*",
              "destinationPortRange": "80",
              "sourceAddressPrefix": "*",
              "destinationAddressPrefix": "*",
              "access": "Allow",
              "priority": 110,
              "direction": "Inbound"
            }
          ]
        }
      ]
    }
````
#### `networkSecurityGroupsSettings` parameter for `\linux`:

````json
    "networkSecurityGroupsSettings": {
      "value": [
        {
          "name": "ra-multi-vm-nsg",
          "subnets": [
            "ra-multi-vm-sn"
          ],
          "networkInterfaces": [
          ],
          "securityRules": [
            {
              "name": "default-allow-ssh",
              "direction": "Inbound",
              "priority": 100,
              "sourceAddressPrefix": "*",
              "destinationAddressPrefix": "*",
              "sourcePortRange": "*",
              "destinationPortRange": "22",
              "access": "Allow",
              "protocol": "Tcp"
            },
            {
              "name": "default-allow-http",
              "protocol": "Tcp",
              "sourcePortRange": "*",
              "destinationPortRange": "80",
              "sourceAddressPrefix": "*",
              "destinationAddressPrefix": "*",
              "access": "Allow",
              "priority": 110,
              "direction": "Inbound"
            }
          ]
        }
      ]
    }
````

- `"name"` defines the name of the NSG. 

- `"subnets"` is an array of the subnet names that the NSG will apply to. In this RA, the value `"ra-multi-vm-sn"` references the name of the CIDR address block `10.0.1.0\24` defined above in the VNet parameters. 

- `"networkInterfaces"` is an array of the names of the VM NICs that the NSG will be restricted to. This property is empty to specify that all the NSG should apply to all NICs.

- `"securityRules"` is an array of security rules property objects that specifies the allowed protocols and VM ports that the protocol will be directed to.
    - For the `windows` RA, the properties specify an inbound rule (`"default-allow-rdp"`) to allow remote desktop connections. 
    - For the `linux` RA, the properties specify an inbound rule (`"default-allow-ssh"`) to allow SSH session connections. 
    - For both RAs, the properties specify an inbound rule (`"default-allow-http"`) to allow HTTP connections.

-------------------------
### Virtual machine (VM)

The `loadBalancer.parameters.json` ([windows][vm-windows-parameters]/[linux][vm-linux-parameters]) file is used by the 
[loadBalancer-backend-n-vm][bb-vm] template to deploy the VMs and the load balancer. It includes four parameters: `virtualMachinesSettings`, `loadBalancerSettings`,`virtualNetworkSettings`, and `buildingBlockSettings`. 

#### `virtualMachinesSettings` parameter for `\windows`:

````json
    "virtualMachinesSettings": {
      "value": {
        "namePrefix": "ra-multi",
        "computerNamePrefix": "cn",
        "size": "Standard_DS1_v2",
        "osType": "windows",
        "adminUsername": "",
        "adminPassword": "",
        "sshPublicKey": "",
        "osAuthenticationType": "password",
        "nics": [
          {
            "isPublic": "false",
            "subnetName": "ra-multi-vm-sn",
            "privateIPAllocationMethod": "dynamic",
            "publicIPAllocationMethod": "dynamic",
            "isPrimary": "true",
            "enableIPForwarding": false,
            "domainNameLabelPrefix": "",
            "dnsServers": [ ]
          }
        ],
        "imageReference": {
          "publisher": "MicrosoftWindowsServer",
          "offer": "WindowsServer",
          "sku": "2012-R2-Datacenter",
          "version": "latest"
        },
        "dataDisks": {
          "count": 1,
          "properties": {
            "diskSizeGB": 128,
            "caching": "None",
            "createOption": "Empty"
          }
        },
        "osDisk": {
          "caching": "ReadWrite"
        },
        "extensions": [
          {
            "name": "iis-config-ext",
            "settingsConfigMapperUri": "https://raw.githubusercontent.com/mspnp/template-building-blocks/master/templates/resources/Microsoft.Compute/virtualMachines/extensions/vm-extension-passthrough-settings-mapper.json",
            "publisher": "Microsoft.Powershell",
            "type": "DSC",
            "typeHandlerVersion": "2.20",
            "autoUpgradeMinorVersion": true,
            "settingsConfig": {
              "modulesUrl": "https://raw.githubusercontent.com/mspnp/reference-architectures/master/guidance-compute-multi-vm/extensions/windows/iisaspnet.ps1.zip",
              "configurationFunction": "iisaspnet.ps1\\iisaspnet"
            },
            "protectedSettingsConfig": { }
          }
        ],
        "availabilitySet": {
          "useExistingAvailabilitySet": "No",
          "name": "ra-multi-vm-as"
        }
      }
    }
````

#### `virtualMachinesSettings` parameter for `\linux`:
````json
    "virtualMachinesSettings": {
      "value": {
        "namePrefix": "ra-multi",
        "computerNamePrefix": "cn",
        "size": "Standard_DS1_v2",
        "osType": "linux",
        "adminUsername": "",
        "adminPassword": "",
        "sshPublicKey": "",
        "osAuthenticationType": "password",
        "nics": [
          {
            "isPublic": "false",
            "subnetName": "ra-multi-vm-sn",
            "privateIPAllocationMethod": "dynamic",
            "publicIPAllocationMethod": "dynamic",
            "isPrimary": "true",
            "enableIPForwarding": false,
            "domainNameLabelPrefix": "",
            "dnsServers": [ ]
          }
        ],
        "imageReference": {
          "publisher": "Canonical",
          "offer": "UbuntuServer",
          "sku": "14.04.5-LTS",
          "version": "latest"
        },
        "dataDisks": {
          "count": 1,
          "properties": {
            "diskSizeGB": 128,
            "caching": "None",
            "createOption": "Empty"
          }
        },
        "osDisk": {
          "caching": "ReadWrite"
        },
        "extensions": [
          {
            "name": "apache-config-ext",
            "settingsConfigMapperUri": "https://raw.githubusercontent.com/mspnp/template-building-blocks/master/templates/resources/Microsoft.Compute/virtualMachines/extensions/vm-extension-passthrough-settings-mapper.json",
            "publisher": "Microsoft.OSTCExtensions",
            "type": "CustomScriptForLinux",
            "typeHandlerVersion": "1.5",
            "autoUpgradeMinorVersion": true,
            "settingsConfig": {
              "fileUris": [ "https://raw.githubusercontent.com/mspnp/reference-architectures/master/guidance-compute-multi-vm/extensions/linux/install-apache.sh" ],
              "commandToExecute": "sh install-apache.sh"
            },
            "protectedSettingsConfig": { }
          }
        ],
        "availabilitySet": {
          "useExistingAvailabilitySet": "No",
          "name": "ra-multi-vm-as"
        }
      }
    }
````

- The template automatically generates Azure display names and OS host names based on the number of VMs that are created. `"namePrefix"` specifies the prefix of the Azure display name for each VM, and `"computerNamePrefix"` specifies the prefix for the computer name for the VM. A suffix is appended to both based on the order in which the VM was created by the Resource Manager. In this example the `"namePrefix"` is set to `"ra-multi"`. Two VMs are specified for creation (see the `"vmCount"` property in the  `buildingBlockSettings` parameter below for more details), and this results in an Azure display name of `"ra-multi1"` for the first VM and `"ra-multi2"` for the second. The `computerNamePrefix` property is set to `"cn"`, which results in an computer name of `"cn1"` for the first VM and `"cn2"` for the second.

- `"size"` specifies the size of the VM. The `"Standard_DS1_v2"` size specifications are available in the [sizes for virtual machines in Azure](https://azure.microsoft.com/documentation/articles/virtual-machines-windows-sizes/#dsv2-series) documentation.

- `"osType"` is a directive used by the building blocks templates themselves. The valid values are `windows` for Windows VMs and `linux` for Linux VMs.  

- Each VM OS requires an administrator account.
    - `"adminUsername"` specifies the user name for the administrator account. Note that this is purposely left blank here for security purposes.
    - `"adminPassword"` specifies the administrator password. Note that this is also purposely left blank here. 
    - `"osAuthenticationType"` specifies the sign in authentication type: `password` or `ssh`. For `windows`, the only valid value is `password`, while either `password` or `ssh` is valid for a `linux` deployment. Note that if `"ssh"` is specified for `"linux"`, `"ssh"` specifies the SSH key to be used for logging in.

- `"nics"` specifies the settings for each VM's virtual network interface (NIC). A VM can have more than one NIC assigned to it so this property is implemented as an array of multiple NIC property objects.
    - `"isPublic"` specifies whether or not a [Public IP resource][public-ip-address] (PIP) will be deployed and associated with the NIC. It's set to `"false"` because a load balancer is being deployed, and the load balancer will route incoming public traffic to each of the VMs.
    - `"subnetName"` specifies the subnet that this NIC is associated with. In this case it's the `"ra-multi-vm-sn"` subnet deployed with the VNet above.
    - `"privateIPAllocationMethod"` can be set to either `"static"` or `"dynamic"`. It's set to `"dynamic"` here to specify the IP address will be dynamically allocated by Azure.
    - `"publicIPAllocationMethod"` specifies whether or not the NIC's public IP address should be statically or dynamically allocated. `"isPublic"` is set to `"false"` here, so this property is not used.
    - `"isPrimary"` specifies whether or not this NIC is the primary NIC for the VM. This is set to `"true"` because a NIC must be primary to be in the load balancer's back end pool.
    - `"enableIPForwarding"` is used to specify whether or not the NIC can be used on user defined routes. It's set to `"false"` here.
    - `"domainNameLabelPrefix"` specifies the DNS prefix for the PIP, if it was deployed using the `"isPublic"` property. The value is empty for this RA because no PIP is deployed.
    - `"dnsServer"` is an array that specifies the IP addresses of any DNS servers deployed in the VNet that the NIC should use for name resolution. This RA doesn't deploy any DNS servers, so the value is empty.

- The `"imageReference"` parameter specifies the OS to be installed on the VM. The values of the `"windows"` deployment properties deploys a VM with Windows Server 2012 R2 Datacenter. The values of the `"linux"` deployment properties deploys a VM with Canonical Ubuntu Server. 

- The `dataDisks` property defines the attributes of the data disks that are to be created for use with each of the VMs. In this example, the values of the properties create one empty data disk that is 128GB in size with no cache. For more information, see the Azure Res

- The `osDisk` property defines the cache setting of the OS drive for the VM. In this example, the value of the `caching` sub-property specifies that the OS disk is to perform write-back caching.

- The `extensions` property is an array of objects that describe the extensions that will be installed on the VM when it is deployed. The values of the properties in the `"windows"` deployment specify that Internet Information Services (IIS) is to be installed. The values of the property in the `"linux"` deployment specify that Apache2 Web Server is to be installed. The installation of VM extensions at deployment is complex and beyond the scope of this topic. For more information, see [`"extensions" property`][bb-vm]. 

- In order for the availability SLA for Azure VMs to apply, you must place your VMs in an availability set. The load balancer also requires that VMs in back-end pools are in an availability set. The `"availabilitySet"` property has two sub-properties:
    - `"useExistingAvailabilitySet"`: `"Yes"` specifies that an existing availability set is to be used, while `"No"` specifies that a new availability set is to be created. 
    - `"name"` specifies the name for the availability set that's created if the `"useExistingAvailabilitySet"` sub-property is set to `"No"`, as it is for both the `"windows"` and `"linux"` deployments.

#### `"loadBalancerSettings"` parameter for `"windows"` and `"linux"`

````json
   "loadBalancerSettings": {
      "value": {
        "name": "ra-multi-vm-lb",
        "frontendIPConfigurations": [
          {
            "name": "ra-multi-vm-lb-fe-config1",
            "loadBalancerType": "public",
            "domainNameLabel": "",
            "internalLoadBalancerSettings": {
              "privateIPAddress": "10.0.0.250",
              "subnetName": "ra-multi-vm-sn"
            }
          }
        ],
        "loadBalancingRules": [
          {
            "name": "lbr1",
            "frontendPort": 80,
            "backendPort": 80,
            "protocol": "Tcp",
            "backendPoolName": "ra-multi-vm-lb-bep1",
            "frontendIPConfigurationName": "ra-multi-vm-lb-fe-config1",
            "enableFloatingIP": false,
            "probeName": "lbp1"
          }
        ],
        "probes": [
          {
            "name": "lbp1",
            "port": 80,
            "protocol": "Http",
            "requestPath": "/"
          }
        ],
        "backendPools": [
          {
            "name": "ra-multi-vm-lb-bep1",
            "nicIndex": 0
          }
        ],
        "inboundNatRules": [
          {
            "namePrefix": "rdp",
            "frontendIPConfigurationName": "ra-multi-vm-lb-fe-config1",
            "startingFrontendPort": 50000,
            "backendPort": 3389,
            "natRuleType": "All",
            "protocol": "Tcp",
            "nicIndex": 0
          }
        ]
      }
    }
````

- the `"name"` property specifies the Azure Resource Manager display name of the load balancer and also acts as a reference for other resources in the template.

- the `"frontendIPConfigurations"` property is an array of objects that specify the incoming traffic rules for the load balancer. The configuration object has the following properties:
    - `"name"` specifies the name of the configuration.
    - `"loadBalancerType"` specifies whether the load balancer is `"public"` or `"internal"`.
    - `"domainNameLabel"` specifies the domain name prefix for the load balancer if the load balancer is public-facing as it is here. This is the label that will be prefixed to the Azure fully qualified domain name for the load balancer.
    - `"internalLoadBalancerSettings"` specifies settings for the load balancer itself. It has the following sub-properties:
        - `"privateIPAddress"` specifies the VNet IP address of the load balancer.
        - `"subnetName"` is a reference to the name of the subnet that the load balancer is associated with. Recall that the subnet named `"ra-multi-vm-sn"` was created earlier in the `"VirtualNetworkSettings"` parameter.
- `"loadBalancingRules"` is an array of objects that specify the traffic handling rules for the load balancer. The objects have the following sub-properties:
    - `"name"` specifies the name of the rule.
    - `"frontendPort"` specifies the port number the load balancer listens on.
    - `"backendPort"` specifies the port number to which traffic will be forwarded on the backend VMs.
    - `"protocol"` specifies the protocol that this rule applies to. Either `"TCP"` or `"UDP"`.
    - `"backendPoolName"` references the name of the backend pool to which this rule applies. Note that the `"ra-multi-vm-lb-bep1"` value here refers to the 

#### `virtualMachinesSettings` parameter for `\windows`:

The `virtualNetworkSettings` parameter references the VNet that the VM will be deployed to. The `name` property references the name of the VNet. The `resourceGroup` property references the name of the Resource Group that includes the VNet. This is the same for both the `windows` and `linux` deployments. 

The `buildingBlockSettings` parameter is a set of properites used to control the behavior of the building block templates themselves. The `vmCount` property defines the number of VMs to be created. The `vmStartIndex` property is used to define the initial value of the numbering to be used for the VM names. The `storageAccountsCount` property defines the number of Storage Accounts to be created. These properties are the same for both the `windows` and `linux` deployments.

## Customizing this reference architecture deployment

Now that you've seen how the reference architecture deployment parameter files were created, you can edit the parameter files to customize it. The parameter documentation for each template is available here:

|Template|Parameter File|Documentation|
|--------|--------------|-------------|
|Vnet|virtualNetwork.parameters.json|[vnet-n-subnet][bb-vnet]|
|NSG|networkSecurityGroups.parameters.json|[networkSecurityGroups][bb-nsg]|
|VM|virtualMachine.parameters.json|[multi-vm-n-nic-m-storage][bb-vm]|

Once you've edited the parameter files with your custom property values, follow the instructions below for the type of deployment:

### **Portal**

1. Store your parameter files in a location with a publicly accessible URI. Note that the URI path must start at the `\guidance-compute-multi-vm` folder, but the only files necessary are the files you've edited in the `\parameters` folder. Make sure you preserve the `\windows` and `\linux` file structure. 

2. Click the button below.

	<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Freference-architectures%2Fmaster%2Fguidance-compute-multi-vm%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/></a>

3. Once the link has opened in the Azure portal, you must enter some values for the settings: 
    - For the **Resource group** text box, select **Use Existing** and enter the name of the resource group you've chosen for the resources in your parameter files.
    - Select the region from the **Location** drop down box.
    - Do not edit the **Template Root Uri** text box.
    - Enter the URI path to your `\guidance-compute-multi-vm` folder in the **Parameter Root URI** text box.
    - Select your **Os Type** from the drop down box, **windows** or **linux**.
    - Review the terms and conditions, then click the **I agree to the terms and conditions stated above** checkbox.
    - Click on the **Purchase** button.

4. Wait for the deployment to complete.

### Powershell
1. Open a [PowerShell console][azure-powershell-download] and navigate to the local directory where you placed the solution components and edited the parameter files.

2. Run the cmdlet below, substituting your Azure subscription ID for `<id>`, the region for `<location>`, and the Os type you'd like to deploy for `<linux|windows>`. 

````
.\Deploy-ReferenceArchitecture -SubscriptionId <id> -Location <location> -OSType <linux|windows> -ResourceGroupName ra-single-vm-rg
````

### **Bash**
1. Open a bash console and navigate to the local directory where you placed the solution components and edited the parameter files.

2. Run the command below, substituting your Azure subscription ID for `<id>`, the region for `<location>`, and the Os type you'd like to deploy for `<linux|windows>`.

````
sh deploy-reference-architecture.sh -s <subscription id> -l <location> -o <linux|windows> -r ra-single-vm-rg
````

<!-- links -->
[0]: ./diagram.png
[azure-powershell-download]: https://azure.microsoft.com/documentation/articles/powershell-install-configure/
[bb]: https://github.com/mspnp/template-building-blocks
[bb-vnet]: https://github.com/mspnp/template-building-blocks/tree/master/templates/buildingBlocks/loadBalancer-backend-n-vm
[bb-nsg]: https://github.com/mspnp/template-building-blocks/tree/master/templates/buildingBlocks/networkSecurityGroups
[bb-templates]:https://github.com/mspnp/template-building-blocks/tree/master/templates/buildingBlocks
[bb-vm]: https://github.com/mspnp/template-building-blocks/tree/master/templates/buildingBlocks/loadBalancer-backend-n-vm
[deployment]: #Solution-deployment
[github-folder]:(https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-multi-vm)
[guidance]: https://azure.microsoft.com/documentation/articles/guidance-compute-multi-vm/
[guidance-network]:
https://azure.microsoft.com/documentation/articles/guidance-compute-multi-vm#network-recommendations
[guidance-security]:
https://azure.microsoft.com/documentation/articles/guidance-compute-multi-vm#security-considerations
[linking-to-a-template]:https://azure.microsoft.com/documentation/articles/resource-group-linked-templates/
[nsg-linux-parameters]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-multi-vm/parameters/linux/networkSecurityGroups.parameters.json
[nsg-windows-parameters]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-multi-vm/parameters/windows/networkSecurityGroups.parameters.json
[root]:
https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-multi-vm
[root-parameters]:https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-multi-vm/parameters
[root-parameters-linux]:
https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-multi-vm/parameters/linux
[root-parameters-windows]:https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-multi-vm/parameters/windows
[solution-arm]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-multi-vm/azuredeploy.json
[solution-shscript]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-multi-vm/deploy-reference-architecture.sh
[solution-psscript]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-multi-vm/Deploy-ReferenceArchitecture.ps1
[vnet-linux-parameters]: https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-multi-vm/parameters/linux/virtualNetwork.parameters.json 
[vnet-windows-parameters]: https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-multi-vm/parameters/windows/virtualNetwork.parameters.json
[vm-linux-parameters]: https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-multi-vm/parameters/linux/loadBalancer.parameters.json
[vm-windows-parameters]: https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-multi-vm/parameters/windows/loadBalancer.parameters.json
[vm-size]:
https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-sizes/