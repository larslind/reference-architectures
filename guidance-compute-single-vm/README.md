# Deploying a single VM to Azure

You can read the [guidance on deploying a single VM to Azure][guidance] document to understand the best practices related to single VM deployment that accompanies the reference architecture below.

![[0]][0]

## Deployment components

This reference architecture is deployed using a set of Azure Resource Manager templates that we've designed to be a set of building blocks.  

The templates use a set of [parameter files](https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-single-vm/parameters) to define the resources that will be deployed. For this deployment, there is one set of parameter files for [Windows](https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-single-vm/parameters/windows) and another set for [Linux](https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-single-vm/parameters/windows). You can deploy the reference architecture as is by following the instructions in the [Deploying this Reference Architecture](#deploying-this-reference-architecture) section. 

For more information on how to modify this deployment by editing the parameter files, it's best to first read the [Understanding this Reference Architecture Deployment](#understanding-this-reference-architecture-deployement) section, and then the [Customizing this Reference Architecture Deployment](#customizing-this-deployment) section.

## Deploying this reference architecture

The [Github folder](https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-single-vm)  includes the files for deploying using the Azure Portal, Powershell, and Bash. The folder includes the [root template][root-template] (note that some of the nested templates are stored on Github), parameter files, [Powershell script][solution-psscript], [Bash script][solution-shscript], and a Visual Studio project file.

The reference architecture can be deployed using several methods:

### **Portal**

1. Click the button below.

	<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Freference-architectures%2Fmaster%2Fguidance-compute-single-vm%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/></a>

2. Once the link has opened in the Azure portal, you must enter values for some of the settings: 
    - The **Resource group** name is already defined in the parameter file, so select **Use Existing** and enter `ra-single-vm-rg` in the text box.
    - Select the region from the **Location** drop down box.
    - Select the **Os Type** from the drop down box, **windows** or **linux**.
    - Review the terms and conditions, then click the **I agree to the terms and conditions stated above** checkbox.
    - Click on the **Purchase** button.

3. Wait for the deployment to complete.

### **PowerShell**
1. Download the files from [Github][github-folder] and place them in a local directory. 

2. Open a [PowerShell console][azure-powershell-download] and navigate to the local directory where you placed the solution components.

3. Run the cmdlet below, substituting your Azure subscription ID for `<id>`, the region for `<location>`, and the Os type you'd like to deploy for `<linux|windows>`. 

````
.\Deploy-ReferenceArchitecture -SubscriptionId <id> -Location <location> -OSType <linux|windows> -ResourceGroupName ra-single-vm-rg
````

### **Bash**
1. Download the files from [Github][github-folder] and place them in a local directory. 

2. Open a bash console and navigate to the local directory where you placed the solution components.

3. Run the command below, substituting your Azure subscription ID for `<id>`, the region for `<location>`, and the Os type you'd like to deploy for `<linux|windows>`.

````
sh deploy-reference-architecture.sh -s <subscription id> -l <location> -o <linux|windows> -r ra-single-vm-rg
````

## Understanding this reference architecture deployment

If you haven't downloaded the reference architecture files from [Github][github-folder] yet, do that now so you can refer to the parameter files as you read. If you don't want to download the files, you can click on the link to the file in Github in each section.

This reference architecture is deployed using a set of building block templates that we've provided. These [building block templates](https://github.com/mspnp/template-building-blocks/) are designed to make it easy to deploy resources that are commonly deployed together. For example, a virtual machine requires networking, network security, and other resources to be deployed, and would use the virtual networking, network security group, and virtual machine building block templates.  

Each building block template requires a corresponding parameter file to define the resources that will be deployed. The path to these parameter files in the Github folder is `\parameters\` with another set of folders for each operating system deployment under that. Let's take a look at each of the parameter files and the values of the properties used to deploy this reference architecture.

### Virtual network

The `virtualNetwork.parameters.json` ([windows][vnet-windows-parameters]/[linux][vnet-linux-parameters]) file is used by the [vnet-n-subnet][bb-vnet] template. It includes a single parameter, `virtualNetworkSettings`. This parameter defines the properties used by the Resource Manager to create the VNet. Note that these property values are the same for both the `windows` and `linux` parameter files.

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

The `name` property specifies the name to be assigned to the VNet. This name is used both to define the name of the VNet in the Azure environment and as a reference for other resources in the other templates.

The `addressPrefixes` array specifies CIDR address blocks for the VNet.In this deployment there's only a single address block for the VNet, `10.0.0.0/16`. 

The `resourceGroup` property specifies the name of an existing Resource Group that the VNet will be assigned to. In this deployment, the `resourceGroup` property is either set as part of the deployment process using the UI, or it's passed to the template by the deployment script. 

The `subnets` property defines the subnets in the VNet. More than one subnet can be defined in the Vnet, so this is defined as an array to hold multiple elements. In this deployment, only one subnet will be deployed.

- The `name` sub-property defines the name of the subnet. It is also used as reference for other resources in the deployment templates.

- The `addressPrefix` sub-property specifies the CIDR address block for the subnet. Note that the address block specified for the subnet (`10.0.1.0/24`) must be fall within the address block specified for the VNet (`10.0.0.0/16`).

The `dnsServers` property is an array of elements to define the IP addresses of private DNS servers for the VNet. The array here is empty to specify that Azure-managed DNS should be used for name resolution. 

### Network security group

The `networkSecurityGroups.parameters.json` ([windows][nsg-windows-parameters]/[linux][nsg-linux-parameters]) file is used by the [networkSecurityGroups][bb-nsg] template. It includes two parameters: `virtualNetworkSettings` and `networkSecurityGroupsSettings`. These parameters are used by the Resource Manager to create a Network Security Group that will be attached to the VNet.

#### windows:
````json
{
  "parameters": {
    "virtualNetworkSettings": {
      "value": {
        "name": "ra-single-vm-vnet"
      }
    },
    "networkSecurityGroupsSettings": {
      "value": [
        {
          "name": "ra-single-vm-nsg",
          "subnets": [
            "web"
          ],
          "networkInterfaces": [
          ],
          "securityRules": [
            {
              "name": "RDPAllow",
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
  }
}
````

#### linux:
````json
  "parameters": {
    "virtualNetworkSettings": {
      "value": {
        "name": "ra-single-vm-vnet",
        "resourceGroup": "ra-single-vm-rg"
      }
    },
    "networkSecurityGroupsSettings": {
      "value": [
        {
          "name": "ra-single-vm-nsg",
          "subnets": [
            "web"
          ],
          "networkInterfaces": [
          ],
          "securityRules": [
            {
              "name": "default-allow-ssh",
              "direction": "Inbound",
              "priority": 1000,
              "sourceAddressPrefix": "*",
              "destinationAddressPrefix": "*",
              "sourcePortRange": "*",
              "destinationPortRange": "22",
              "access": "Allow",
              "protocol": "Tcp"
            }
          ]
        }
      ]
    }
  }
````

The `virtualNetworkSettings` parameter references the VNet that the NSGs will be attached to. In this example, the `name` property references the VNet created above. The `resourceGroup` property references the resource group, note that it's consistent with the other templates. Note that this is the same for both `windows` and `linux` deployments.

The `networkSecurityGroupsSettings` parameter is an array because one or more NSGs can be provisioned. Each element of the array includes properties to specify the creation of a NSG. In this example, there is a single NSG settings object defined in the parameter to create one NSG.  

- The `name` property defines the name of the NSG. This is the same for both `windows` and `linux` deployments.

- The `subnets` property is an array with elements that reference the names of the subnets that the NSG will apply to. In this deployment, the value `web` references the CIDR address block `10.0.1.0\24` defined above in the VNet parameters. This is the same for both `windows` and `linux` deployments. 

- The `networkInterfaces` property is an array that references the names of the NICs that the NSG will be restricted to. This property is empty to specify that all the NSG should apply to all NICs. This is the same for both `windows` and `linux` deployments.

- The `securityRules` element includes an array to specify the properties for the security rules that will be created for the NSG. For the `windows` deployment, the properties specify an inbound rule to allow remote desktop connections. For the `linux` deployment, the properties specify an inbound rule to allow SSH session connections.

### Virtual machine

The `virtualMachine.parameters.json` ([windows][vm-windows-parameters]/[linux][vm-linux-parameters]) file is used by the 
[multi-vm-n-nic-m-storage][bb-vm] template. It includes three parameters: `virtualMachinesSettings`, `virtualNetworkSettings`, and `buildingBlockSettings`. These parameters are used by the Resource Manager to create the VM and deploy it in the VNet. 

#### windows:
````json
   "parameters": {
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
    },
    "virtualNetworkSettings": {
      "value": {
        "name": "ra-single-vm-vnet",
        "resourceGroup": "ra-single-vm-rg"
      }
    },
    "buildingBlockSettings": {
      "value": {
        "storageAccountsCount": 1,
        "vmCount": 1,
        "vmStartIndex": 0
      }
    }
  }
````

#### linux:
````json
  "parameters": {
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
    },
    "virtualNetworkSettings": {
      "value": {
        "name": "ra-single-vm-vnet",
        "resourceGroup": "ra-single-vm-rg"
      }
    },
    "buildingBlockSettings": {
      "value": {
        "storageAccountsCount": 1,
        "vmCount": 1,
        "vmStartIndex": 0
      }
    }
  }
````

The `virtualMachinesSettings` parameter includes properties that define the creation of the VM. 

The template automatically generates Azure display names and OS host names based on the number of VMs that are created. The `namePrefix` property specifies the prefix of the Azure display name for each VM, and the `computerNamePrefix` specifies the prefix for the host name for the VM's OS. A suffix is appended to both based on the order in which the VM was created by the Resource Manager. In this example the `namePrefix` property is set to `"ra-single-vm"`. Only one VM is specified for creation (see the `vmCount` property in the  `buildingBlockSettings` parameter below for more details), and this results in an Azure display name of `"ra-single-vm1"`. The `computerNamePrefix` property is set to `"cn"`, which results in an OS name of `"cn1"`. This is the same for both `Windows` and `Linux` deployments.

The `size` property references the size of the VM. In this example, a DS_ series VM is specified by setting the `size` property to `"Standard_DS1_v2"`. This size is the same for both `windows` and `linux` deployments.

The `osType` property is a directive used by the building blocks templates themselves. The valid values are `windows` for Windows VMs and `linux` for Linux VMs.  

The VM's OS requires an administrator account. The user name for the admin account is specified in the `adminUsername` property and the password is specified in the `adminPassword` property. The `osAuthenticationType` property specifies the sign in authentication type: `password` or `ssh`. Note that the only valid value for a `windows` deployment is `password`, while either `password` or `ssh` is valid for a `linux` deployment. The `adminUsername` and `adminPassword` property values are purposely left blank here for security, so you will have to provide your own administrator user name and administrator password.  

The `nics` property specifies the NIC settings for the VM's virtual network interface. A VM can have more than one NIC assigned to it so this property is implemented as an array of multiple NIC property objects. In this example only a single NIC is to be created so there is a single NIC property object in the array. The `subnetName` sub-property references the name of the subnet that the NIC will be associated with. The `isPublic` sub-property specifies whether or not a [Public IP resource][public-ip-address] will be created and associated with the NIC. This PIP can be assigned an IP address either statically or dynamically and this is specified in the `publicIPAllocationMethod` sub-property. The NIC will also be assigned a private IP address by Azure-managed DNS servers within the VNet. This private IP address can be either statically or dynamically assigned and this is is specified in the `privateIPAllocationMethod` sub-property. The `enableIPForwarding` sub-property specifies whether or not the NIC will route packets within the VNet. The `isPrimary` sub-property specifies whether or not the NIC is the primary NIC for the VM. And, the `dnsServer` sub-property is an array containing the addresses of any custom DNS Servers within the VNet. This array is blank in the example to specify that the Azure-managed DNS is to be used.

The `imageReference` parameter specifies the OS to be installed on the VM. The values of the `Windows` deployment properties deploys a VM with Windows Server 2012 R2 Datacenter. The values of the `Linux` deployment properties deploys a VM with Canonical Ubuntu Server.

The `dataDisks` property defines the attributes of the data disks that are to be created for use with the VM. In this example, the values of the properties create two empty data disks that are 128GB in size, empty upon creation, and do not cache.

The `osDisk` property defines the cache setting of the OS drive for the VM. In this example, the value of the `caching` sub-property specifies that the OS disk is to perform write-back caching.

The `availabilitySet` property references the availability set for the VM, but since we are creating a single VM in both the `windows` and `linux` deployments, it's not possible to create an availability set.

The `extensions` property is used to reference [Azure VM Extensions][azure-vm-extensions]. It's blank for both the `windows` and `linux` deployments because we're not installing any extensions.

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
[guidance]: https://azure.microsoft.com/en-us/documentation/articles/guidance-compute-single-vm-linux/
[linking-to-a-template]:https://azure.microsoft.com/en-us/documentation/articles/resource-group-linked-templates/
[nsg-linux-parameters]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-single-vm/parameters/linux/networkSecurityGroups.parameters.json
[nsg-windows-parameters]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-single-vm/parameters/windows/networkSecurityGroups.parameters.json
[root-template]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-single-vm/azuredeploy.json
[solution-shscript]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-single-vm/deploy-reference-architecture.sh
[solution-psscript]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-single-vm/Deploy-ReferenceArchitecture.ps1
[vnet-linux-parameters]: https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-single-vm/parameters/linux/virtualNetwork.parameters.json 
[vnet-windows-parameters]: https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-single-vm/parameters/windows/virtualNetwork.parameters.json
[vm-linux-parameters]: https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-single-vm/parameters/linux/virtualMachine.parameters.json
[vm-windows-parameters]: https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-single-vm/parameters/windows/virtualMachine.parameters.json