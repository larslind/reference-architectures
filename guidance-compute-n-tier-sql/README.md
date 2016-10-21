# Deploying multiple Windows VMs to Azure with an N-tier architecture

This reference architecture (RA) deploys multiple Windows virtual machine (VM) instances to Azure with an n-tier architecture shown below. This RA implements the proven best practices for [running Windows VMs for an N-tier architecture][guidance], and we recommend you read that document before moving on to this.

![[0]][0]

## Deployment components

This RA is deployed using a set of Azure Resource Manager templates that we've designed to be a set of building blocks.  

The templates use a set of [parameter files][root-parameters] to specify the resources that will be deployed. 

You can deploy this RA as is by following the instructions in the [Deploying this Reference Architecture](#deploying-this-reference-architecture) section. 

You can modify this RA by editing the parameter files, but it's best to first read the [Understanding this reference architecture deployment](#understanding-this-reference-architecture-deployement) section, and then the [customizing this reference architecture deployment](#customizing-this-deployment) section.

## Deploying this reference architecture

The [Github folder][root] includes the files for deploying using Azure Powershell. This folder includes the parameter files for both Windows and Linux, a [Powershell script][solution-psscript], a [Bash script][solution-shscript], and a Visual Studio project file. The powershell script has to be executed in three separate modes: `Infrastructure` to deploy SQL Server, `Workload` to deploy the web tier and business tier, and finally `Security` to deploy the 

1. Download the files from [Github][github-folder] and place them in a local directory.

2. 

3. Open a [PowerShell console][azure-powershell-download] and navigate to the local directory where you placed the solution components.

4. Run the cmdlet below, substituting your Azure subscription ID for `<id>`, the region for `<location>`, and the Os type you'd like to deploy for `<linux|windows>`. 

````
.\Deploy-ReferenceArchitecture -SubscriptionId <id> -Location <location> -OSType <linux|windows> -ResourceGroupName ra-single-vm-rg
````

### **Bash** for Linux
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

This reference architecture includes a VNet, a NSG, and two VMs as shown in the architecture diagram above. Let's take a look at each of the **parameter files** and the values of the properties used to deploy this reference architecture.

> Note that the building block templates deploy all resources into a single resource group. 

The script references the following parameter files to build the VMs and the surrounding infrastructure. Note that there are two versions of these files; one for Windows VMs and another for Linux (RedHat). The examples shown below depict the Windows versions. The Linux files are very similar except where described:

- **[virtualNetwork.parameters.json][vnet-parameters-windows]**. This file defines the VNet settings. The VNet contains separate subnets for the web, business, and database tiers, and a further subnet for hosting the VMs running management services. You can also specify the addresses of any DNS servers required. Note that subnet addresses must be contained within the address space of the VNet:

<!-- source: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-n-tier/parameters/windows/virtualNetwork.parameters.json#L4-L32 -->

```json
  "parameters": {
    "virtualNetworkSettings": {
      "value": {
        "name": "ra-vnet",
        "addressPrefixes": [
          "10.0.0.0/16"
        ],
        "subnets": [
          {
            "name": "app1-web-sn",
            "addressPrefix": "10.0.0.0/24"
          },
          {
            "name": "app1-biz-sn",
            "addressPrefix": "10.0.1.0/24"
          },
          {
            "name": "app1-data-sn",
            "addressPrefix": "10.0.2.0/24"
          },
          {
            "name": "app1-mgmt-sn",
            "addressPrefix": "10.0.3.0/24"
          }
        ],
        "dnsServers": [ ]
      }
    }
  }
```

- **[webTier.parameters.json][webtier-parameters-windows]**. This file defines the settings for the VMs in the web tier, including the [size of each VM][VM-sizes], the security credentials for the admin user, the disks to be created, the storage accounts to hold these disks. This file also contains the definition of an availability set for the VMs, and the load balancer configuration for distributing traffic across the VMs in this set.

<!-- source: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-n-tier/parameters/windows/webTier.parameters.json#L4-L103 -->

```json
  "parameters": {
    "loadBalancerSettings": {
      "value": {
        "name": "app1-web-lb",
        "frontendIPConfigurations": [
          {
            "name": "lb-fe-config1",
            "loadBalancerType": "public",
            "internalLoadBalancerSettings": {
              "privateIPAddress": "10.0.0.250",
              "subnetName": "app1-web-sn"
            }
          }
        ],
        "loadBalancingRules": [
          {
            "name": "lbr1",
            "frontendPort": 80,
            "backendPort": 80,
            "protocol": "Tcp",
            "backendPoolName": "lb-bep1",
            "frontendIPConfigurationName": "lb-fe-config1"
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
            "name": "lb-bep1",
            "nicIndex": 0
          }
        ],
        "inboundNatRules": [ ]
      }
    },
    "virtualMachinesSettings": {
      "value": {
        "namePrefix": "ra",
        "computerNamePrefix": "cn",
        "size": "Standard_DS1",
        "adminUsername": "testuser",
        "adminPassword": "AweS0me@PW",
        "osType": "windows",
        "osAuthenticationType": "password",
        "sshPublicKey": "",
        "nics": [
          {
            "isPublic": "false",
            "isPrimary": "true",
            "subnetName": "app1-web-sn",
            "privateIPAllocationMethod": "dynamic",
            "enableIPForwarding": false,
            "dnsServers": [ ]
          }
        ],
        "imageReference": {
          "publisher": "MicrosoftWindowsServer",
          "offer": "WindowsServer",
          "sku": "2012-R2-Datacenter",
          "version": "latest"
        },
        "osDisk": {
          "caching": "ReadWrite"
        },
        "dataDisks": {
          "count": 1,
          "properties": {
            "diskSizeGB": 128,
            "caching": "None",
            "createOption": "Empty"
          }
        },
        "extensions": [ ],
        "availabilitySet": {
          "useExistingAvailabilitySet": "No",
          "name": "app1-web-as"
        },
        "extensions": [ ]
      }
    },
    "virtualNetworkSettings": {
      "value": {
        "name": "ra-vnet",
        "resourceGroup": "ra-ntier-vm-rg"
      }
    },
    "buildingBlockSettings": {
      "value": {
        "storageAccountsCount": 1,
        "vmCount": 3,
        "vmStartIndex": 1
      }
    }
  }
```

  The `virtualMachineSettings` section contains the configuration details for the VMs. The physical VM names and the logical computer names of the VMs are generated, based on the values specified for the `namePrefix` and `computerNamePrefix` parameters together with the `vmCount` parameter in the `buildingBlockSettings` section at the end of the file. (The `vmCount` parameter determines the number of VMs to build, and the `vmStartIndex` parameter indicates a starting point for numbering VMs.) The values shown above generate the suffixes 1, 2, and 3 which are appended to the names generated by the `namePrefix` and `computerNamePrefix`. Using the default values for these parameters (shown above), the physical names of the VMs that appear in the Azure portal will be ra-vm1, ra-vm2, and ra-vm3. The computer names of the VMs that appear on the virtual network will be cn1, cn2, and cn3.

  The `subnetName` parameter in the `nics` section specifies the subnet for the VMs. Similarly, the `name` parameter in the `virtualNetworkSettings` identifies the VNet to use. These should be the name of a subnet and VNet defined in the **virtualNetwork.parameters.json** file.

  You must specify an image in the `imageReference` section. The values shown above create a VM with the latest build of Windows Server 2012 R2 Datacenter. You can use the following Azure CLI command to obtain a list of all available Windows images in a region (the example uses the westus region):

  ```text
  azure vm image list westus MicrosoftWindowsServer WindowsServer
  ```

  The default configuration for building Linux VMs references Ubuntu Linux 14.04. The `imageReference` section looks like this:

<!-- source: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-n-tier/parameters/linux/webTier.parameters.json#L65-L70 -->

```json
  "imageReference": {
    "publisher": "Canonical",
    "offer": "UbuntuServer",
    "sku": "14.04.5-LTS",
    "version": "latest"
  },
```

  Note that in this case the `osType` parameter must be set to `linux`. If you want to base your VMs on a different build of Linux from a different vendor, you can use the `azure vm image list` command to view the available images.

  The `loadBalancerSettings` section specifies the configuration for the load balancer used to direct traffic to the VMs. The default configuration creates a public load balancer with an internal IP address of `10.0.0.250`. You can change this, but the address must fall within the address space of the specified subnet. The load balancer rules handle traffic appearing on TCP port 80 with a health probe referencing the same port. You can change these ports as appropriate, and you can add further load balancing rules if you need to open up different ports.

  >[AZURE.NOTE] The template does not install any web servers on the VMs in this tier. You can install a web server of your choice (IIS, Apache, etc) manually.

- **[businessTier.parameters.json][businesstier-parameters-windows]**. This file contains the settings for the load balancer and VMs in the business tier. The parameters are very similar to those used by the template for creating the web tier. Note that you must set the values in the `buildingBlockSettings` section at the end of the file to ensure that VM and computer names do not clash with those in the web tier. The default configuration (shown below) creates a set of 3 VMs starting with suffix 4. The default web tier configuration uses suffixes 1 through 3, but if you create more VMs in the web tier you should adjust the `vmStartIndex` in this file:

<!-- source: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-n-tier/parameters/windows/businessTier.parameters.json#L96-L102 -->

```json
  "buildingBlockSettings": {
    "value": {
      "storageAccountsCount": 1,
      "vmCount": 3,
      "vmStartIndex": 4
    }
  }
```

- **[dataTier.parameters.json][datatier-parameters-windows]**. This file contains the settings for the load balancer and VMs in the database tier. As before, the parameters are very similar to those used by the template for creating the web tier. Again, you must be careful to set the `vmStartIndex` value in the `buildingBlockSettings` section of this file to avoid clashes with VM and computer names in the other two tiers.

  >[AZURE.NOTE] The template does not install any database software on the VMs in this tier. You must perform this task manually.

- **[networkSecurityGroup.parameters.json][nsg-parameters-windows]**. This file contains the definitions of NSGs and NSG rules for each of the subnets. The `name` parameter in the `virtualNetworkSettings` block specifies the VNet to which the NSG is attached. The `subnets` parameter in each of the `networkSecurityGroupSettings` blocks identifies the subnets which apply the NSG rules in the VNet. These should be items defined in the **virtualNetwork.parameters.json** file.

  The security groups implement the following rules:

  - The business tier only permits traffic that arrives on port 80 from VMs in the web tier. All other traffic is blocked.

  - The database tier only permits traffic that arrives on port 80 from VMs in the business tier. All other traffic is blocked.

  - The web tier only permits traffic that arrives on port 80. These requests can originate from an external network or from VMs in any of the subnets in the VNet. All other traffic is blocked.

  - The management subnet permits a user to connect to a VMs in this tier through a remote desktop (RDP) connection. All other traffic is blocked.
    For security purposes, the web, business, and database tiers block RDP/SSH traffic by default, even from the management tier. You can temporarily create additional rules to open these ports to enable you to connect and install software on these tiers, but then you can disable them again afterwards. However, you should open any ports required by whatever tools you are using to monitor and manage the web, business, and database tiers from the management tier.

  >[AZURE.IMPORTANT] The NSG rules for the management tier are applied to the NIC for the jump box rather than the management subnet. The default name for this NIC, ra-vm9-nic1, assumes that you haven't changed the `namePrefix` value for the management tier VMs, and that you have not modified the number or starting index of the VMs in each tier (by default, the jump box will be given the suffix 9). If you have changed these parameters, then you must also modify the value of the NIC referenced by the management tier NSG rules accordingly, otherwise they may be applied to a NIC associated with a different VM.

<!-- source:  https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-n-tier/parameters/windows/networkSecurityGroups.parameters.json#L4-L162 -->

```json
  "parameters": {
    "virtualNetworkSettings": {
      "value": {
        "name": "ra-vnet",
        "resourceGroup": "ra-ntier-vm-rg"
      }
    },
    "networkSecurityGroupsSettings": {
      "value": [
        {
          "name": "app1-biz-nsg",
          "subnets": [
            "app1-biz-sn"
          ],
          "networkInterfaces": [
          ],
          "securityRules": [
            {
              "name": "allow-web-traffic",
              "description": "Allow traffic originating from web layer.",
              "protocol": "*",
              "sourcePortRange": "*",
              "destinationPortRange": "80",
              "sourceAddressPrefix": "10.0.0.0/24",
              "destinationAddressPrefix": "*",
              "access": "Allow",
              "priority": 100,
              "direction": "Inbound"
            },
            {
              "name": "deny-other-traffic",
              "description": "Deny all other traffic",
              "protocol": "*",
              "sourcePortRange": "*",
              "destinationPortRange": "*",
              "sourceAddressPrefix": "*",
              "destinationAddressPrefix": "*",
              "access": "Deny",
              "priority": 120,
              "direction": "Inbound"
            }
          ]
        },
        {
          "name": "app1-data-nsg",
          "subnets": [
            "app1-data-sn"
          ],
          "networkInterfaces": [
          ],
          "securityRules": [
            {
              "name": "allow-biz-traffic",
              "description": "Allow traffic originating from biz layer.",
              "protocol": "*",
              "sourcePortRange": "*",
              "destinationPortRange": "80",
              "sourceAddressPrefix": "10.0.1.0/24",
              "destinationAddressPrefix": "*",
              "access": "Allow",
              "priority": 100,
              "direction": "Inbound"
            },
            {
              "name": "deny-other-traffic",
              "description": "Deny all other traffic",
              "protocol": "*",
              "sourcePortRange": "*",
              "destinationPortRange": "*",
              "sourceAddressPrefix": "*",
              "destinationAddressPrefix": "*",
              "access": "Deny",
              "priority": 120,
              "direction": "Inbound"
            }
          ]
        },
        {
          "name": "app1-web-nsg",
          "subnets": [
            "app1-web-sn"
          ],
          "networkInterfaces": [
          ],
          "securityRules": [
            {
              "name": "allow-web-traffic-from-external",
              "description": "Allow web traffic originating externally.",
              "protocol": "*",
              "sourcePortRange": "*",
              "destinationPortRange": "80",
              "sourceAddressPrefix": "*",
              "destinationAddressPrefix": "*",
              "access": "Allow",
              "priority": 100,
              "direction": "Inbound"
            },
            {
              "name": "allow-web-traffic-from-vnet",
              "description": "Allow web traffic originating from vnet.",
              "protocol": "*",
              "sourcePortRange": "*",
              "destinationPortRange": "80",
              "sourceAddressPrefix": "10.0.0.0/16",
              "destinationAddressPrefix": "*",
              "access": "Allow",
              "priority": 110,
              "direction": "Inbound"
            },
            {
              "name": "deny-other-traffic",
              "description": "Deny all other traffic",
              "protocol": "*",
              "sourcePortRange": "*",
              "destinationPortRange": "*",
              "sourceAddressPrefix": "*",
              "destinationAddressPrefix": "*",
              "access": "Deny",
              "priority": 120,
              "direction": "Inbound"
            }
          ]
        },
        {
          "name": "app1-mgmt-nsg",
          "subnets": [ ],
          "networkInterfaces": [
            "ra-vm9-nic1"
          ],
          "securityRules": [
            {
              "name": "RDP",
              "description": "Allow RDP Subnet",
              "protocol": "tcp",
              "sourcePortRange": "*",
              "destinationPortRange": "3389",
              "sourceAddressPrefix": "*",
              "destinationAddressPrefix": "*",
              "access": "Allow",
              "priority": 100,
              "direction": "Inbound"
            },
            {
              "name": "deny-other-traffic",
              "description": "Deny all other traffic",
              "protocol": "*",
              "sourcePortRange": "*",
              "destinationPortRange": "*",
              "sourceAddressPrefix": "*",
              "destinationAddressPrefix": "*",
              "access": "Deny",
              "priority": 120,
              "direction": "Inbound"
            }
          ]
        }
      ]
    }
  }
```

Note that the management tier security rule for the Linux implementation differs in that it opens port 22 to enable SSH connections rather than RDP:

<!-- source: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-n-tier/parameters/linux/networkSecurityGroups.parameters.json#L20-L45 -->

```json
"securityRules": [
  {
    "name": "allow-web-traffic",
    "description": "Allow traffic originating from web layer.",
    "protocol": "*",
    "sourcePortRange": "*",
    "destinationPortRange": "80",
    "sourceAddressPrefix": "10.0.0.0/24",
    "destinationAddressPrefix": "*",
    "access": "Allow",
    "priority": 100,
    "direction": "Inbound"
  },
  {
    "name": "deny-other-traffic",
    "description": "Deny all other traffic",
    "protocol": "*",
    "sourcePortRange": "*",
    "destinationPortRange": "*",
    "sourceAddressPrefix": "*",
    "destinationAddressPrefix": "*",
    "access": "Deny",
    "priority": 120,
    "direction": "Inbound"
  }
]
```

You can open additional ports (or deny access through specific ports) by adding further items to the `securityRules` array for the appropriate subnet.



------------------------------


## Customizing this reference architecture deployment

Now that you've seen how the reference architecture deployment parameter files were created, you can edit the parameter files to customize it. The parameter documentation for each template is available here:

|Template|Parameter File|Documentation|
|--------|--------------|-------------|
|Vnet|virtualNetwork.parameters.json|[vnet-n-subnet][bb-vnet]|
|NSG|networkSecurityGroups.parameters.json|[networkSecurityGroups][bb-nsg]|
|VMs and load balancer|loadBalancer.parameters.json.parameters.json|[loadBalancer-backend-n-vm][bb-vm]|

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
[github-folder]:https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-n-tier
[guidance]: https://azure.microsoft.com/documentation/articles/guidance-compute-n-tier-vm/
[nsg-parameters]: https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-n-tier-sql/parameters
[nsg-windows-parameters]: https://github.com/mspnp/reference-architectures/blob/master/guidance-compute-multi-vm/parameters/windows/networkSecurityGroups.parameters.json
[root]:
https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-multi-vm
[root-parameters]:https://github.com/mspnp/reference-architectures/tree/master/guidance-compute-n-tier-sql/parameters
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