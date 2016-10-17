# Deploying a single VM to Azure

This reference architecture (RA) deploys a single virtual machine (VM) instance to Azure. This RA implements the proven best practices for [running a VM on Azure][guidance].

![[0]][0]

## Deployment components

This RA is deployed using a set of Azure Resource Manager templates that we've designed to be a set of building blocks.  

The templates use a set of [parameter files][root-parameters] to define the resources that will be deployed. For this deployment, there is one set of parameter files for [Windows][root-parameters-windows] and another set for [Linux][root-parameters-linux]. You can deploy this RA as is by following the instructions in the [Deploying this Reference Architecture](#deploying-this-reference-architecture) section. 

For more information on how to modify this RA by editing the parameter files, it's best to first read the [Understanding this Reference Architecture Deployment](#understanding-this-reference-architecture-deployement) section, and then the [Customizing this Reference Architecture Deployment](#customizing-this-deployment) section.


## Deploying this reference architecture

The [Github folder][root] includes the files for deploying using the Azure Portal, Powershell, and Bash. This folder includes the parameter files for both Windows and Linux, a [Powershell script][solution-psscript], a [Bash script][solution-shscript], and a Visual Studio project file.

The reference architecture can be deployed using several methods:

### **Portal**

1. Click the button below.

	<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Freference-architectures%2Fmaster%2Fguidance-compute-single-vm%2Fazuredeploy.json" target="_blank">
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

2. If you want to deploy Windows VMs, navigate to the `\parameters\windows\` folder and edit the `virtualMachine.parameters.json` file. Decide on an administrator user name and add the value to the  `"adminUsername"` property, then decide on a password and add the value to the `"adminPassword"`property. If you want to deploy Linux VMs, do the same thing in the `\parameters\linux` directory. Save your edits.

3. Open a [PowerShell console][azure-powershell-download] and navigate to the local directory where you placed the solution components.

4. Run the cmdlet below, substituting your Azure subscription ID for `<id>`, the region for `<location>`, and the Os type you'd like to deploy for `<linux|windows>`. 

````
.\Deploy-ReferenceArchitecture -SubscriptionId <id> -Location <location> -OSType <linux|windows> -ResourceGroupName ra-single-vm-rg
````

### **Bash**
1. Download the files from [Github][github-folder] and place them in a local directory. 

2. If you want to deploy Windows VMs, navigate to the `\parameters\windows\` folder and edit the `virtualMachine.parameters.json` file. Decide on an administrator user name and add the value to the  `"adminUsername"` property, then decide on a password and add the value to the `"adminPassword"`property. If you want to deploy Linux VMs, do the same thing in the `\parameters\linux` directory. Save your edits.

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

This RA includes a VNet, a NSG, and a VM as shown in the architecture diagram above. Let's take a look at each of the **parameter files** and the values of the properties used to deploy this reference architecture.

> Note that the building block templates deploy all resources into a single resource group. 

--------------------------
### **Virtual network (VNet)**

The `virtualNetwork.parameters.json` ([windows][vnet-windows-parameters] / [linux][vnet-linux-parameters]) file is used by the [vnet-n-subnet][bb-vnet] template. It includes a single parameter, `virtualNetworkSettings`. 

#### `virtualNetworkSettings` parameter for `\windows` and `\linux`:

````json
  "parameters": {
    "virtualNetworkSettings": {
      "value": {
        "name": "ra-single-vm-vnet",
        "addressPrefixes": [
          "10.0.0.0/16"
        ],
        "subnets": [
          {
            "name": "web",
            "addressPrefix": "10.0.1.0/24"
          }
        ],
        "dnsServers": [ ]
      }
    }
  }
````

- `name` specifies the name to be assigned to the VNet. This name is used both to define the name of the VNet in the Azure environment and as a reference for other resources in the other templates.

- `addressPrefixes` is an array that holds CIDR address blocks for the VNet. In this RA there's only a single address block for the VNet, `10.0.0.0/16`. 

-`subnets` is an array of objects for specifying subnets. The [network recommendation][guidance-network] for [running multiple VMs on Azure][guidance] is to place all VMs on the same subnet, so one subnet is defined here. The subnet object has the following properties:
    - `name` defines the name of the subnet. It is also used as reference for other resources in the deployment templates.
    - The `addressPrefix` sub-property specifies the CIDR address block for the subnet. Note that the address block specified for the subnet (`10.0.1.0/24`) must be fall within the address block specified for the VNet (`10.0.0.0/16`).

- `dnsServers` is an array that holds the IP addresses of private DNS servers for the VNet. The array here is empty to specify that Azure-managed DNS should be used for name resolution.

--------------------------------------
### Network security group (NSG)

A [network recommendation][guidance-network-recommendation] for [running a VM on Azure][guidance] is to restrict traffic to VMs to only the protocols and ports needed. This RA implements this consideration using a NSG to restrict traffic to the VM.

The `networkSecurityGroups.parameters.json` ([windows][nsg-windows-parameters] / [linux][nsg-linux-parameters]) file is used by the [networkSecurityGroups][bb-nsg] template to specify the deployment of the NSG. 

It includes two parameters: `virtualNetworkSettings` and `networkSecurityGroupsSettings`. These parameters are used by the Resource Manager to create a Network Security Group that will be attached to the VNet.

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
          ]
        }
      ]
    }
````

- `name` defines the name of the NSG. 

- `subnets` is an array of the subnet names that the NSG will apply to. In this RA, the value `ra-multi-vm-sn` references the name of the CIDR address block `10.0.1.0\24` defined above in the VNet parameters. 

- `networkInterfaces` is an array of the names of the VM NICs that the NSG will be restricted to. This property is empty to specify that all the NSG should apply to all NICs.

- `securityRules` is an array of security rules property objects that specifies the allowed protocols and VM ports that the protocol will be directed to.
    - For the `\windows` RA, the properties specify an inbound rule (`"default-allow-rdp"`) to allow remote desktop connections. 
    - For the `\linux` RA, the properties specify an inbound rule (`"default-allow-ssh"`) to allow SSH session connections.

-----------------------------
### Virtual machine (VM)

The `virtualMachine.parameters.json` ([windows][vm-windows-parameters] / [linux][vm-linux-parameters]) file is used by the 
[multi-vm-n-nic-m-storage][bb-vm] template to deploy the VM. It includes three parameters: `virtualMachinesSettings`, `virtualNetworkSettings`, and `buildingBlockSettings`. These parameters are used by the Resource Manager to create the VM and deploy it in the VNet. 

#### `virtualMachinesSettings` parameter for `\windows`:

````json
    "virtualMachinesSettings": {
      "value": {
        "namePrefix": "ra-single-vm",
        "computerNamePrefix": "cn",
        "size": "Standard_DS1_v2",
        "osType": "windows",
        "adminUsername": "",
        "adminPassword": "",
        "osAuthenticationType": "password",
        "nics": [
          {
            "isPublic": "true",
            "subnetName": "ra-single-vm-sn",
            "privateIPAllocationMethod": "dynamic",
            "publicIPAllocationMethod": "dynamic",
            "enableIPForwarding": false,
            "dnsServers": [
            ],
            "isPrimary": "true"
          }
        ],
        "imageReference": {
          "publisher": "MicrosoftWindowsServer",
          "offer": "WindowsServer",
          "sku": "2012-R2-Datacenter",
          "version": "latest"
        },
        "dataDisks": {
          "count": 2,
          "properties": {
            "diskSizeGB": 128,
            "caching": "None",
            "createOption": "Empty"
          }
        },
        "osDisk": {
          "caching": "ReadWrite"
        },
        "extensions": [ ],
        "availabilitySet": {
          "useExistingAvailabilitySet": "No",
          "name": ""
        }
      }
    }
````

#### `virtualMachinesSettings` parameter for `\linux`:

````json
    "virtualMachinesSettings": {
      "value": {
        "namePrefix": "ra-single-vm",
        "computerNamePrefix": "cn",
        "size": "Standard_DS1_v2",
        "osType": "linux",
        "adminUsername": "",
        "adminPassword": "",
        "osAuthenticationType": "password",
        "nics": [
          {
            "isPublic": "true",
            "subnetName": "subnet1",
            "privateIPAllocationMethod": "dynamic",
            "publicIPAllocationMethod": "dynamic",
            "enableIPForwarding": false,
            "dnsServers": [
            ],
            "isPrimary": "true"
          }
        ],
        "imageReference": {
          "publisher": "Canonical",
          "offer": "UbuntuServer",
          "sku": "14.04.5-LTS",
          "version": "latest"
        },
        "dataDisks": {
          "count": 2,
          "properties": {
            "diskSizeGB": 128,
            "caching": "None",
            "createOption": "Empty"
          }
        },
        "osDisk": {
          "caching": "ReadWrite"
        },
        "extensions": [ ],
        "availabilitySet": {
          "useExistingAvailabilitySet": "No",
          "name": ""
        }
      }
    }
````

- The template automatically generates Azure display names and OS host names based on the number of VMs that are created. The `namePrefix` property specifies the prefix of the Azure display name for each VM, and the `computerNamePrefix` specifies the prefix for the host name for the VM's OS. A suffix is appended to both based on the order in which the VM was created by the Resource Manager. In this example the `namePrefix` property is set to `"ra-single-vm"`. Only one VM is specified for creation (see the `vmCount` property in the  `buildingBlockSettings` parameter below for more details), and this results in an Azure display name of `"ra-single-vm1"`. The `computerNamePrefix` property is set to `"cn"`, which results in an OS name of `"cn1"`. This is the same for both `Windows` and `Linux` deployments.

- `size` references the size of the VM. The [VM recommendations][guidance-vm-recommendation] is to deploy DS- or GS- series VMs. In this example, a DS_ series VM is specified by setting the `size` property to `"Standard_DS1_v2"`. The `"Standard_DS1_v2"` size specification is available in the [sizes for virtual machines in Azure](https://azure.microsoft.com/documentation/articles/virtual-machines-windows-sizes/#dsv2-series) documentation.

- `osType` is a directive used by the building blocks templates themselves. The valid values are `windows` for Windows VMs and `linux` for Linux VMs.  

- The VM's OS requires an administrator account.
    - `adminUsername` specifies the user name for the administrator account. Note that this is purposely left blank here for security purposes.
    - `adminPassword` specifies the administrator password. Note that this is also purposely left blank here. 
    - `osAuthenticationType` specifies the sign in authentication type: `"password"` or `"ssh"`. For the `\windows` RA, note that the only valid value is `password`, while either `"password"` or `"ssh"` is valid for the `\linux` RA. Note that if `"ssh"` is specified for the `\linux` RA, the `ssh` property specifies the SSH key to be used for logging in.

- `nics` specifies the settings for each VM's virtual network interface (NIC). A VM can have more than one NIC assigned to it so this property is implemented as an array of multiple NIC property objects.
    - `isPublic` specifies whether or not a [Public IP resource][public-ip-address] (PIP) will be deployed and associated with the NIC. In this RA it's set to `"true"`.
    - `subnetName` references the subnet that this NIC is associated with. In this RA it's the `"web"` subnet specified in the VNet parameters earlier.
    - `privateIPAllocationMethod` can be set to either `"static"` or `"dynamic"`. It's set to `"dynamic"` here to specify the IP address will be dynamically allocated by Azure.
    - `publicIPAllocationMethod` specifies whether or not the NIC's public IP address should be statically or dynamically allocated. This is set to `"dynamic"` to indicate the PIP will be dynamically allocated. 
    - `isPrimary` specifies whether or not this NIC is the primary NIC for the VM. This is set to `"true"` because a NIC must be primary to be in the load balancer's back end pool.
    - `enableIPForwarding` is used to specify whether or not the NIC can be used on user defined routes. It's set to `"false"` here.
    - `"dnsServer"` is an array that specifies the IP addresses of any DNS servers deployed in the VNet that the NIC should use for name resolution. This RA doesn't deploy any DNS servers, so the value is empty.

- `imageReference` specifies the OS to be installed on the VM. The `\windows` RA property values specify a VM with Windows Server 2012 R2 Datacenter. The `\linux` RA property values specify a VM with Canonical Ubuntu Server.

- `dataDisks` specifies the attributes of the data disks to be created for use with the VM. For this RA, the values specify two empty data disks that are 128GB in size, empty upon creation, and do not cache. The [disk and storage recommendation][guidance-disk-recommendation] is to use [premium storage][premium-storage] accounts, and the building block templates create premium locally-redundant storage accounts for all `dataDisks`.

- `osDisk` specifies the attributes of the OS drive for the VM. In this RA, the value of the `caching` sub-property specifies that the OS disk is to perform write-back caching. As with `dataDisks`, the building block templates follow the [disk and storage recommendations][guidance-disk-recommendation] and create [premium storage][premium-storage] accounts for the `osDisk` for all VMs.

- `extensions` is used to reference [Azure VM Extensions][azure-vm-extensions]. It's blank for both the `\windows` and `\linux` RAs because we're not installing any extensions.

- `availabilitySet` specifies the deployment of an availability set, but since this RA deploys only a single VM in both `\windows` and `\linux`, it's not possible to create an availability set.

#### `"virtuaNetworkSettings"` parameter for `"\windows"` and `"\linux"`:

The `"virtualNetworkSettings"` parameter references the VNet that the VM will be deployed to.

````json
    "virtualNetworkSettings": {
      "value": {
        "name": "ra-single-vm-vnet",
        "resourceGroup": "ra-single-vm-rg"
      }
    }
```` 
- `"name"` references the name of the VNet that was deployed earlier in the `"virtualNetworkSettings"` parameter. 
- `"resourceGroup"` references the name of the Resource Group that includes the VNet.  

#### `"buildingBlockSettings"` parameter for `"\windows"` and `"\linux"`:

The `buildingBlockSettings` parameter is a set of properites used to control the behavior of the building block templates themselves. 

````json
    "buildingBlockSettings": {
      "value": {
        "storageAccountsCount": 1,
        "vmCount": 1,
        "vmStartIndex": 0
      }
    }
````
- `storageAccountsCount` specifies the number of Storage Accounts that will be created for each VM.
- `vmCount` specifies the number of VMs to be created. 
- `vmStartIndex` specifies the initial value of the numbering to be used for the VM names.

## Customizing this reference architecture deployment

Now that you've seen how the reference architecture deployment parameter files were created, you can edit the parameter files to customize it. The parameter documentation for each template is available here:

|Template|Parameter File|Documentation|
|--------|--------------|-------------|
|Vnet|virtualNetwork.parameters.json|[vnet-n-subnet][bb-vnet]|
|NSG|networkSecurityGroups.parameters.json|[networkSecurityGroups][bb-nsg]|
|VM|virtualMachine.parameters.json|[multi-vm-n-nic-m-storage][bb-vm]|

Once you've edited the parameter files with your custom property values, follow the instructions below for the type of deployment:

### **Portal**

1. Store your parameter files in a location with a publicly accessible URI. Note that the URI path must start at the `\guidance-compute-single-vm` folder, but the only files necessary are the files you've edited in the `\parameters` folder. Make sure you preserve the `\windows` and `\linux` file structure. 

2. Click the button below.

	<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Freference-architectures%2Fmaster%2Fguidance-compute-single-vm%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/></a>

3. Once the link has opened in the Azure portal, you must enter some values for the settings: 
    - For the **Resource group** text box, select **Use Existing** and enter the name of the resource group you've chosen for the resources in your parameter files.
    - Select the region from the **Location** drop down box.
    - Do not edit the **Template Root Uri** text box.
    - Enter the URI path to your `\guidance-compute-single-vm` folder in the **Parameter Root URI** text box.
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
[bb-vnet]: https://github.com/mspnp/template-building-blocks/tree/master/templates/buildingBlocks/vnet-n-subnet
[bb-nsg]: https://github.com/mspnp/template-building-blocks/tree/master/templates/buildingBlocks/networkSecurityGroups
[bb-vm]: https://github.com/mspnp/template-building-blocks/tree/master/templates/buildingBlocks/multi-vm-n-nic-m-storage
[deployment]: #Solution-deployment
[github-folder]:(https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-single-vm)
[guidance]: https://azure.microsoft.com/en-us/documentation/articles/guidance-compute-single-vm/
[guidance-disk-recommendation]:
https://azure.microsoft.com/en-us/documentation/articles/guidance-compute-single-vm/#disk-and-storage-recommendations
[guidance-network-recommendation]:
https://azure.microsoft.com/en-us/documentation/articles/guidance-compute-single-vm/#network-recommendations
[guidance-vm-recommendation]:
https://azure.microsoft.com/en-us/documentation/articles/guidance-compute-single-vm/#vm-recommendations
[nsg-linux-parameters]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-single-vm/parameters/linux/networkSecurityGroups.parameters.json
[nsg-windows-parameters]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-single-vm/parameters/windows/networkSecurityGroups.parameters.json
[premium-storage]:
https://azure.microsoft.com/documentation/articles/storage-premium-storage/
[root]:
https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-single-vm
[root-parameters]:
https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-single-vm/parameters
[root-parameters-linux]:
https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-single-vm/parameters/linux
[root-parameters-windows]:
https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-single-vm/parameters/windows
[root-template]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-single-vm/azuredeploy.json
[solution-shscript]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-single-vm/deploy-reference-architecture.sh
[solution-psscript]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-single-vm/Deploy-ReferenceArchitecture.ps1
[vnet-linux-parameters]: https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-single-vm/parameters/linux/virtualNetwork.parameters.json 
[vnet-windows-parameters]: https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-single-vm/parameters/windows/virtualNetwork.parameters.json
[vm-linux-parameters]: https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-single-vm/parameters/linux/virtualMachine.parameters.json
[vm-windows-parameters]: https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-single-vm/parameters/windows/virtualMachine.parameters.json