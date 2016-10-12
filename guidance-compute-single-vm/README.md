# Deploying a single VM to Azure

You can read the [guidance on deploying a single VM to Azure][guidance] document to understand the best practices related to single VM deployment that accompanies the reference architecture below.

![[0]][0]

## Solution components

The reference architecture above is deployed using different building blocks for virtual network, network security group, and virtual machine.

You can deploy these template building blocks by using:
- [a template file][solution-template]
- [a PowerShell script][solution-psscript]
- [a bash script][solution-shscript]

Each building block consumes a parameter file that you can download and modify for your own environment. The parameters used in this deployment scenario are as follows.

### Virtual network

Download the [virtualNetwork.parameters.json][vnet-parameters] and make any necessary changes. You can learn about each parameter used in this file in the [vnet-n-subnet][bb-vnet] building block **readme** page. The parameter file used in this scenario creates a vnet with a single subnet, using 10.0.1.0/24 as its CIDR as follows.

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

The `virtualNetworkSettings` parameter in this file defines the properties used by the Resource Manager to create the VNet.

The `name` property specifies the name to be assigned to the VNet. This name is used to define the name of the VNet in the Azure environment and as a reference for the other resources in the template.  

The `resourceGroup` property specifies the name of an existing Resource Group that the VNet will be assigned to. In this example, the `resourceGroup` property is set to the value specifed for the resource group in the [Azure Powershell script][azure-powershell-download] that is included as part of the solution. 

The `subnets` property includes an array of elements to define subnets in the VNet. For each element in the array, the `name` property identifies the subnet and the `addressPrefix` property specifies the addresses that are included in the subnet. Note that the addresses specified for the subnet must be within the range of addresses specified for the VNet.

The `dnsServers` property is an array of elements to define the IP addresses of private DNS servers for the VNet. An empty array specifies that Azure-managed DNS should be used for name resolution. 

### Network security group

Download the [networkSecurityGroup.parameters.json][nsg-parameters] and make any necessary changes. You can learn about each parameter used in this file in the [networkSecurityGroups][bb-nsg] building block **readme** page. The parameter file used in this scenario creates an NSG with a single rule, allowing SSH access, linked to the **web** subnet as follows.

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
This file includes two parameters: `virtualNetworkSettings` and `networkSecurityGroupsSettings`. These parameters are used by the Resource Manager to create a Network Security Group that will be attached to the VNet.

The `virtualNetworkSettings` parameter references the VNet and the Resource Group that the NSGs will be attached to. In this example, the `name` property references the VNet created above. The `resourceGroup` property references the same Resource Group that the VNet above is assigned to.

The `networkSecurityGroupsSettings` parameter is an array in which each element includes properties to specify the creation of a NSG. In this example, there is a single NSG settings object defined in the parameter to create one NSG.  

The `name` property defines the name of the NSG. 

The `subnets` property is an array with elements that reference the names of the subnets that the NSG will apply to.

The `networkInterfaces` property is an array that references the names of the NICs that the NSG will be restricted to.  

The `securityRules` element includes an array to specify the properties for the security rules that will be created for the NSG. The valid rules and their associated values are documented in the **networkSecurityGroups** documentation. In this example, the security properties shown here specify a rule to allow remote desktop (RDP) connections to the VM.

### Virtual machine

Download the [virtualMachineParameters.json][vm-parameters] and make any necessary changes. You can learn about each parameter used in this file in the [multi-vm-n-nic-m-storage][bb-vm] building block **readme** page. 

Windows:

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
        "sshPublicKey": "",
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

The parameter file used in this scenario creates a single Linux VM with a NIC, a public IP address, and two data disks as follows.

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

This file includes three parameters: `virtualMachinesSettings`, `virtualNetworkSettings`, and `buildingBlockSettings`. These parameters are used by the Resource Manager to create the VM and deploy it in the VNet.

The `virtualNetworkSettings` parameter references the VNet that the VM will be deployed to. The `name` property references the name of the VNet. The `resourceGroup` property references the name of the Resource Group that includes the VNet. 

The `virtualMachinesSettings` parameter includes properties that define the creation of the VM. 

The template automatically generates Azure display names and OS host names based on the number of VMs that are to be created. The `namePrefix` property specifies the prefix of the Azure display name for each VM, and the `computerNamePrefix` specifies the prefix for the host name for the VM's OS. A suffix is appended to both based on the order in which the VM was created by the Resource Manager. In this example the `namePrefix` property is set to `"ra-single-vm"`. In the `buildingBlockSettings` parameter the `vmCount` property is set to `1`, and this results in an Azure display name of `"ra-single-vm1"`. The `computerNamePrefix` property is set to `"cn"`, which results in an OS name of `"cn1"`.

The `size` property references the size of the VM. In this example, a DS_ series VM is specified by setting the `size` property to `"Standard_DS1_v2"`.

The `osType` property is a reference for the template to use this particular parameter based on a variable defined in the Powershell script included in the solution for this example.  

The `imageReference` parameter specifies the OS to be installed on the VM. The values of the properties shown in this example create a VM with the latest build of Windows Server 2012 R2 Datacenter. 

