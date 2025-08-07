<# 
.SYNOPSIS Bootstrapper: pull scripts from GitHub and run the installation flow
#>

$scriptDir = 'C:\startupscripts'
if (-not (Test-Path $scriptDir)) { New-Item -ItemType Directory -Path $scriptDir | Out-Null }

$base = 'https://raw.githubusercontent.com/cods4/windows_sandbox/main'
$files = @('apps.json','select_apps.ps1','install_apps.ps1')

foreach ($f in $files) {
  $dst = Join-Path $scriptDir $f
  if (-not (Test-Path $dst)) {
    $url = "$base/$f"
    try {
      Write-Host "Downloading $f from $url to $dst"
      Invoke-WebRequest -Uri $url -OutFile $dst -UseBasicParsing
    } catch {
      Write-Host "[ERROR] Failed to download $f from $url"
      exit 1
    }
  }
}

# Run the GUI to select apps (if GUI is available)
$selectPath = Join-Path $scriptDir 'select_apps.ps1'
if (Test-Path $selectPath) {
  try {
    & $selectPath
  } catch {
    Write-Host "[ERROR] Failed to run select_apps.ps1"
  }
}

$appJson = Join-Path $scriptDir 'apps.json'
$appsSelected = Join-Path $scriptDir 'apps_selected.json'

if (Test-Path $appsSelected) {
  & (Join-Path $scriptDir 'install_apps.ps1') -AppsJsonPath $appsSelected
} else {
  & (Join-Path $scriptDir 'install_apps.ps1') -AppsJsonPath $appJson
}

Write-Host "Bootstrap finished"
