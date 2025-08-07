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


:: --- Run the GUI selection for apps to install (if available) ---
echo Launching program selection dialog... >> "%LOG_FILE%"
powershell.exe -ExecutionPolicy Bypass -File "C:\startupscripts\select_apps.ps1" >> "%LOG_FILE%" 2>&1

:: If apps_selected.json exists, install those; otherwise fall back to default apps.json
if exist "C:\startupscripts\apps_selected.json" (
    echo Using selected apps from apps_selected.json >> "%LOG_FILE%"
    powershell.exe -ExecutionPolicy Bypass -File "C:\startupscripts\install_apps.ps1" -AppsJsonPath "C:\startupscripts\apps_selected.json" >> "%LOG_FILE%" 2>&1
) else (
    echo No selection made or selection file not found. Falling back to default apps.json >> "%LOG_FILE%"
    powershell.exe -ExecutionPolicy Bypass -File "C:\startupscripts\install_apps.ps1" -AppsJsonPath "C:\startupscripts\apps.json" >> "%LOG_FILE%" 2>&1
)


:: --- Final Message ---
echo.
echo =================================================================
echo Script execution has finished.
echo A detailed log has been saved to: %LOG_FILE%
echo =================================================================
echo.
pause
