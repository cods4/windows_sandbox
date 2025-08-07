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


:: --- Run the PowerShell script and redirect all output ---
echo The script is running. Please see the log file for detailed progress:
echo %LOG_FILE%
echo.

:: This command runs the PowerShell script. 
:: '>>' appends the standard output to the log file.
:: '2>&1' redirects the standard error to the same place as the standard output (the log file).
powershell.exe -ExecutionPolicy Bypass -File "C:\startupscripts\install_apps.ps1" >> "%LOG_FILE%" 2>&1


:: --- Final Message ---
echo.
echo =================================================================
echo Script execution has finished.
echo A detailed log has been saved to: %LOG_FILE%
echo =================================================================
echo.
pause
