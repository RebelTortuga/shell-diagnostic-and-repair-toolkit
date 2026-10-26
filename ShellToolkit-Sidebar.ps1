# Shell Diagnostic and Repair Toolkit | RebelTortuga | Version 1.0.0
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$state = Join-Path $env:LOCALAPPDATA 'RebelTortuga\Shell-Toolkit'
$logs = Join-Path $state 'Logs'
New-Item -ItemType Directory -Path $logs -Force | Out-Null
$script:LogFile = Join-Path $logs ('Shell-' + (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss-fff') + '.txt')
$script:Report = @()
function Log($text) { Add-Content -LiteralPath $script:LogFile -Value "[$(Get-Date -Format o)] $text" -Encoding UTF8 }
function PickBackup {
    $d = New-Object System.Windows.Forms.FolderBrowserDialog
    $d.Description = 'Choose the dated backup folder containing Backup Complete.json'
    try { if ($d.ShowDialog() -eq 'OK') { return $d.SelectedPath } } finally { $d.Dispose() }
}
function OpenGuide {
    $path = Join-Path $PSScriptRoot 'OPTIONS-README.md'
    try { Start-Process -FilePath $path } catch { Start-Process notepad.exe -ArgumentList "`"$path`"" }
}
function VerifyBackup {
    $backup = PickBackup
    if (!$backup) { Write-Output 'Verification cancelled.'; return }
    $marker = Join-Path $backup 'Backup Complete.json'
    if (!(Test-Path -LiteralPath $marker -PathType Leaf)) { throw 'No completion marker: this is not a completed backup.' }
    $meta = Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
    if ($meta.Format -ne 'ShellBackup1') { throw 'Unrecognized backup format.' }
    $rows = @(Import-Csv -LiteralPath (Join-Path $backup 'File Checksums.csv'))
    if (!$rows.Count) { throw 'Checksum list is empty.' }
    $base = [IO.Path]::GetFullPath($backup).TrimEnd('\') + '\'
    $failures = @()
    foreach ($row in $rows) {
        $path = [IO.Path]::GetFullPath((Join-Path $backup $row.File))
        if (!$path.StartsWith($base,[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe path in checksum list.' }
        if (!(Test-Path -LiteralPath $path -PathType Leaf)) { $failures += "Missing: $($row.File)"; continue }
        $f = Get-Item -LiteralPath $path
        if ($f.Length -ne [long]$row.Bytes -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $row.SHA256) { $failures += "Mismatch: $($row.File)" }
    }
    $script:Report = @('Shell Backup Verification',"Checked: $(Get-Date -Format o)","Backup: $backup","Listed files checked: $($rows.Count)") + $failures
    if ($failures.Count) { $script:Report += 'FAIL: backup files differ or are missing.'; $script:Report; throw 'Backup verification failed. Review results and keep the backup unchanged.' }
    $script:Report += 'PASS: all listed file sizes and SHA-256 hashes match. This does not prove authenticity or restore compatibility; extra files are not checked.'
    $script:Report
    Log "Verified $($rows.Count) listed files."
}
function Diagnose {
    $script:Report = @('Shell Diagnostic Report - RebelTortuga - Version 1.0.0',"Time: $(Get-Date -Format o)",'File presence and tool discovery are indicators, not a diagnosis.')
    foreach ($name in @('powershell.exe','pwsh.exe','cmd.exe','clink.exe','clink_x64.exe','oh-my-posh.exe','wt.exe','robocopy.exe','reg.exe')) {
        $tool = Get-Command $name -ErrorAction SilentlyContinue | Select-Object -First 1
        $script:Report += if ($tool) { "FOUND: $name - $($tool.Source)" } else { "INFO: $name not found on PATH; optional tools may be installed elsewhere." }
    }
    $docs = [Environment]::GetFolderPath('MyDocuments')
    foreach ($path in @((Join-Path $docs 'PowerShell'),(Join-Path $docs 'WindowsPowerShell'),(Join-Path $env:LOCALAPPDATA 'clink'),(Join-Path $env:APPDATA 'clink'),(Join-Path $env:USERPROFILE '.config\oh-my-posh'))) {
        $script:Report += "Folder exists: $(Test-Path -LiteralPath $path) - $path"
    }
    $script:Report += 'Profiles were not executed. Modules, themes, registry values and scripts were not repaired.'
    $script:Report
    Log 'Local diagnostics completed.'
}
function ExportReport {
    if (!$script:Report.Count) { throw 'Run diagnostics or verification first.' }
    $d = New-Object System.Windows.Forms.SaveFileDialog
    $d.Filter = 'Text report (*.txt)|*.txt'
    $d.FileName = 'Shell Diagnostic Report.txt'
    try { if ($d.ShowDialog() -eq 'OK') { $script:Report | Set-Content -LiteralPath $d.FileName -Encoding UTF8; Write-Output "Report saved: $($d.FileName)" } } finally { $d.Dispose() }
}
function InvokeAction([string]$id) {
    switch ($id) {
        'docs' { Start-Process explorer.exe -ArgumentList ('"' + [Environment]::GetFolderPath('MyDocuments') + '"') }
        'user' { Start-Process explorer.exe -ArgumentList "`"$env:USERPROFILE`"" }
        'logs' { Start-Process explorer.exe -ArgumentList "`"$logs`"" }
        'backup' {
            $engine = Join-Path $PSScriptRoot 'ShellBackup.ps1'
            if (!(Test-Path -LiteralPath $engine)) { throw 'ShellBackup.ps1 is missing. Extract all files together.' }
            $exe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
            $p = Start-Process $exe -ArgumentList "-NoLogo -NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$engine`"" -WindowStyle Hidden -Wait -PassThru
            if ($p.ExitCode -ne 0) { throw 'Backup failed. Review the backup dialog error.' }
            Write-Output 'Backup dialog closed. Only its completion message and Backup Complete.json establish completion; closing or cancelling does not.'
        }
        'restore' { OpenGuide; Write-Output 'Follow the Manual restore section. This version does not automatically overwrite files, import registry exports or replace PATH.' }
        'openbackup' { $path = PickBackup; if ($path) { Start-Process explorer.exe -ArgumentList "`"$path`"" } }
        'scan' { Diagnose }
        'verify' { VerifyBackup }
        'export' { ExportReport }
        'clean' { Start-Process (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') -ArgumentList '-NoLogo -NoProfile'; Write-Output 'A visible test shell opened without loading profile scripts. Close it separately when finished.' }
        'help' { OpenGuide; Write-Output 'See Repair & Troubleshoot in the guide.' }
        'feedback' { Write-Output 'RebelTortuga: use the repository Issues tab for bugs, cleanup ideas, more options and feature requests. Include Windows version, steps and exact errors. Keep backups and private paths out of public reports. No repository URL has been confirmed.' }
        'support' {
            $supportUrl = 'https://ko-fi.com/rebeltortuga'
            Write-Output "All features are free. Donations are optional: $supportUrl"
            $choice = [System.Windows.Forms.MessageBox]::Show("Help this turtle get a new shell? Opening Ko-fi is optional; no purchase is made. Open $supportUrl ?",'Optional RebelTortuga Support','YesNo','Question')
            if ($choice -eq 'Yes') { Start-Process -FilePath $supportUrl; Write-Output 'Opened Ko-fi in the default browser.' }
        }
    }
}
function RunAction([scriptblock]$work) {
    $script:Form.UseWaitCursor = $true
    $script:ActionPanel.Enabled = $false
    $script:Nav.Enabled = $false
    $script:ProfilePanel.Enabled = $false
    $script:ExitButton.Enabled = $false
    $script:Busy = $true
    try {
        $script:Results.AppendText("`r`n[$(Get-Date -Format 'HH:mm:ss')] Started.`r`n")
        $output = @(& $work 6>&1 | ForEach-Object { $_.ToString() })
        if ($output.Count) { $script:Results.AppendText(($output -join "`r`n") + "`r`n") }
        $script:Results.AppendText("Action window closed / command returned. Check the reported outcome; cancellation does not mean completion.`r`n")
    } catch {
        $script:Results.AppendText("ERROR: $($_.Exception.Message)`r`n")
        Log "Action error: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,'Shell Toolkit','OK','Error') | Out-Null
    } finally {
        $script:Form.UseWaitCursor = $false
        $script:ActionPanel.Enabled = $true
        $script:Nav.Enabled = $true
        $script:ProfilePanel.Enabled = $true
        $script:ExitButton.Enabled = $true
        $script:Busy = $false

    }
}
function ShowSection([string]$name) {
    $script:ActionPanel.Controls.Clear()
    $script:SectionTitle.Text = $name
    $items = @(switch ($name) {
        'Profile and Folders' { [pscustomobject]@{ Id='docs'; Text='Open Documents folder' }; [pscustomobject]@{ Id='user'; Text='Open user folder' }; [pscustomobject]@{ Id='logs'; Text='Saved Logs' } }
        'Backup & Restore' { [pscustomobject]@{ Id='backup'; Text='Save a backup - choose folders and files' }; [pscustomobject]@{ Id='restore'; Text='Manual restore guide' }; [pscustomobject]@{ Id='openbackup'; Text='Open an existing backup' } }
        'Diagnostics' { [pscustomobject]@{ Id='scan'; Text='Check shell tools and common folders' }; [pscustomobject]@{ Id='verify'; Text='Verify a backup' }; [pscustomobject]@{ Id='export'; Text='Export last report' } }
        'Repair & Troubleshoot' { [pscustomobject]@{ Id='clean'; Text='Open Windows PowerShell without a profile' }; [pscustomobject]@{ Id='restore'; Text='Manual restore guide' }; [pscustomobject]@{ Id='help'; Text='Shell troubleshooting guidance' } }
        'Other Tools' { [pscustomobject]@{ Id='verify'; Text='Verify a backup' }; [pscustomobject]@{ Id='feedback'; Text='Feedback and GitHub information' } }
        'Optional Support' { [pscustomobject]@{ Id='support'; Text='Optional Ko-fi support' } }
    })
    foreach ($item in $items) {
        $button = New-Object System.Windows.Forms.Button
        $button.Text = $item.Text
        $button.Tag = $item.Id
        $button.Size = New-Object System.Drawing.Size(470,42)
        $button.Margin = New-Object System.Windows.Forms.Padding(0,0,0,10)
        $button.TextAlign = 'MiddleLeft'
        $button.Add_Click({ $id = [string]$this.Tag; RunAction { InvokeAction $id } })
        $script:ActionPanel.Controls.Add($button)
    }
    foreach ($button in $script:NavButtons) {
        if ($button.Tag -eq 'Diagnostics') {
            $button.UseVisualStyleBackColor = $false
            $button.BackColor = [Drawing.Color]::ForestGreen
            $button.ForeColor = [Drawing.Color]::White
        } elseif ($button.Tag -eq 'Optional Support') {
            $button.UseVisualStyleBackColor = $false
            $button.BackColor = [Drawing.Color]::RoyalBlue
            $button.ForeColor = [Drawing.Color]::White
        } else {
            $button.BackColor = if ($button.Tag -eq $name) { [Drawing.Color]::LightSteelBlue } else { [Drawing.SystemColors]::Control }
        }
    }
}
try {
    Log 'Sidebar toolkit started.'
    $script:Form = New-Object System.Windows.Forms.Form
    $script:Form.Text = 'Shell Diagnostic and Repair Toolkit - Version 1.0.0 - RebelTortuga'
    $script:Form.Size = New-Object Drawing.Size(1050,900)
    $script:Form.MinimumSize = New-Object Drawing.Size(920,850)
    $script:Form.StartPosition = 'CenterScreen'
    $script:Form.Font = New-Object Drawing.Font('Segoe UI',10)
    $layout = New-Object System.Windows.Forms.TableLayoutPanel
    $layout.Dock = 'Fill'
    $layout.ColumnCount = 2
    $layout.RowCount = 5
    $layout.Padding = New-Object System.Windows.Forms.Padding(18)
    $null = $layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Absolute',230)))
    $null = $layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Percent',100)))
    foreach ($height in @(110,90,250)) { $null = $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Absolute',$height))) }
    $null = $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent',100)))
    $null = $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Absolute',40)))
    $script:Form.Controls.Add($layout)
    $title = New-Object System.Windows.Forms.Label
    $title.Text = 'Shell Diagnostic and Repair Toolkit' + "`r`n" + 'Version 1.0.0 | RebelTortuga | Free to use' + "`r`n`r`n" + 'Save your work and close relevant shells and editors before backing up.'
    $title.Dock = 'Fill'
    $layout.Controls.Add($title,0,0)
    $layout.SetColumnSpan($title,2)
    $script:ProfilePanel = New-Object System.Windows.Forms.Label
    $script:ProfilePanel.Dock = 'Fill'
    $script:ProfilePanel.Text = 'Current Windows user: ' + $env:USERNAME + "`r`nSources are detected when you choose Save a backup. Review the checked list and add custom folders."
    $layout.Controls.Add($script:ProfilePanel,0,1)
    $layout.SetColumnSpan($script:ProfilePanel,2)
    $script:Nav = New-Object System.Windows.Forms.TableLayoutPanel
    $script:Nav.Dock = 'Fill'
    $script:Nav.ColumnCount = 1
    $script:Nav.RowCount = 10
    foreach ($height in @(50,50,50,50,50,50)) { $null = $script:Nav.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Absolute',$height))) }
    $null = $script:Nav.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent',50)))
    $null = $script:Nav.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Absolute',50)))
    $null = $script:Nav.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent',50)))
    $null = $script:Nav.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Absolute',50)))
    $layout.Controls.Add($script:Nav,0,2)
    $layout.SetRowSpan($script:Nav,3)
    $script:NavButtons = @()
    $row = 0
    foreach ($name in @('Profile and Folders','Backup && Restore','Diagnostics','Repair && Troubleshoot','Other Tools')) {
        $button = New-Object System.Windows.Forms.Button
        $button.Text = $name
        $button.Tag = $name.Replace('&&','&')
        $button.Dock = 'Fill'
        $button.Margin = New-Object System.Windows.Forms.Padding(0,0,12,8)
        $button.Add_Click({ ShowSection $this.Tag })
        $script:Nav.Controls.Add($button,0,$row)
        $script:NavButtons += $button
        $row++
    }
    $help = New-Object System.Windows.Forms.Button
    $help.Text = 'Detailed Options Guide (H)'
    $help.UseVisualStyleBackColor = $false
    $help.BackColor = [Drawing.Color]::Khaki
    $help.ForeColor = [Drawing.Color]::Black
    $help.Dock = 'Fill'
    $help.Margin = New-Object System.Windows.Forms.Padding(0,0,12,8)
    $help.Add_Click({ RunAction { OpenGuide } })
    $script:Nav.Controls.Add($help,0,5)
    $support = New-Object System.Windows.Forms.Button
    $support.Text = 'Optional Support'
    $support.UseVisualStyleBackColor = $false
    $support.BackColor = [Drawing.Color]::RoyalBlue
    $support.ForeColor = [Drawing.Color]::White
    $support.Tag = 'Optional Support'
    $support.Dock = 'Fill'
    $support.Margin = New-Object System.Windows.Forms.Padding(0,0,12,8)
    $support.Add_Click({ ShowSection 'Optional Support' })
    $script:Nav.Controls.Add($support,0,7)
    $script:NavButtons += $support
    $script:ExitButton = New-Object System.Windows.Forms.Button
    $script:ExitButton.Text = 'Exit Toolkit'
    $script:ExitButton.Dock = 'Fill'
    $script:ExitButton.Margin = New-Object System.Windows.Forms.Padding(0,0,12,0)
    $script:ExitButton.UseVisualStyleBackColor = $false
    $script:ExitButton.BackColor = [Drawing.Color]::Firebrick
    $script:ExitButton.ForeColor = [Drawing.Color]::White
    $script:ExitButton.Font = New-Object Drawing.Font('Segoe UI',11,[Drawing.FontStyle]::Bold)
    $script:ExitButton.Add_Click({ $script:Form.Close() })
    $script:Nav.Controls.Add($script:ExitButton,0,9)
    $content = New-Object System.Windows.Forms.TableLayoutPanel
    $content.Dock = 'Fill'
    $content.RowCount = 2
    $null = $content.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Absolute',35)))
    $null = $content.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent',100)))
    $layout.Controls.Add($content,1,2)
    $script:SectionTitle = New-Object System.Windows.Forms.Label
    $script:SectionTitle.Dock = 'Fill'
    $script:SectionTitle.Font = New-Object Drawing.Font('Segoe UI',12,[Drawing.FontStyle]::Bold)
    $content.Controls.Add($script:SectionTitle,0,0)
    $script:ActionPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $script:ActionPanel.Dock = 'Fill'
    $script:ActionPanel.FlowDirection = 'TopDown'
    $script:ActionPanel.WrapContents = $false
    $script:ActionPanel.AutoScroll = $true
    $content.Controls.Add($script:ActionPanel,0,1)
    $resultsPanel = New-Object System.Windows.Forms.TableLayoutPanel
    $resultsPanel.Dock = 'Fill'
    $resultsPanel.RowCount = 2
    $null = $resultsPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Absolute',30)))
    $null = $resultsPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent',100)))
    $resultsCaption = New-Object System.Windows.Forms.Label
    $resultsCaption.Text = 'Results and messages appear here'
    $resultsCaption.Dock = 'Fill'
    $resultsPanel.Controls.Add($resultsCaption,0,0)
    $script:Results = New-Object System.Windows.Forms.TextBox
    $script:Results.Multiline = $true
    $script:Results.ReadOnly = $true
    $script:Results.ScrollBars = 'Vertical'
    $script:Results.Dock = 'Fill'
    $script:Results.Font = New-Object Drawing.Font('Consolas',10)
    $script:Results.Text = ''
    $resultsPanel.Controls.Add($script:Results,0,1)
    $layout.Controls.Add($resultsPanel,1,3)
    $logCaption = New-Object System.Windows.Forms.Label
    $logCaption.Text = "Saved Log Path: $script:LogFile"
    $logCaption.Dock = 'Fill'
    $logCaption.AutoEllipsis = $true
    $layout.Controls.Add($logCaption,1,4)
    $script:Form.KeyPreview = $true
    $script:Form.Add_KeyDown({ if (!$script:Busy -and $_.KeyCode -eq 'H' -and !($_.Control -or $_.Alt)) { RunAction { OpenGuide }; $_.Handled = $true } })
    $script:Form.Add_FormClosing({ if ($script:Busy) { $_.Cancel = $true } })
    $script:Form.Add_FormClosed({ Log 'Toolkit exited.' })
    ShowSection 'Profile and Folders'
    [void]$script:Form.ShowDialog()
    $script:Form.Dispose()
} catch {
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,'Shell Toolkit - Startup Failed','OK','Error') | Out-Null
    exit 1
}
