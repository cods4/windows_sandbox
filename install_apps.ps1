<#
.SYNOPSIS
    A PowerShell script to automate the installation of common applications in a new
    Windows or Windows Sandbox environment using 'winget import'.

.DESCRIPTION
    This script first ensures Winget is installed, then uses 'winget import'
    to install all applications defined in the 'apps.json' file.

.NOTES
    Author: Gemini
    Version: 3.0
    Created: 2025-08-07
#>

# --- Force modern TLS for network requests. This is critical for sandbox environments. ---
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3, Tls, Tls11, Tls12'

# --- Helper Function ---
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    Write-Host $Message
    # Logging to a file is now handled by the .bat script
}

# =============================================================================
# --- 1. WINGET INSTALLER (FOR SANDBOX) ---
# =============================================================================
Write-Log "Checking for winget..."
winget --version | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Log "Winget not found. Attempting to install it using the confirmed working method..."
    
    # This block uses the user-confirmed working method for bootstrapping winget.
    $progressPreference = 'silentlyContinue'
    Write-Host "Installing WinGet PowerShell module from PSGallery..."
    Install-PackageProvider -Name NuGet -Force | Out-Null
    Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
    Write-Host "Using Repair-WinGetPackageManager cmdlet to bootstrap WinGet..."
    Import-Module -Name Microsoft.WinGet.Client
    Repair-WinGetPackageManager -AllUsers
    Write-Host "Done."

    # Verify installation
    winget --version | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Log "[SUCCESS] Winget installed and verified successfully."
    } else {
        Write-Log "[FATAL ERROR] Winget installation failed. Cannot proceed."
        Read-Host "Press Enter to exit"
        exit
    }
} else {
    Write-Log "Winget is already installed."
}

# =============================================================================
# --- 2. BEGIN APPLICATION INSTALLATIONS VIA IMPORT ---
# =============================================================================
Write-Log " "
Write-Log "====================================================="
Write-Log "Starting application installation using 'winget import'..."
Write-Log "Reading package list from 'apps.json'..."
Write-Log "====================================================="

try {
    # Using --accept-source-agreements is important for the first run.
    winget import -i C:\startupscripts\apps.json --accept-source-agreements
    
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
