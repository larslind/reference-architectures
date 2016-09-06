Param(
  [Parameter(Mandatory=$True)]
  [string]$AdminUser,

  [Parameter(Mandatory=$True)]
  [string]$AdminPassword,

  [Parameter(Mandatory=$True)]
  [string]$NetBiosDomainName,

  [Parameter(Mandatory=$True)]
  [string]$FederationName,

  [switch]$AddWebApplicationProxyApplication
)

$secAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("$NetBiosDomainName\$AdminUser", $secAdminPassword)

$thumbprint=(Get-ChildItem -DnsName $FederationName -Path cert:\LocalMachine\My).Thumbprint

# Install ADFS feature
Install-WindowsFeature -IncludeManagementTools -name Web-Application-Proxy
Import-Module WebApplicationProxy

Install-WebApplicationProxy -FederationServiceTrustCredential $credential -CertificateThumbprint $thumbprint -FederationServiceName $FederationName 

if ($AddWebApplicationProxyApplication) {
  Add-WebApplicationProxyApplication -BackendServerUrl "https://$FederationName" -ExternalCertificateThumbprint $thumbprint -ExternalUrl "https://$FederationName" -Name "Contoso App" -ExternalPreAuthentication PassThrough
}

