AGENTS: How to build, test and code in this repo

Build / run / test
- Run selection UI: powershell -ExecutionPolicy Bypass -File .\select_apps.ps1 -AppsJsonPath C:\startupscripts\apps.json
- Run installer (install all or selected): powershell -ExecutionPolicy Bypass -File .\install_apps.ps1
- Lint PowerShell: Install-Module -Name PSScriptAnalyzer; Invoke-ScriptAnalyzer -Path .\ -Recurse
- Tests (Pester): Invoke-Pester -Script .\tests\MyTest.tests.ps1 (to run a single test use -TestName 'Name')

Code style (short and actionable)
- Formatting: Use 4-space indentation, UTF8 without BOM. Keep lines <= 120 chars.
- Modules / imports: Use Add-Type for assemblies (UI) and explicit using statements for modules; avoid implicit global imports.
- Naming: Use PascalCase for functions and Cmdlet-style names (Verb-Noun), camelCase for local variables, UpperCamelCase for classes/objects.
- Types: Add parameter type hints and validate attributes where appropriate (e.g., [string], [int], ValidateSet).
- Error handling: Prefer try/catch for filesystem or network operations; write user-friendly messages and exit with non-zero codes on failure.
- Output: Use Write-Host for informational output; use Write-Error for errors. Return machine-readable artifacts (e.g., apps_selected.json) in deterministic paths.
- Imports/Paths: Resolve paths explicitly and use Join-Path / Split-Path. Do not assume working directory.
- Tests: Add Pester tests for parsing apps.json and for installer behavior (e.g., fallback when no selection).

Cursor / Copilot rules
- No .cursor or Copilot rules detected in repo; follow general project guidelines above.

Keep this file short and update as tooling or CI is added.
