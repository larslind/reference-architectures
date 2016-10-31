#!/bin/bash

RESOURCE_GROUP_NAME="ra-ntier-cassandra-rg"
LOCATION="centralus"
OS_TYPE="linux"

TEMPLATE_ROOT_URI=${TEMPLATE_ROOT_URI:="https://raw.githubusercontent.com/larslind/template-building-blocks/master/"}
# Make sure we have a trailing slash
[[ "${TEMPLATE_ROOT_URI}" != */ ]] && TEMPLATE_ROOT_URI="${TEMPLATE_ROOT_URI}/"

# For validating HTTP URIs only
URI_REGEX="^((?:https?://(?:(?:[a-zA-Z0-9$.+!*(),;?&=_-]|(?:%[a-fA-F0-9]{2})){1,64}(?::(?:[a-zA-Z0-9$.+!*(),;?&=_-]|(?:%[a-fA-F0-9]{2})){1,25})?@)?)?(?:(([a-zA-Z0-9\x00A0-\xD7FF\xF900-\xFDCF\xFDF0-\xFFEF]([a-zA-Z0-9\x00A0-\xD7FF\xF900-\xFDCF\xFDF0-\xFFEF-]{0,61}[a-zA-Z0-9\x00A0-\xD7FF\xF900-\xFDCF\xFDF0-\xFFEF]){0,1}\.)+[a-zA-Z\x00A0-\xD7FF\xF900-\xFDCF\xFDF0-\xFFEF]{2,63}|((25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9])\.(25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[0-9]))))(?::\d{1,5})?)(/(?:(?:[a-zA-Z0-9\x00A0-\xD7FF\xF900-\xFDCF\xFDF0-\xFFEF;/?:@&=#~.+!*(),_-])|(?:%[a-fA-F0-9]{2}))*)?(?:\b|$)$"

validate() {
    for i in "${@:2}"; do
      if [[ "$1" == "$i" ]]
      then
        return 1 
      fi
    done
    
    return 0 
}

validateNotEmpty() {
    if [[ "$1" != "" ]]
    then
      return 1
    else
      return 0
    fi
}

showErrorAndUsage() {
  echo
  if [[ "$1" != "" ]]
  then
    echo "  error:  $1"
    echo
  fi

  echo "  usage:  $(basename ${0}) [options]"
  echo "  options:"
  echo "    -l, --location <location>"
  echo "    -s, --subscription <subscription-id>"
  echo
  exit 1
}

