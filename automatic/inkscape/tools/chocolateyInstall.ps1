﻿$ErrorActionPreference = 'Stop'

$toolsPath = Split-Path -parent $MyInvocation.MyCommand.Definition

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'msi'
  url            = 'https://inkscape.org/gallery/item/37365/inkscape-1.2.2_2022-12-01_b0a8486541-x86.msi'
  checksum       = '8FE306B950D7EDC2C412FA4F110E5972CE2C839DE6CF4CA58EF88240B648737C'
  checksumType   = 'sha256'
  file64         = "$toolsPath\inkscape-1.2.2_2022-12-01_b0a8486541-x64.msi"
  softwareName   = 'InkScape*'
  silentArgs     = "/qn /norestart /l*v `"$($env:TEMP)\$($env:chocolateyPackageName).$($env:chocolateyPackageVersion).MsiInstall.log`""
  validExitCodes = @(0)
}

[array]$key = Get-UninstallRegistrykey $packageArgs['softwareName']
if ($key.Count -eq 1) {
  if ($key[0].DisplayVersion -eq '1.2.2') {
    Write-Host "Software already installed"
    return
  }
  else {
    # We need to do it this way, as PSChildName isn't available in POSHv2
    $msiId = $key[0].UninstallString -replace '^.*MsiExec\.exe\s*\/I', ''
    Uninstall-ChocolateyPackage -packageName $packageArgs['packageName'] `
      -fileType $packageArgs['fileType'] `
      -silentArgs "$msiId $($packageArgs['silentArgs'] -replace 'MsiInstall','MsiUninstall')" `
      -validExitCodes $packageArgs['validExitCodes'] `
      -file ''
  }
}
elseif ($key.Count -gt 1) {
  Write-Warning "$($key.Count) matches found!"
  Write-Warning "To prevent accidental data loss, no programs will be uninstalled."
  Write-Warning "This will most likely cause a 1603/1638 failure when installing InkScape."
  Write-Warning "Please uninstall InkScape before installing this package."
}

if ((Get-OSArchitectureWidth 32) -or ($env:chocolateyForceX86 -eq $true)) {
  Install-ChocolateyPackage @packageArgs
}
else {
  Install-ChocolateyInstallPackage @packageArgs
}

Get-ChildItem $toolsPath\*.msi | ForEach-Object { Remove-Item $_ -ea 0; if (Test-Path $_) { Set-Content "$_.ignore" } }

$packageName = $packageArgs.packageName
$installLocation = Get-AppInstallLocation $packageArgs['softwareName']
if ($installLocation) {
  Install-BinFile 'inkscape' $installLocation\bin\inkscape.exe
  Write-Host "$packageName installed to '$installLocation'"
}
else { Write-Warning "Can't find $PackageName install location" }