The VM's OS requires an administrator account. The user name for the admin account is specified in the `adminUsername` property and the password is specified in the `adminPassword` property. The `osAuthenticationType` property specifies the sign in authentication type: `password` or `ssh` but this value is only used on a VM with a Linux OS installed. The `adminUsername` and `adminPassword` property values are purposely left blank in this example.  

The `osDisk` property defines the cache setting of the OS drive for the VM. In this example, the value of the `caching` sub-property specifies that the OS disk is to perform write-back caching.

The `nics` property specifies the NIC settings for the VM's virtual network interface. A VM can have more than one NIC assigned to it so this property is implemented as an array of multiple NIC property objects. In this example only a single NIC is to be created so there is a single NIC property object in the array. The `subnetName` sub-property references the name of the subnet that the NIC will be associated with. The `isPublic` sub-property specifies whether or not a [Public IP resource][public-ip-address] will be created and associated with the NIC. This PIP can be assigned an IP address either statically or dynamically and this is specified in the `publicIPAllocationMethod` sub-property. The NIC will also be assigned a private IP address by Azure-managed DNS servers within the VNet. This private IP address can be either statically or dynamically assigned and this is is specified in the `privateIPAllocationMethod` sub-property. The `enableIPForwarding` sub-property specifies whether or not the NIC will route packets within the VNet. The `isPrimary` sub-property specifies whether or not the NIC is the primary NIC for the VM. And, the `dnsServer` sub-property is an array containing the addresses of any custom DNS Servers within the VNet. This array is blank in the example to specify that the Azure-managed DNS is to be used.

The `dataDisks` property defines the attributes of the data disks that are to be created for use with the VM. In this example, the values of the properties create 2 empty data disks that are 128GB in size, empty upon creation, and do not cache.

The `availabilitySet` property references the availability set for the VM, but since we are creating a single VM in this example there is no availability set. The `extensions` property is used to reference [Azure VM Extensions][azure-vm-extensions], but those will be covered later so the array is blank here.

The `buildingBlockSettings` parameter is a set of properites used to define the number of VMs and Storage Accounts that are to be created. As mentioned above, the `vmCount` property defines the number of VMs to be created. The 'vmStartIndex` property is used to define the initial value of the numbering to be used for the VM names. The `storageAccountsCount` property defines the number of Storage Accounts to be created.

## Solution deployment

You can deploy this reference architecture by using PowerShell, bash, or the Azure portal. To do so using your own parameter files, follow the instructions below.

1. Download all the files and folders in this folder.

2. In the **parameters** folder, customize each parameter file according to your needs.

3. Follow the steps in one of the following sections to deploy your solution.

### Portal
1. Copy your parameters files to a URI that is publicly accessible.

2. Click the button below.

	<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Freference-architectures%2Fmaster%2Fguidance-compute-single-vm%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/></a>

3. In the Azure portal, specify the **Subscription**, **Resource group**, and **Location** you want to use for your deployment.

	**Note** Make sure the **Resource group** name used matches the value used in your parameter files.

4. In the **Parameter Root Uri** textbox, type the URL where you copied your parameter files to. Remember, this must be a publicly accessible URL.

5. Specify the **OS Type** (Windows or Linux).

6. Click **I agree to the terms and conditions stated above** and then click **Purchase**.

### PowerShell
1. Open a PowerShell console and navigate to the folder where you downloaded the script and parameter files.

2. Run the cmdlet below using your own subscription id, location, OS type, and resource group name.

	.\Deploy-ReferenceArchitecture -SubscriptionId <id> -Location <location> -OSType <linux|windows> -ResourceGroupName <resource group>

### Bash
1. Open a bash console and navigate to the folder where you downloaded the script and parameter files.

2. Run the command below using your own subscription id, location, OS type, and resource group name.

	sh deploy-reference-architecture.sh -s <subscription id> -l <location> -o <linux|windows> -r <resource group>

<!-- links -->
[0]: ./diagram.png
[bb]: https://github.com/mspnp/template-building-blocks
[bb-vnet]: https://github.com/mspnp/template-building-blocks/tree/master/templates/buildingBlocks/vnet-n-subnet
[bb-nsg]: https://github.com/mspnp/template-building-blocks/tree/master/templates/buildingBlocks/networkSecurityGroups
[bb-vm]: https://github.com/mspnp/template-building-blocks/tree/master/templates/buildingBlocks/multi-vm-n-nic-m-storage
[deployment]: #Solution-deployment
[solution-shscript]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-single-vm/deploy-reference-architecture.sh
[solution-psscript]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-single-vm/Deploy-ReferenceArchitecture.ps1
[solution-template]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-single-vm/azuredeploy.json
[vnet-parameters]: https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-single-vm/parameters/linux/virtualNetwork.parameters.json 
[nsg-parameters]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-single-vm/parameters/linux/networkSecurityGroups.parameters.json
[vm-parameters]: https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-single-vm/parameters/linux/virtualMachine.parameters.json
[guidance]: https://azure.microsoft.com/en-us/documentation/articles/guidance-compute-single-vm-linux/