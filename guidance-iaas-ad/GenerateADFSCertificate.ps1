$subjectName = "adfs.contoso.com"
$pwd = ConvertTo-SecureString -String "AweS0meC3rt@PW" -Force -AsPlainText
$cert = New-SelfSignedCertificate -CertStoreLocation "Cert:\LocalMachine\My" -Subject "CN=$subjectName" -KeyAlgorithm RSA -KeyLength 2048 -KeyExportPolicy Exportable -HashAlgorithm SHA256 -KeySpec KeyExchange -Provider "Microsoft Strong Cryptographic Provider"
try {
    $cerFilename = [System.IO.Path]::Combine($PSScriptRoot, "$subjectName.cer")
    $pfxFilename = [System.IO.Path]::Combine($PSScriptRoot, "$subjectName.pfx")
    $certPath = "Cert:\LocalMachine\My\$($cert.Thumbprint)"

    Export-Certificate -Cert $certPath -FilePath $cerFilename
    Export-PfxCertificate -Cert $certPath -FilePath $pfxFilename -Password $pwd
}
finally {
    # Remove the certificate from the local store since we have the files now.
    Remove-Item -Path "Cert:\LocalMachine\My\$($cert.Thumbprint)"
}

$encodedCertBytes = [System.Convert]::ToBase64String([byte[]]$(Get-Content -Path $pfxFilename -Encoding byte));
#[pscustomobject]@{bytes=$encodedCertBytes} | Format-Table -Wrap -Property @{Expression={$_.bytes};Label="Pfx Encoded Bytes"}

Out-File -FilePath "$pfxFilename.txt" -InputObject $encodedCertBytes -NoNewline

#Write-Host "Pfx Encoded Bytes"
#Write-Host "-----------------"
#Write-Host $encodedCertBytes

$encodedCertBytes = [System.Convert]::ToBase64String([byte[]]$(Get-Content -Path $cerFilename -Encoding byte));

Out-File -FilePath "$cerFilename.txt" -InputObject $encodedCertBytes -NoNewline

#Write-Host "Cer Encoded Bytes"
#Write-Host "-----------------"
#Write-Host $encodedCertBytes

#[pscustomobject]@{bytes=$encodedCertBytes} | Format-Table -Wrap -Property @{Expression={$_.bytes};Label="Cer Encoded Bytes"}

#[System.IO.File]::WriteAllBytes("$PSScriptRoot\adfs.pfx", [System.Convert]::FromBase64String($encodedCertBytes))
#$pwd = ConvertTo-SecureString -String "AweS0meC3rt@PW" -AsPlainText -Force
#Import-PfxCertificate -FilePath "$PSScriptRoot\adfs.pfx" -CertStoreLocation "Cert:\LocalMachine\My" -Password $pwd