<# 
.SYNOPSIS Bootstrapper: pull scripts from GitHub and run the installation flow from a temporary directory
#>

$logPath = 'C:\startupscripts\startup_run.log'

function Write-Log {
  param([string]$Message)
  # Write to the console; the .wsb will capture console output to the logfile.
  Write-Host $Message
}

Write-Log "=== Bootstrap start at $(Get-Date) ==="

# Create a temporary working directory inside the sandbox VM's TEMP (not the mapped host folder)
$tmpDir = Join-Path $env:TEMP ("wsb_startupscripts_" + (Get-Random -Maximum 999999))
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
Write-Log "Using temporary working directory: $tmpDir"

$base = 'https://raw.githubusercontent.com/cods4/windows_sandbox/main'
$files = @('apps.json','select_apps.ps1','install_apps.ps1')

try {
  foreach ($f in $files) {
    $dst = Join-Path $tmpDir $f
    $url = "$base/$f"
    try {
      Write-Log "Downloading $f from $url to $dst"
      Invoke-WebRequest -Uri $url -OutFile $dst -UseBasicParsing
      Write-Log "Downloaded $f"
    } catch {
      Write-Log "[ERROR] Failed to download $f from $url : $($_.Exception.Message)"
      throw
    }
  }

  # Run the GUI to select apps (if GUI is available)
  $selectPath = Join-Path $tmpDir 'select_apps.ps1'
  if (Test-Path $selectPath) {
    try {
      Write-Log "Running select_apps.ps1"
      & $selectPath -AppsJsonPath (Join-Path $tmpDir 'apps.json')
    } catch {
      Write-Log "[ERROR] Failed to run select_apps.ps1: $($_.Exception.Message)"
      # continue to install using the full apps.json as fallback
    }
  }

  $appJson = Join-Path $tmpDir 'apps.json'
  $appsSelected = Join-Path $tmpDir 'apps_selected.json'

  if (Test-Path $appsSelected) {
    Write-Log "Running install_apps.ps1 with apps_selected.json"
    & (Join-Path $tmpDir 'install_apps.ps1') -AppsJsonPath $appsSelected
  } else {
    Write-Log "Running install_apps.ps1 with apps.json"
    & (Join-Path $tmpDir 'install_apps.ps1') -AppsJsonPath $appJson
  }

} finally {
  Write-Log "Cleaning up temporary directory: $tmpDir"
  try { Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction SilentlyContinue } catch { Write-Log "Warning: failed to remove temp dir: $($_.Exception.Message)" }
  Write-Log "=== Bootstrap finished at $(Get-Date) ==="
}
