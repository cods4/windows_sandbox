# Windows Sandbox Configurations

This repository contains a custom configuration for **Windows Sandbox**. This configuration is designed to create a sandboxed environment with specific settings and pre-mapped folders, making it easier to test applications or run scripts in a safe, isolated space.

## What is Windows Sandbox?

Windows Sandbox provides a lightweight desktop environment to safely run applications in isolation. Software installed inside the Windows Sandbox environment remains "sandboxed" and runs separately from the host machine. When Windows Sandbox is closed, all software with all its files and state are permanently deleted.

## Features

These configuration files extend the default Sandbox functionality with the following features:

  * **Virtualised GPU**: Enabled for better graphics performance.
  * **Networking**: Enabled to allow internet access from within the sandbox.
  * **Mapped Folders**:
      * Maps the host's `Downloads` folder to `C:\temp` inside the sandbox.
      * Maps a `startupscripts` folder from your user profile on the host to `C:\startupscripts` inside the sandbox.
  * **Logon Command**: Automatically runs a PowerShell bootstrap script (`bootstrap.ps1`) when the sandbox starts.
  * **bootstrap.ps1**: This downloads the rest of the scripts from this repo which offer the user a popup to select the applications they want to install, and then installs winget and the selected applications. If no response is received after 5 minutes, all applicationsa are installed.

## Prerequisites

1.  **Operating System**: Windows 10/11 **Pro** or **Enterprise**.
2.  **Windows Feature**: The **Windows Sandbox** feature must be enabled on your host machine. You can enable it via "Turn Windows features on or off".

## How to Use

1.  Clone or download the `sandbox.wsb` file from this repository to your local machine.
2.  Clone or download the `bootstrap.ps1` file from this repository and place it in %USERPROFILE%\Sandbox\startupscripts.
4.  Simply **double-click** the `.wsb` file to launch a new Windows Sandbox session with the specified configuration.
5.  A log file will be generated in %USERPROFILE%\Sandbox\startupscripts with the output from bootstrap.ps1.

## Customization

You can easily customize the `.wsb` files by opening them in a text editor.

### Folder Mapping

To change which folders are shared between your host and the sandbox, edit the `<MappedFolders>` section. The configuration uses the `%USERPROFILE%` environment variable to dynamically find the current user's home directory, making it portable across different machines.

```xml
<MappedFolders>
  <MappedFolder>
    <HostFolder>%USERPROFILE%\Downloads</HostFolder>
    <SandboxFolder>C:\temp</SandboxFolder>
    <ReadOnly>false</ReadOnly>
  </MappedFolder>
</MappedFolders>
```

-----
