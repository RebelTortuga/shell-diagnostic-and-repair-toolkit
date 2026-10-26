# Shell Diagnostic and Repair Toolkit | RebelTortuga | Version 1.0.0
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
$script:items = New-Object System.Collections.ArrayList
function AddItem($label,$path) {
    if (!$path -or !(Test-Path -LiteralPath $path)) { return }
    $full = [IO.Path]::GetFullPath($path)
    if (@($script:items | Where-Object { $_.Path -eq $full }).Count -eq 0) {
        [void]$script:items.Add([pscustomobject]@{Label=$label;Path=$full})
    }
}
function PickFolder($title) {
    $d=New-Object System.Windows.Forms.FolderBrowserDialog
    $d.Description=$title
    if ($d.ShowDialog() -eq 'OK') { return $d.SelectedPath }
    return $null
}
$docs=[Environment]::GetFolderPath('MyDocuments')
foreach ($base in @($docs,(Join-Path $env:USERPROFILE 'Documents')) | Select-Object -Unique) {
    AddItem 'PowerShell profiles, modules and scripts' (Join-Path $base 'PowerShell')
    AddItem 'Windows PowerShell profiles, modules and scripts' (Join-Path $base 'WindowsPowerShell')
}
foreach ($p in @((Join-Path $env:USERPROFILE '.config\powershell'), (Join-Path $env:APPDATA 'Microsoft\PowerShell'))) { AddItem 'PowerShell configuration' $p }
foreach ($p in @((Join-Path $env:LOCALAPPDATA 'clink'),(Join-Path $env:APPDATA 'clink'),$env:CLINK_PROFILE,$env:CLINK_PATH)) {
    if ($p) { foreach ($part in ($p -split ';')) { AddItem 'Clink configuration and scripts' $part } }
}
$clink=Get-Command clink.exe,clink_x64.exe,clink.bat -ErrorAction SilentlyContinue | Select-Object -First 1
if ($clink) {
    $clinkRoot=Split-Path $clink.Source -Parent
    AddItem 'Clink installation (including bundled Lua scripts)' $clinkRoot
}
foreach ($p in @((Join-Path $env:USERPROFILE '.config\oh-my-posh'),(Join-Path $env:USERPROFILE '.poshthemes'),(Join-Path $env:LOCALAPPDATA 'Programs\oh-my-posh'),$env:POSH_THEMES_PATH)) { AddItem 'Oh My Posh themes and configuration' $p }
foreach ($f in (Get-ChildItem -LiteralPath $env:USERPROFILE -File -Filter '*.omp.*' -ErrorAction SilentlyContinue)) { AddItem 'Oh My Posh custom theme' $f.FullName }
foreach ($root in @($env:USERPROFILE,$docs) | Select-Object -Unique) {
    foreach ($name in @('Scripts','PowerShell Projects','Projects','CMD','Clink')) { AddItem 'Projects or shell scripts' (Join-Path $root $name) }
}
# Locate local Oh My Posh theme paths explicitly referenced by profile scripts.
foreach ($item in @($script:items)) {
    if ($item.Label -like '*PowerShell*') {
        $profiles=Get-ChildItem -LiteralPath $item.Path -File -Filter '*profile*.ps1' -ErrorAction SilentlyContinue
        foreach ($file in $profiles) {
            $body=[string](Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue)
            if ([string]::IsNullOrWhiteSpace($body)) { continue }
            foreach ($m in [regex]::Matches($body, '--config\s+["'']([^"'']+)["'']')) {
                $theme=$m.Groups[1].Value
                $theme=$theme.Replace('$HOME',$env:USERPROFILE).Replace('$env:USERPROFILE',$env:USERPROFILE)
                foreach ($envMatch in [regex]::Matches($theme,'\$env:([A-Za-z_][A-Za-z0-9_]*)')) {
                    $value=[Environment]::GetEnvironmentVariable($envMatch.Groups[1].Value)
                    if ($value) { $theme=$theme.Replace($envMatch.Value,$value) }
                }
                $theme=[Environment]::ExpandEnvironmentVariables($theme)
                if ($theme.StartsWith('~\') -or $theme.StartsWith('~/')) { $theme=Join-Path $env:USERPROFILE $theme.Substring(2) }
                AddItem 'Oh My Posh theme referenced in profile' $theme
            }
        }
    }
}
$packages=Join-Path $env:LOCALAPPDATA 'Packages'
if (Test-Path -LiteralPath $packages) {
    foreach ($dir in (Get-ChildItem -LiteralPath $packages -Directory -Filter 'Microsoft.WindowsTerminal*')) { AddItem 'Windows Terminal settings' (Join-Path $dir.FullName 'LocalState') }
}
AddItem 'Windows Terminal unpackaged settings' (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal')
$form=New-Object System.Windows.Forms.Form
$form.Text='Shell Backup - RebelTortuga - Version 1.0.0'
$form.Size=New-Object System.Drawing.Size(880,530)
$form.StartPosition='CenterScreen'
$label=New-Object System.Windows.Forms.Label
$label.Text='Select folders/files to save. Add any project, CMD, portable Clink or custom theme folders not listed.'
$label.SetBounds(15,15,830,35)
$list=New-Object System.Windows.Forms.CheckedListBox
$list.SetBounds(15,55,830,350)
$list.CheckOnClick=$true
$list.HorizontalScrollbar=$true
function RefreshList {
    $list.Items.Clear()
    foreach ($item in $script:items) { [void]$list.Items.Add("$($item.Label): $($item.Path)",$true) }
}
RefreshList
$add=New-Object System.Windows.Forms.Button
$add.Text='Add Folder'
$add.SetBounds(15,420,130,35)
$add.Add_Click({$p=PickFolder 'Choose a project or script folder to include'; if ($p) { AddItem 'Selected project/scripts' $p; $item=$script:items[$script:items.Count-1]; if (!$list.Items.Contains("$($item.Label): $($item.Path)")) { [void]$list.Items.Add("$($item.Label): $($item.Path)",$true) } }})
$run=New-Object System.Windows.Forms.Button
$run.Text='Save Backup'
$run.SetBounds(690,420,155,35)
$run.DialogResult='OK'
$form.Controls.AddRange(@($label,$list,$add,$run))
try {
    if ($form.ShowDialog() -ne 'OK') { exit }
    $chosen=@(foreach ($i in $list.CheckedIndices) { $script:items[$i] })
    if (!$chosen.Count) { throw 'Select at least one source to back up.' }
    $parent=PickFolder 'Choose the backup destination (external disk recommended)'
    if (!$parent) { exit }
    $parentFull=[IO.Path]::GetFullPath($parent).TrimEnd('\')
    foreach ($item in $chosen) {
        if (Test-Path -LiteralPath $item.Path -PathType Container) {
            $src=$item.Path.TrimEnd('\')
            if ($parentFull -eq $src -or $parentFull.StartsWith($src+'\',[StringComparison]::OrdinalIgnoreCase)) { throw "Backup destination cannot be inside a selected source: $src" }
        }
    }
    $backup=Join-Path $parent ('Shell Backup '+(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss-fff'))
    New-Item -ItemType Directory -Path $backup | Out-Null
    $log=Join-Path $backup 'Copy Log.txt'
    $mapping=New-Object System.Collections.ArrayList
    $n=0
    foreach ($item in $chosen) {
        $n++
        $relative='Files\'+$n.ToString('000')+'\'+(Split-Path $item.Path -Leaf)
        $dest=Join-Path $backup $relative
        if (Test-Path -LiteralPath $item.Path -PathType Container) {
            & robocopy.exe $item.Path $dest /E /XJ /R:1 /W:1 /COPY:DAT /DCOPY:DAT /NP "/LOG+:$log" | Out-Null
            if ($LASTEXITCODE -ge 8) { throw "Copy failed for $($item.Path). See $log. No completion marker was created." }
        } else {
            New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
            Copy-Item -LiteralPath $item.Path -Destination $dest
            Add-Content -LiteralPath $log -Value "Copied file: $($item.Path)" -Encoding UTF8
        }
        [void]$mapping.Add([pscustomobject]@{Label=$item.Label;OriginalPath=$item.Path;BackupPath=$relative})
    }
    $mapping.ToArray() | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $backup 'Restore Map.json') -Encoding UTF8
    $settings=Join-Path $backup 'Windows Settings'
    New-Item -ItemType Directory -Path $settings | Out-Null
    foreach ($entry in @(@('HKCU\Software\Microsoft\Command Processor','CMD Settings.reg'),@('HKCU\Console','Console Settings.reg'),@('HKCU\Software\Clink','Clink Settings.reg'))) {
        $psKey=$entry[0].Replace('HKCU\','HKCU:\')
        if (Test-Path $psKey) {
            & reg.exe export $entry[0] (Join-Path $settings $entry[1]) /y | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "Could not export $($entry[0])." }
        }
    }
    $envSettings=@{}
    foreach ($name in @('Path','POSH_THEMES_PATH','POSH_THEME','CLINK_PATH','CLINK_PROFILE','PSModulePath')) {
        $envSettings[$name]=[Environment]::GetEnvironmentVariable($name,'User')
    }
    $envSettings | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $settings 'User Shell Environment.json') -Encoding UTF8
    @('Shell Backup','Created: '+(Get-Date).ToString('o'),'','Copied sources:') + @($mapping | ForEach-Object { $_.OriginalPath+' -> '+$_.BackupPath }) | Set-Content -LiteralPath (Join-Path $backup 'Backup Summary.txt') -Encoding UTF8
    $checksumInputs = @(Get-ChildItem -LiteralPath $backup -File -Recurse | Where-Object { $_.Name -notin @('File Checksums.csv', 'Backup Complete.json') })
    $checksumRows = @($checksumInputs | ForEach-Object {
        [pscustomobject]@{File=$_.FullName.Substring($backup.Length+1);Bytes=$_.Length;SHA256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
    })
    $checksumRows | Export-Csv -LiteralPath (Join-Path $backup 'File Checksums.csv') -NoTypeInformation -Encoding UTF8
    @{Format='ShellBackup1';Created=(Get-Date).ToString('o');Sources=$mapping.Count} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $backup 'Backup Complete.json') -Encoding UTF8
    [System.Windows.Forms.MessageBox]::Show("Backup completed: $($mapping.Count) selected sources, plus user shell/console settings.`n`n$backup",'Shell Backup') | Out-Null
} catch {
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,'Shell Backup - Failed','OK','Error') | Out-Null
    exit 1
}
