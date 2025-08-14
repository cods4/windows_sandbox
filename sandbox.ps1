# Get the current user's profile path (e.g., C:\Users\username)
$UserProfile = $env:USERPROFILE

# Define the output file name
$OutputFile = "sandbox.wsb"

# --- Tailscale Key Handling (Host Side) ---
$tailscaleKey = Read-Host -Prompt "Enter Tailscale authentication key (leave blank to skip Tailscale setup)"
$startupscriptsHostPath = Join-Path $UserProfile "Sandbox\startupscripts"
$tailscaleKeyFilePath = Join-Path $startupscriptsHostPath "tailscale_key.txt"

if (-not [string]::IsNullOrEmpty($tailscaleKey)) {
    # Ensure the startupscripts directory exists on the host
    if (-not (Test-Path $startupscriptsHostPath)) {
        New-Item -ItemType Directory -Path $startupscriptsHostPath -Force | Out-Null
    }
    Set-Content -Path $tailscaleKeyFilePath -Value $tailscaleKey
    Write-Host "Tailscale key saved to '$tailscaleKeyFilePath'"
} else {
    Write-Host "No Tailscale key entered. Tailscale setup will be skipped."
    # Ensure the file is removed if it exists from a previous run and no key is provided
    if (Test-Path $tailscaleKeyFilePath) {
        Remove-Item -Path $tailscaleKeyFilePath -Force | Out-Null
    }
}



# Define the XML configuration using a placeholder for the user path
# A here-string (@"..."@) makes it easy to write multi-line text
$WsbTemplate = @"
<Configuration>
    <VGpu>Enable</VGpu>
    <Networking>Enable</Networking>
    <AudioInput>Enable</AudioInput>
    <ProtectedClient>Disable</ProtectedClient>
    <PrinterRedirection>Enabled</PrinterRedirection>
    <ClipboardRedirection>Enabled</ClipboardRedirection>
    <MemoryInMB>4096</MemoryInMB>
    <MappedFolders>
        <MappedFolder>
            <HostFolder>__USERPROFILE__\Downloads</HostFolder>
            <SandboxFolder>C:\temp</SandboxFolder>
            <ReadOnly>false</ReadOnly>
        </MappedFolder>
        <MappedFolder>
            <HostFolder>__USERPROFILE__\Sandbox\startupscripts</HostFolder>
            <SandboxFolder>C:\startupscripts</SandboxFolder>
            <ReadOnly>false</ReadOnly>
        </MappedFolder>
    </MappedFolders>
    <LogonCommand>
        <Command>cmd.exe /c "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\startupscripts\bootstrap.ps1 > C:\startupscripts\startup_run.log 2&gt;&amp;1"</Command>
    </LogonCommand>
</Configuration>
"@

# Replace the placeholder with the actual user profile path
$WsbContent = $WsbTemplate.Replace('__USERPROFILE__', $UserProfile)

# Save the final content to the .wsb file
Set-Content -Path $OutputFile -Value $WsbContent

Write-Host "Successfully created '$OutputFile' for user $UserProfile"
