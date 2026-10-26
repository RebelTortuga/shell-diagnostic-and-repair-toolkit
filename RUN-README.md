# Shell Diagnostic and Repair Toolkit
## Running the Toolkit

**Developer:** RebelTortuga  
**Platform:** Windows 10 / Windows 11  
**Version:** 1.0.0

## Launch

1. Extract all files into a new folder.
2. Double-click **Shell Diagnostic and Repair Toolkit.bat** or **Start.cmd**.
3. Keep Launch-Toolkit.vbs and both PowerShell files together with the launcher and Markdown files.

The launcher uses Windows Script Host to start Windows PowerShell hidden. Only the graphical toolkit remains
visible. Launch-Toolkit.vbs also works directly. Running a PS1 directly can leave a console visible. The
no-profile troubleshooting button intentionally opens a visible test shell.

## If Windows Blocks a Downloaded File

1. Right-click the downloaded ZIP.
2. Choose **Properties**.
3. Check **Unblock**, if shown, and click **Apply**.
4. Extract the ZIP and run the launcher.

If already extracted, check the blocked file's **Properties** too.

Unblock removes a download mark; it does not override Smart App Control, antivirus or organization policy. If
Windows still blocks it, read the exact message. Do not disable Windows protection simply to run the toolkit.
If Windows Script Host is disabled by organizational policy, contact your administrator.

## Requirements
Windows 10 or 11 with Windows PowerShell 5.1 and Windows Script Host. No PowerShell 7 or administrator access
is required. Execution-policy bypass is limited to this process. Some protected source files can require
additional access; the toolkit reports copy failures.

## Finish
Use **Exit Toolkit**, the red button at the bottom left. Wait for active operations to finish. Keep the new
backup private and verify it before depending on it.

## Optional Ko-fi support

Optional Support asks before opening [https://ko-fi.com/rebeltortuga](https://ko-fi.com/rebeltortuga) in your browser. All features remain free, and no payment information is collected by the toolkit.
