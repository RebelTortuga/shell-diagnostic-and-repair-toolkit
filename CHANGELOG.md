# Shell Diagnostic and Repair Toolkit
## Changelog

## Version 1.0.0 — 2026-10-14

### Interface and Branding

- Converted the original Shell and Project Backup utility into the Shell Diagnostic and Repair Toolkit, branded RebelTortuga.
- Added the matching toolkit sidebar, action area, labeled results box and saved session logs.
- Ordered sections as Profile and Folders, Backup & Restore, Diagnostics, Repair & Troubleshoot and Other Tools.
- Set Diagnostics to green, Detailed Options Guide to yellow, Optional Support to blue and Exit Toolkit to red with white text. Section changes preserve these colors; support has equal spacer rows above and below it.

### Launching

- Added a hidden-console BAT/VBS launcher and kept Start.cmd as a compatible entry point.

### Backup, Diagnostics, and Recovery

- Preserved the original backup discovery and copy coverage, registry/environment exports, restore mapping, checksums and completion marker.
- Added an empty-selection guard, local shell diagnostics, report export and backup checksum verification.
- Added a no-profile Windows PowerShell troubleshooting launch and explicit manual-restore guidance. Automatic restore is not implemented.

### Documentation

- Replaced `Read_Me.txt` with formatted `README.md`, `RUN-README.md`, `OPTIONS-README.md` and `CHANGELOG.md`, with consistent heading hierarchy, compact descriptions, readable menu tables and linked file references.
- No confirmed GitHub or Ko-fi URL was supplied; none was invented.

### Branding and optional support update

- Added the RebelTortuga mascot to the GitHub README.
- Added the confirmed optional Ko-fi support URL and an explicit confirmation before opening it.
- Updated companion documentation and removed superseded release-status notes.
