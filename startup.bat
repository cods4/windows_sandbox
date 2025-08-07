@echo off
:: This batch file launches the PowerShell installer and captures ALL output to a log file.

:: Define the log file location
set "LOG_FILE=%TEMP%\FullInstallerLog.txt"

:: Clear the log from the previous run
if exist "%LOG_FILE%" del "%LOG_FILE%"

:: --- Start the Logging ---
echo Starting PowerShell installer script at %TIME% on %DATE% > "%LOG_FILE%"
echo. >> "%LOG_FILE%"
echo ================================================================= >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

:: Pull latest scripts from GitHub (basic, logging only)
:: Use the public raw base of the actual repository
set "GITHUB_RAW_BASE=https://raw.githubusercontent.com/cods4/windows_sandbox/main"
set "SCRIPTS_DIR=C:\startupscripts"
if not exist "%SCRIPTS_DIR%" mkdir "%SCRIPTS_DIR%"

set "DOWNLOAD_FAILED=0"

echo Pulling latest scripts from GitHub... >> "%LOG_FILE%"
setlocal EnableDelayedExpansion
for %%F in (apps.json select_apps.ps1 install_apps.ps1) do (
    set "SRC=!GITHUB_RAW_BASE!/%%F"
    set "DST=!SCRIPTS_DIR!\\%%F"
    echo [GitHub] Downloading %%F from !SRC! to !DST! >> "%LOG_FILE%"
    powershell -ExecutionPolicy Bypass -NoProfile -Command "try {Invoke-WebRequest -Uri '!SRC!' -OutFile '!DST!' -UseBasicParsing; if (-Not (Test-Path -Path '!DST!')) {Exit 1}} catch {Exit 1}" >> "%LOG_FILE%" 2>&1
    if not exist "!DST!" (
        echo [ERROR] Failed to download %%F. Please check internet connection or repository access. >> "%LOG_FILE%"
        set "DOWNLOAD_FAILED=1"
    )
)
endlocal

:CHECK_FILES
:: Validate downloaded files exist
if not exist "%SCRIPTS_DIR%\\select_apps.ps1" (
    echo [ERROR] select_apps.ps1 not found after GitHub pull. See log for details. >> "%LOG_FILE%"
    set "DOWNLOAD_FAILED=1"
)
if not exist "%SCRIPTS_DIR%\\install_apps.ps1" (
    echo [ERROR] install_apps.ps1 not found after GitHub pull. See log for details. >> "%LOG_FILE%"
    set "DOWNLOAD_FAILED=1"
)
if not exist "%SCRIPTS_DIR%\\apps.json" (
    echo [ERROR] apps.json not found after GitHub pull. See log for details. >> "%LOG_FILE%"
    set "DOWNLOAD_FAILED=1"
)

if %DOWNLOAD_FAILED% == 1 (
    echo [FATAL] Failed to fetch required startup scripts from GitHub. >> "%LOG_FILE%"
    echo Please check your internet connection and that the GitHub repository is publicly accessible. >> "%LOG_FILE%"
    echo Exiting. >> "%LOG_FILE%"
    echo. 
    echo ERROR: Could not pull necessary startup scripts from GitHub. Please check internet connectivity and repo accessibility.
    echo See log at %LOG_FILE% for details.
    pause
    goto :EOF
)

:: --- Run the GUI selection for apps to install (if available) ---
echo Launching program selection dialog... >> "%LOG_FILE%"
powershell.exe -ExecutionPolicy Bypass -File "%SCRIPTS_DIR%\select_apps.ps1" >> "%LOG_FILE%" 2>&1

:: If apps_selected.json exists, install those; otherwise fall back to default apps.json
if exist "C:\startupscripts\apps_selected.json" (
    echo Using selected apps from apps_selected.json >> "%LOG_FILE%"
    powershell.exe -ExecutionPolicy Bypass -File "%SCRIPTS_DIR%\install_apps.ps1" -AppsJsonPath "C:\startupscripts\apps_selected.json" >> "%LOG_FILE%" 2>&1
) else (
    echo No selection made or selection file not found. Falling back to default apps.json >> "%LOG_FILE%"
    powershell.exe -ExecutionPolicy Bypass -File "%SCRIPTS_DIR%\install_apps.ps1" -AppsJsonPath "C:\startupscripts\apps.json" >> "%LOG_FILE%" 2>&1
)


:: --- Final Message ---
echo.
echo =================================================================
echo Script execution has finished.
echo A detailed log has been saved to: %LOG_FILE%
echo =================================================================
echo.
pause
