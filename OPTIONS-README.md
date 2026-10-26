# Shell Diagnostic and Repair Toolkit
## Detailed Options Guide

### Version

1.0.0 · **Developer:** RebelTortuga

### Platform
Windows 10 / Windows 11

| Section | Actions |
| --- | --- |
| Profile and Folders | Open Documents; open user folder; saved logs |
| Backup & Restore | Save a backup; manual restore guide; open existing backup |
| Diagnostics — green | Check shell tools and common folders; verify a backup; export last report |
| Repair & Troubleshoot | Open Windows PowerShell without a profile; manual restore guide; troubleshooting guidance |
| Other Tools | Verify a backup; feedback and GitHub information |
| Detailed Options Guide (H) | Yellow; opens OPTIONS-README.md |
| Optional Support | Blue; optional Ko-fi support with confirmation |
| Exit Toolkit | Red with white text; closes the toolkit |

## 1. Profile and Folders

| Action | What It Opens |
| --- | --- |
| **Open Documents** | Windows' configured Documents location, including redirection |
| **Open user folder** | The current user's home folder |
| **Saved Logs** | This toolkit's session-log folder |

 Sources are detected anew in the backup dialog; this toolkit does not select browser profiles.

## 2. Backup & Restore

### Save a backup

1. Review every checked source and uncheck unwanted folders.
2. Use **Add Folder** for an additional folder. Individual files such as detected themes may already appear in the list; include custom standalone files by selecting their parent folder.
3. Select at least one source.
4. Save your work and close relevant editors and shells.
5. Choose an external destination outside all selected source folders.

A new dated folder is created for each backup.

Robocopy copies directory contents with junction exclusion and one retry. Exit codes of 8 or higher are
treated as copy failures. The completion marker is written after copies, settings exports and checksum
generation succeed. On failure, retain the partial folder only for investigation; do not treat it as complete.

### Open an existing backup
choose the dated folder to inspect it in Explorer. This action does not verify it.

### Manual Restore

1. Verify the backup first. Preserve a separate copy of your current files.
2. Reinstall needed shell programs, modules or fonts separately. Close relevant shells and editors.
3. Open `Restore Map.json`. For each entry, locate `BackupPath` beneath the backup folder and review `OriginalPath`. Adjust usernames, drive letters and moved project locations for the target computer.
4. Copy each backed-up file or folder to the reviewed target. Review overwrite prompts. Folder copies overlay existing contents; extra target files remain.
5. Review files under **Windows Settings**. Registry exports can include executable CMD AutoRun commands. Import only exports you understand and intend to apply to the current user. Preserve current registry settings first.
6. Review `User Shell Environment.json`. Apply only the needed values through Windows Environment Variables. Merge required `PATH` entries with the current `PATH`; do not blindly replace `PATH` or `PSModulePath`, especially on another computer.
7. Reopen the relevant shells and Windows Terminal and check profiles, prompts, themes and projects. Keep recovery copies until the result is confirmed.

The toolkit performs no automatic restore, registry import or environment replacement.

## 3. Diagnostics

### Check shell tools and common folders
checks command discovery for Windows PowerShell, PowerShell 7, CMD, Clink, Oh My Posh, Windows Terminal,
Robocopy and reg.exe, plus several common configuration folders. Missing optional tools are informational.
Installation outside `PATH` may be missed. It does not execute profiles, validate Lua or PowerShell syntax,
inspect project dependencies or prove settings are correct.

### Verify a backup
select the folder containing `Backup Complete.json`. Checks recognized format and each `File Checksums.csv`
entry for presence, length and SHA-256 match. Paths escaping the backup root are rejected. Missing or
mismatched files fail. Extra files are not checked, and the checksum list is not digitally signed.
Verification cannot establish authenticity or that every desired source was included.

### Export last report
saves the most recent diagnostic or verification report to a chosen text file. Run a scan or verification
first. Review identifying paths before sharing.

## 4. Repair & Troubleshoot

### Open Windows PowerShell without a profile
opens a visible Windows PowerShell test window with `-NoProfile`. Compare its behavior with a normal shell to
help isolate profile-related problems. This does not test PowerShell 7 or CMD configuration and changes no
profile files. Close the test shell separately.

### Manual restore guide
opens this document at the default location; follow the Manual restore section.

### Shell troubleshooting guidance
opens this guide. If a clean shell works, back up profile files and review recent profile/theme/module
changes. Test changes individually and retain recovery copies. If a tool is not discovered, inspect its
installation location and `PATH` before reinstalling. Avoid executing downloaded scripts or importing registry
files without review.

## 5. Other Tools
Backup verification is the same action as in Diagnostics. Feedback and GitHub information prints the author
and instructions for bug reports, cleanup ideas and requests for more options. No guessed repository link is
embedded.

## 6. Detailed Options Guide (H)
The yellow button or H shortcut opens this document. If no Markdown app is registered, the toolkit tries
Notepad.

## 7. Optional Support
opens. The toolkit is free and tips do not unlock features.

## 8. Exit Toolkit
Red button with white text. Closes the main toolkit after operations return. It is disabled during work. Do
not force-close PowerShell during a copy. The separate clean-shell troubleshooting window must be closed
separately.

## Optional Ko-fi support

Optional Support asks before opening [https://ko-fi.com/rebeltortuga](https://ko-fi.com/rebeltortuga) in your browser. All features remain free, and no payment information is collected by the toolkit.
