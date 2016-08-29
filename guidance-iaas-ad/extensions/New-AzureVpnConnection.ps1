Param(
  [string]$InterfaceName = "Azure",
  [string]$GatewayIpAddress,
  [string]$VirtualNetworkAddressPrefix,
  [string]$SharedKey
)

$ErrorActionPreference = "Stop"

Add-VpnS2SInterface -Name $InterfaceName -Destination $GatewayIpAddress -Protocol IKEv2 -AuthenticationMethod PSKOnly -IPv4Subnet "$VirtualNetworkAddressPrefix`:2" -SharedSecret $SharedKey
Connect-VpnS2SInterface -Name $InterfaceName
