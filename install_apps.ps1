<#
.SYNOPSIS
    A PowerShell script to automate the installation of common applications in a new
    Windows or Windows Sandbox environment using 'winget import'.

.DESCRIPTION
    This script accepts an optional AppsJsonPath parameter and uses winget import to
    install the packages defined in that JSON file. If no path is provided, it defaults
    to C:\startupscripts\apps.json.

.NOTES
    Author: Gemini
    Version: 3.1
    Created: 2025-08-07
#>

param(
    [string]$AppsJsonPath = 'C:\startupscripts\apps.json'
)

# --- Force modern TLS for network requests. This is critical for sandbox environments. ---
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    Write-Host $Message
    # We rely on the batch script to collect logs; this keeps output simple.
}

# Verify the Apps JSON path exists
if (-Not (Test-Path -Path $AppsJsonPath)) {
    Write-Log "[ERROR] Apps JSON not found at '$AppsJsonPath'. Exiting."
    exit 1
}

$text = Get-Content -Path $AppsJsonPath -Raw
try {
    $appsJson = $text | ConvertFrom-Json
} catch {
    Write-Log "[ERROR] Failed to parse JSON from '$AppsJsonPath'. Exiting."
    exit 1
}

$schema = $appsJson.'$schema'
$winGetVersion = $appsJson.WinGetVersion
$packages = $appsJson.Sources[0].Packages

# =============================================================================
# --- 1. WINGET INSTALLER (FOR SANDBOX) ---
# =============================================================================
Write-Log "Checking for winget..."
try {
    & winget --version > $null 2>&1
    $wingetPresent = $true
} catch {
    $wingetPresent = $false
}
if (-not $wingetPresent) {
    Write-Log "[INFO] Winget not found. Attempting to install/repair..."
    $progressPreference = 'silentlyContinue'
    Write-Host "Installing WinGet PowerShell module from PSGallery..."

    # Helper to log full exception details
    function Log-Exception($ex) {
        try { Write-Log "Exception: $([string]($ex | Out-String))" } catch { Write-Host "(failed to log exception)" }
    }

    $installed = $false
    try {
        Install-PackageProvider -Name NuGet -Force | Out-Null
        Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
        Write-Host "Using Repair-WinGetPackageManager cmdlet to bootstrap WinGet..."
        Repair-WinGetPackageManager -AllUsers
        Write-Host "Done."
        Write-Log "[SUCCESS] Winget installed/bootstrapped (AllUsers)."
        $installed = $true
    } catch {
        Write-Log "[WARN] Initial winget bootstrap (AllUsers) failed. Will try CurrentUser scope. Error: $($_.Exception.Message)"
        Log-Exception $_
    }

    if (-not $installed) {
        try {
            Write-Host "Attempting Install-Module with CurrentUser scope..."
            Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery -Scope CurrentUser -ErrorAction Stop | Out-Null
            Import-Module -Name Microsoft.WinGet.Client -ErrorAction Stop
            # Repair may still require elevation; try anyway
            Repair-WinGetPackageManager -AllUsers -ErrorAction Stop
            Write-Host "Done."
            Write-Log "[SUCCESS] Winget installed/bootstrapped (CurrentUser)."
            $installed = $true
        } catch {
            Write-Log "[FATAL] Winget installation failed in both AllUsers and CurrentUser attempts: $($_.Exception.Message)"
            Log-Exception $_
            exit 1
        }
    }

    # Verify winget is available
    try {
        & winget --version > $null 2>&1
        Write-Log "[SUCCESS] Winget appears available after bootstrap."
    } catch {
        Write-Log "[FATAL ERROR] Winget installation verification failed: $($_.Exception.Message)"
        Log-Exception $_
        exit 1
    }
} else {
    Write-Log "[INFO] Winget is already installed."
}

# =============================================================================
# --- 2. BEGIN APPLICATION INSTALLATIONS VIA IMPORT ---
# =============================================================================
Write-Log " "
Write-Log "====================================================="
Write-Log "Starting application installation using 'winget import'..."
Write-Log "Reading package list from '$AppsJsonPath'..."
Write-Log "====================================================="

try {
    # Accept source agreements and install as per the provided JSON
    winget import -i $AppsJsonPath --accept-source-agreements
    if ($LASTEXITCODE -eq 0) {
        Write-Log "[SUCCESS] All applications installed successfully."
    } else {
        Write-Log "[ERROR] 'winget import' finished with errors. Check the output above for details."
    }
} catch {
    $errorMessage = "[ERROR] An exception occurred during 'winget import': {0}" -f $_.Exception.Message
    Write-Log $errorMessage
}

# =============================================================================
# --- SCRIPT FINISHED ---
# =============================================================================
Write-Log " "
Write-Log "All selected application installations are complete."
