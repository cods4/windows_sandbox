# Get the current user's profile path (e.g., C:\Users\username)
$UserProfile = $env:USERPROFILE

# Define the output file name
$OutputFile = "My Sandbox.wsb"

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
