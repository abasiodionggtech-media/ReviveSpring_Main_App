param(
  [string]$KeyPropertiesPath = "android/key.properties"
)

$ErrorActionPreference = "Stop"

if (!(Test-Path $KeyPropertiesPath)) {
  Write-Host "Missing $KeyPropertiesPath"
  Write-Host "Copy android/key.properties.example to android/key.properties and fill in your release keystore details."
  exit 1
}

$props = @{}
Get-Content $KeyPropertiesPath | ForEach-Object {
  if ($_ -match "^\s*([^#][^=]+?)\s*=\s*(.+)\s*$") {
    $props[$matches[1].Trim()] = $matches[2].Trim()
  }
}

$storeFile = $props["storeFile"]
$alias = $props["keyAlias"]
$storePassword = $props["storePassword"]

if (!$storeFile -or !$alias -or !$storePassword) {
  Write-Host "key.properties must contain storeFile, keyAlias, and storePassword."
  exit 1
}

$resolvedStore = Resolve-Path (Join-Path "android/app" $storeFile) -ErrorAction SilentlyContinue
if (!$resolvedStore) {
  $resolvedStore = Resolve-Path $storeFile -ErrorAction SilentlyContinue
}
if (!$resolvedStore) {
  Write-Host "Could not find keystore file: $storeFile"
  exit 1
}

keytool -list -v -keystore $resolvedStore -alias $alias -storepass $storePassword | Select-String "SHA1|SHA256"
