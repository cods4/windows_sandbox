<#
.SYNOPSIS
    A PowerShell-based GUI that lets you select which applications from apps.json to install
    in Windows Sandbox. The selected subset is written to apps_selected.json.

#>

param(
    [string]$AppsJsonPath = 'C:\startupscripts\apps.json'
)

# Load the current apps.json to build the UI options
if (-Not (Test-Path -Path $AppsJsonPath)) {
    Write-Error "Cannot locate $AppsJsonPath"
    exit 1
}
$appsJson = Get-Content -Path $AppsJsonPath -Raw | ConvertFrom-Json
$packages = $appsJson.Sources[0].Packages
$schema = if ($appsJson.'$schema') { $appsJson.'$schema' } else { '' }
$winGetVersion = $appsJson.WinGetVersion

# Build a lightweight mapping of display items to PackageIdentifier
$uiItems = @()
$packageIdentifiers = @()
foreach ($p in $packages) {
    $id = $p.PackageIdentifier
    $display = $id
    if ($p.PSObject.Properties.Name -contains 'DisplayName' -and $p.DisplayName) {
        $display = "$($p.DisplayName) ($id)"
    } else {
        $display = $id
    }
    $uiItems += [PSCustomObject]@{ Id = $id; Display = $display }
    $packageIdentifiers += $id
}

# Initialize Windows Forms UI (CheckedListBox)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Select applications to install in Sandbox'
$form.Size = New-Object System.Drawing.Size(650,450)
$form.StartPosition = 'CenterScreen'

$lbl = New-Object System.Windows.Forms.Label
$lbl.Text = 'Choose the applications to install in this sandbox:'
$lbl.AutoSize = $true
$lbl.Location = New-Object System.Drawing.Point(10,10)
$form.Controls.Add($lbl)

$checkedList = New-Object System.Windows.Forms.CheckedListBox
$checkedList.CheckOnClick = $true
$checkedList.Location = New-Object System.Drawing.Point(10,40)
$checkedList.Size = New-Object System.Drawing.Size(620,320)
$checkedList.BorderStyle = 'Fixed3D'

# Populate the list with user-friendly display strings
foreach ($item in $uiItems) {
    $checkedList.Items.Add($item.Display) | Out-Null
}
$form.Controls.Add($checkedList)

# Helper function to process current selection and write apps_selected.json
function Process-Selection {
    param(
        [bool]$AutoSelectAll = $false
    )

    if ($AutoSelectAll) {
        # Select all items in the list
        for ($i = 0; $i -lt $checkedList.Items.Count; $i++) {
            $checkedList.SetItemChecked($i, $true)
        }
        [System.Windows.Forms.MessageBox]::Show('No selection made within the timeout. Selecting all applications and proceeding.','Info',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    }

    # Build the list of selected IDs in the same order as displayed
    $selectedIds = @()
    for ($i = 0; $i -lt $checkedList.CheckedItems.Count; $i++) {
        $idx = $checkedList.CheckedIndices[$i]
        $selectedIds += $packageIdentifiers[$idx]
    }

    # Filter the original package list to those IDs
    $selectedPackages = @()
    foreach ($p in $packages) {
        if ($selectedIds -contains $p.PackageIdentifier) {
            $selectedPackages += $p
        }
    }

    if ($selectedPackages.Count -eq 0) {
        # No selection even after auto-selection - treat as cancel
        [System.Windows.Forms.MessageBox]::Show('No valid packages selected. Exiting.','Info',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        $form.Close()
        exit 1
    }

    # Build new JSON payload preserving the original schema and source details
    $newJson = @{}
    $newJson['$schema'] = $schema
    $newJson['CreationDate'] = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fff-00:00')
    $newJson['Sources'] = @()
    $srcObj = @{}
    $srcObj['Packages'] = $selectedPackages
    $srcObj['SourceDetails'] = $appsJson.Sources[0].SourceDetails
    $newJson['Sources'] += $srcObj
    $newJson['WinGetVersion'] = $winGetVersion

    # Write apps_selected.json next to the apps.json file that was provided
    $outDir = Split-Path -Parent $AppsJsonPath
    if (-Not (Test-Path -Path $outDir)) {
        try {
            New-Item -ItemType Directory -Path $outDir -Force | Out-Null
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Cannot create $outDir to write apps_selected.json. Exiting.", 'Error',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
            $form.Close()
            exit 1
        }
    }

    $outPath = Join-Path $outDir 'apps_selected.json'
    try {
        $newJson | ConvertTo-Json -Depth 99 | Out-File -FilePath $outPath -Encoding UTF8
        Write-Host "Selected apps written to $outPath"
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to write ${outPath}: $($_.Exception.Message)", 'Error',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        $form.Close()
        exit 1
    }

    # Stop timer if running and close form
    if ($timer) {
        try { $timer.Stop() } catch { }
    }

    $form.Close()
}

# Buttons
$okBtn = New-Object System.Windows.Forms.Button
$okBtn.Text = 'OK'
$okBtn.Location = New-Object System.Drawing.Point(200, 380)
$okBtn.Add_Click({ Process-Selection $false })
$form.Controls.Add($okBtn)

$cancelBtn = New-Object System.Windows.Forms.Button
$cancelBtn.Text = 'Cancel'
$cancelBtn.Location = New-Object System.Drawing.Point(320, 380)
$cancelBtn.Add_Click({ if ($timer) { try { $timer.Stop() } catch { } } $form.Close(); exit 1 })
$form.Controls.Add($cancelBtn)

# Setup a 5-minute timer to auto-select all applications if the user does nothing
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 300000 # 5 minutes in milliseconds
$timer.Add_Tick({
    # Ensure the form is still visible and not already closed
    if ($form -and $form.Visible) {
        Process-Selection $true
    }
})
$timer.Start()

$form.Add_Shown({ $form.Activate() })
$form.ShowDialog() | Out-Null

