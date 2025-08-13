# Agent Guidelines for Windows Sandbox Project

This document outlines the conventions and practices for agents operating within this repository.

## 1. Build/Test/Verification Commands

*   **General Verification:** The primary "test" is the successful execution of the PowerShell scripts, which is verified by checking the `startup_run.log` file generated within the sandbox.
*   **Individual Script Execution:**
    *   `powershell.exe -NoProfile -ExecutionPolicy Bypass -File <script_name.ps1>`
    *   For scripts with parameters: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File <script_name.ps1> -ParameterName "Value"`

## 2. Code Style Guidelines (PowerShell)

*   **Naming Conventions:**
    *   **Variables:** Use CamelCase (e.g., `$myVariable`).
    *   **Functions:** Use PascalCase with approved PowerShell verbs (e.g., `Get-Item`, `Set-Content`, `Write-Log`).
    *   **Parameters:** Use PascalCase (e.g., `[string]$AppsJsonPath`).
*   **Formatting:**
    *   **Indentation:** Use 4 spaces for indentation.
    *   **Braces:** Place opening braces on the same line as the statement (K&R style).
*   **Error Handling:**
    *   Utilize `try-catch` blocks for robust error management, especially for file operations, network requests, and external command executions.
    *   Use `Write-Error` or `Write-Log` for reporting issues.
*   **Comments:**
    *   Use `<# ... #>` for multi-line, function-level documentation (e.g., `.SYNOPSIS`, `.DESCRIPTION`).
    *   Use `#` for single-line comments.
*   **Imports/Modules:**
    *   Load .NET assemblies using `Add-Type -AssemblyName`.
    *   Manage PowerShell modules using `Install-Module` and `Import-Module`.
*   **Types:** Explicitly declare types for function parameters (e.g., `[string]`, `[bool]`).

## 3. Cursor/Copilot Rules

*   No specific Cursor or Copilot rules are defined in this repository.
