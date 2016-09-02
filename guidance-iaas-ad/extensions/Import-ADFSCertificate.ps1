Param(
  [Parameter(Mandatory=$True)]
  [string]$Base64EncodedCertificate,

  [Parameter(Mandatory=$True)]
  [string]$CertificatePassword,

  [Parameter(Mandatory=$True)]
  [ValidateSet("Cer", "Pfx")]
  [string]$CertificateType,

  [switch]$InstallTrustedRoot
)

$ErrorActionPreference = "Stop"

$certificateFilename = "$PSScriptRoot\temp.$($CertificateType.ToLower())"
[System.IO.File]::WriteAllBytes($certificateFilename, [System.Convert]::FromBase64String($Base64EncodedCertificate))
$pwd = ConvertTo-SecureString -String $CertificatePassword -AsPlainText -Force

try {
    
    switch ($CertificateType) {
        "Cer" {
            Import-Certificate -FilePath $certificateFilename -CertStoreLocation "Cert:\LocalMachine\My"
        }
        "Pfx" {
            Import-PfxCertificate -FilePath $certificateFilename -CertStoreLocation "Cert:\LocalMachine\My" -Password $pwd
            if ($InstallTrustedRoot) {
                Import-PfxCertificate -FilePath $certificateFilename -CertStoreLocation "Cert:\LocalMachine\AuthRoot" -Password $pwd
            }
        }
    }
}
finally {
    Remove-Item -Path $certificateFilename
}