if [[ $# < 1 ]]
then
  showErrorAndUsage
fi

while [[ $# > 0 ]]
do
  key="$1"
  case $key in
    -s|--subscription)
      # Explicitly set the subscription to avoid confusion as to which subscription
      # is active/default
      SUBSCRIPTION_ID="$2"
      shift
      ;;
    -l|--location)
      LOCATION="$2"
      shift
      ;;
    *)
      showErrorAndUsage "Unknown option: $1"
    ;;
  esac
  shift
done

if ! [[ $SUBSCRIPTION_ID =~ ^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$  ]];
then
  showErrorAndUsage "Invalid Subscription ID"
fi

if validateNotEmpty $LOCATION;
then
  showErrorAndUsage "Location must be provided"
fi

if grep -P -v $URI_REGEX <<< $TEMPLATE_ROOT_URI > /dev/null
then
  showErrorAndUsage "Invalid value for TEMPLATE_ROOT_URI: ${TEMPLATE_ROOT_URI}"
fi

echo
echo "Using ${TEMPLATE_ROOT_URI} to locate templates"
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo
echo "Using ${SCRIPT_DIR} to locate parameters"
echo

VIRTUAL_NETWORK_TEMPLATE_URI="${TEMPLATE_ROOT_URI}templates/buildingBlocks/vnet-n-subnet/azuredeploy.json"

VIRTUAL_NETWORK_MGMT_PARAMETERS_PATH="${SCRIPT_DIR}/parameters/${OS_TYPE}/virtualNetworkManagement.parameters.json"
VIRTUAL_NETWORK_MGMT_DEPLOYMENT_NAME="ra-ntier-mgmt-vnet-deployment"

VIRTUAL_NETWORK_NODES_PARAMETERS_PATH="${SCRIPT_DIR}/parameters/${OS_TYPE}/virtualNetworkNodes.parameters.json"
VIRTUAL_NETWORK_NODES_DEPLOYMENT_NAME="ra-ntier-nodes-vnet-deployment"

AVAILABILITY_SET_TEMPLATE_URI="${TEMPLATE_ROOT_URI}templates/resources/Microsoft.Compute/virtualMachines/availabilitySet-new.json"
AVAILABILITY_SET_PARAMETERS_PATH="${SCRIPT_DIR}/parameters/${OS_TYPE}/availabilitySet.parameters.json"
AVAILABILITY_SET_DEPLOYMENT_NAME="ra-ntier-data-avset-deployment"

VIRTUAL_MACHINE_TEMPLATE_URI="${TEMPLATE_ROOT_URI}templates/buildingBlocks/multi-vm-n-nic-m-storage/azuredeploy.json"

MGMT_TIER_JUMPBOX_PARAMETERS_PATH="${SCRIPT_DIR}/parameters/${OS_TYPE}/managementTierJumpbox.parameters.json"
MGMT_TIER_JUMPBOX_DEPLOYMENT_NAME="ra-ntier-mgmt-jb-deployment"

MGMT_TIER_OPS_PARAMETERS_PATH="${SCRIPT_DIR}/parameters/${OS_TYPE}/managementTierOps.parameters.json"
MGMT_TIER_OPS_DEPLOYMENT_NAME="ra-ntier-mgmt-ops-deployment"

LOAD_BALANCER_TEMPLATE_URI="${TEMPLATE_ROOT_URI}templates/buildingBlocks/loadBalancer-backend-n-vm/azuredeploy.json"

WEB_TIER_PARAMETERS_PATH="${SCRIPT_DIR}/parameters/${OS_TYPE}/webTier.parameters.json"
WEB_TIER_DEPLOYMENT_NAME="ra-ntier-web-deployment"

BIZ_TIER_PARAMETERS_PATH="${SCRIPT_DIR}/parameters/${OS_TYPE}/businessTier.parameters.json"
BIZ_TIER_DEPLOYMENT_NAME="ra-ntier-biz-deployment"

DATA_TIER_PARAMETERS_PATH="${SCRIPT_DIR}/parameters/${OS_TYPE}/dataTier.parameters.json"
DATA_TIER_DEPLOYMENT_NAME="ra-ntier-data-deployment"

NETWORK_SECURITY_GROUP_TEMPLATE_URI="${TEMPLATE_ROOT_URI}templates/buildingBlocks/networkSecurityGroups/azuredeploy.json"
NETWORK_SECURITY_GROUP_PARAMETERS_PATH="${SCRIPT_DIR}/parameters/${OS_TYPE}/networkSecurityGroups.parameters.json"
NETWORK_SECURITY_GROUP_DEPLOYMENT_NAME="ra-ntier-nsg-deployment"

azure config mode arm

# Create the resource group, saving the output for later.
RESOURCE_GROUP_OUTPUT=$(azure group create --name $RESOURCE_GROUP_NAME --location $LOCATION --subscription $SUBSCRIPTION_ID --json) || exit 1

# Create the virtual networks
echo "Deploying virtual network for nodes..."
azure group deployment create --resource-group $RESOURCE_GROUP_NAME --name $VIRTUAL_NETWORK_NODES_DEPLOYMENT_NAME \
--template-uri $VIRTUAL_NETWORK_TEMPLATE_URI --parameters-file $VIRTUAL_NETWORK_NODES_PARAMETERS_PATH \
--subscription $SUBSCRIPTION_ID || exit 1

echo "Deploying virtual network for management..."
azure group deployment create --resource-group $RESOURCE_GROUP_NAME --name $VIRTUAL_NETWORK_MGMT_DEPLOYMENT_NAME \
--template-uri $VIRTUAL_NETWORK_TEMPLATE_URI --parameters-file $VIRTUAL_NETWORK_MGMT_PARAMETERS_PATH \
--subscription $SUBSCRIPTION_ID || exit 1

# Create availability set for Cassandra cluster
echo "Deploying availability set for data tier..."
azure group deployment create --resource-group $RESOURCE_GROUP_NAME --name $AVAILABILITY_SET_DEPLOYMENT_NAME \
--template-uri $AVAILABILITY_SET_TEMPLATE_URI --parameters-file $AVAILABILITY_SET_PARAMETERS_PATH \
--subscription $SUBSCRIPTION_ID || exit 1

echo "Deploying web tier..."
azure group deployment create --resource-group $RESOURCE_GROUP_NAME --name $WEB_TIER_DEPLOYMENT_NAME \
--template-uri $LOAD_BALANCER_TEMPLATE_URI --parameters-file $WEB_TIER_PARAMETERS_PATH \
--subscription $SUBSCRIPTION_ID || exit 1

echo "Deploying business tier..."
azure group deployment create --resource-group $RESOURCE_GROUP_NAME --name $BIZ_TIER_DEPLOYMENT_NAME \
--template-uri $LOAD_BALANCER_TEMPLATE_URI --parameters-file $BIZ_TIER_PARAMETERS_PATH \
--subscription $SUBSCRIPTION_ID || exit 1

echo "Deploying data tier..."
azure group deployment create --resource-group $RESOURCE_GROUP_NAME --name $DATA_TIER_DEPLOYMENT_NAME \
--template-uri $VIRTUAL_MACHINE_TEMPLATE_URI --parameters-file $DATA_TIER_PARAMETERS_PATH \
--subscription $SUBSCRIPTION_ID || exit 1

echo "Deploying jumpbox in management tier..."
azure group deployment create --resource-group $RESOURCE_GROUP_NAME --name $MGMT_TIER_JUMPBOX_DEPLOYMENT_NAME \
--template-uri $VIRTUAL_MACHINE_TEMPLATE_URI --parameters-file $MGMT_TIER_JUMPBOX_PARAMETERS_PATH \
--subscription $SUBSCRIPTION_ID || exit 1

echo "Deploying operations center in management tier..."
azure group deployment create --resource-group $RESOURCE_GROUP_NAME --name $MGMT_TIER_OPS_DEPLOYMENT_NAME \
--template-uri $VIRTUAL_MACHINE_TEMPLATE_URI --parameters-file $MGMT_TIER_OPS_PARAMETERS_PATH \
--subscription $SUBSCRIPTION_ID || exit 1

echo "Deploying network security group..."
azure group deployment create --resource-group $RESOURCE_GROUP_NAME --name $NETWORK_SECURITY_GROUP_DEPLOYMENT_NAME \
--template-uri $NETWORK_SECURITY_GROUP_TEMPLATE_URI --parameters-file $NETWORK_SECURITY_GROUP_PARAMETERS_PATH \
--subscription $SUBSCRIPTION_ID || exit 1

# Display json output
echo "==================================="

echo $RESOURCE_GROUP_OUTPUT

azure group deployment show --resource-group $RESOURCE_GROUP_NAME --name $VIRTUAL_NETWORK_NODES_DEPLOYMENT_NAME \
--subscription $SUBSCRIPTION_ID --json || exit 1

azure group deployment show --resource-group $RESOURCE_GROUP_NAME --name $VIRTUAL_NETWORK_MGMT_DEPLOYMENT_NAME \
--subscription $SUBSCRIPTION_ID --json || exit 1

azure group deployment show --resource-group $RESOURCE_GROUP_NAME --name $AVAILABILITY_SET_DEPLOYMENT_NAME \
--subscription $SUBSCRIPTION_ID --json || exit 1

azure group deployment show --resource-group $RESOURCE_GROUP_NAME --name $WEB_TIER_DEPLOYMENT_NAME \
--subscription $SUBSCRIPTION_ID --json || exit 1

azure group deployment show --resource-group $RESOURCE_GROUP_NAME --name $BIZ_TIER_DEPLOYMENT_NAME \
--subscription $SUBSCRIPTION_ID --json || exit 1

azure group deployment show --resource-group $RESOURCE_GROUP_NAME --name $DATA_TIER_DEPLOYMENT_NAME \
--subscription $SUBSCRIPTION_ID --json || exit 1

azure group deployment show --resource-group $RESOURCE_GROUP_NAME --name $MGMT_TIER_JUMPBOX_DEPLOYMENT_NAME \
--subscription $SUBSCRIPTION_ID --json || exit 1

azure group deployment show --resource-group $RESOURCE_GROUP_NAME --name $MGMT_TIER_OPS_DEPLOYMENT_NAME \
--subscription $SUBSCRIPTION_ID --json || exit 1

azure group deployment show --resource-group $RESOURCE_GROUP_NAME --name $NETWORK_SECURITY_GROUP_DEPLOYMENT_NAME \
--subscription $SUBSCRIPTION_ID --json || exit 1

echo "==================================="
