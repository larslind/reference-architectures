Param(
  [Parameter(Mandatory=$True)]
  [string]$AdminUser,

  [Parameter(Mandatory=$True)]
  [string]$AdminPassword,

  [Parameter(Mandatory=$True)]
  [string]$NetBiosDomainName,

  [Parameter(Mandatory=$True)]
  [string]$FqDomainName,

  [Parameter(Mandatory=$True)]
  [string]$GmsaName,

  [Parameter(Mandatory=$True)]
  [string]$FederationName,

  [Parameter(Mandatory=$True, ParameterSetName="InstallAdfsFarm")]
  [string]$Description,

  [Parameter(Mandatory=$True, ParameterSetName="AddAdfsFarmNode")]
  [string]$PrimaryComputerName
)

$ErrorActionPreference = "Stop"

$secAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("$NetBiosDomainName\$AdminUser", $secAdminPassword)

$thumbprint=(Get-ChildItem -DnsName $FederationName -Path cert:\LocalMachine\My).Thumbprint

Install-WindowsFeature -IncludeManagementTools -Name ADFS-Federation
Import-Module ADFS

switch ($PsCmdlet.ParameterSetName) {
    "InstallAdfsFarm" {
        # Install a new ADFS farm
        Install-AdfsFarm -CertificateThumbprint $thumbprint -FederationServiceDisplayName $Description -FederationServiceName $FederationName -GroupServiceAccountIdentifier "$NetBiosDomainName\$GmsaName`$" -Credential $credential -OverwriteConfiguration
    }
    "AddAdfsFarmNode" {
        # Add a server to an existing ADFS farm
        Add-AdfsFarmNode -CertificateThumbprint $thumbprint -PrimaryComputerName $PrimaryComputerName -GroupServiceAccountIdentifier "$NetBiosDomainName\$GmsaName`$" -Credential $credential
    }
}

# Initialize device registration service for workplace join 
Initialize-ADDeviceRegistration -ServiceAccountName "$NetBiosDomainName\$GmsaName`$" -DeviceLocation $FqDomainName -RegistrationQuota 10 -MaximumRegistrationInactivityPeriod 90 -Credential $Credential -Force

Enable-AdfsDeviceRegistration -Credential $Credential -Force
