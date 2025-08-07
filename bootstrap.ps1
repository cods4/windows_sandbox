<# 
.SYNOPSIS Bootstrapper: pull scripts from GitHub and run the installation flow
#>

$logPath = 'C:\startupscripts\startup_run.log'
# Ensure log directory exists
$logDir = [IO.Path]::GetDirectoryName($logPath)
if(-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

function Write-Log {
  param([string]$Message)
  Write-Host $Message
  Add-Content -Path $logPath -Value $Message
}

Write-Log "=== Bootstrap start at $(Get-Date) ==="

$scriptDir = 'C:\startupscripts'
if (-not (Test-Path $scriptDir)) { New-Item -ItemType Directory -Path $scriptDir | Out-Null }

$base = 'https://raw.githubusercontent.com/cods4/windows_sandbox/main'
$files = @('apps.json','select_apps.ps1','install_apps.ps1')

foreach ($f in $files) {
  $dst = Join-Path $scriptDir $f
  if (-not (Test-Path $dst)) {
    $url = "$base/$f"
    try {
      Write-Log "Downloading $f from $url to $dst"
      Invoke-WebRequest -Uri $url -OutFile $dst -UseBasicParsing
      Write-Log "Downloaded $f"
    } catch {
      Write-Log "[ERROR] Failed to download $f from $url"
      exit 1
    }
  } else {
    Write-Log "$f already present; skipping download"
  }
}

# Run the GUI to select apps (if GUI is available)
$selectPath = Join-Path $scriptDir 'select_apps.ps1'
if (Test-Path $selectPath) {
  try {
    Write-Log "Running select_apps.ps1"
    & $selectPath
  } catch {
    Write-Log "[ERROR] Failed to run select_apps.ps1"
  }
}

$appJson = Join-Path $scriptDir 'apps.json'
$appsSelected = Join-Path $scriptDir 'apps_selected.json'

if (Test-Path $appsSelected) {
  Write-Log "Running install_apps.ps1 with apps_selected.json"
  & (Join-Path $scriptDir 'install_apps.ps1') -AppsJsonPath $appsSelected
} else {
  Write-Log "Running install_apps.ps1 with apps.json"
  & (Join-Path $scriptDir 'install_apps.ps1') -AppsJsonPath $appJson
}

Write-Log "=== Bootstrap finished at $(Get-Date) ==="
