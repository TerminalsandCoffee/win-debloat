# win-debloat

Safe Windows cleanup for a daily-driver laptop: unhook OneDrive Known Folder Move from Desktop, optionally uninstall OneDrive, optionally remove a small set of consumer Store apps.

Built for people who want control of their Desktop without gutting security baselines.

## Design principles

- **Desktop first.** Fix Known Folder Move so Explorer points at `%USERPROFILE%\Desktop`, not OneDrive.
- **Security left alone.** These scripts do **not** disable Windows Defender, Windows Update, BitLocker, or SmartScreen.
- **Opt-in extras.** OneDrive uninstall and app removals are separate scripts you run only if you want them.

## Scripts

| Script | What it does |
|--------|----------------|
| `Unhook-OneDrive-Desktop.ps1` | Points Desktop known folders back to local Desktop; archives leftover OneDrive Desktop items |
| `Remove-OneDrive.ps1` | Uninstalls OneDrive **after** Desktop is local (refuses if still on OneDrive) |
| `Light-Debloat.ps1` | Removes a short list of consumer Appx packages (Xbox overlays, Bing News, etc.) |

## Quick start

```powershell
# From an elevated PowerShell session is safest for uninstall later
Set-ExecutionPolicy -Scope Process Bypass -Force
cd path\to\win-debloat

# 1) Unhook Desktop from OneDrive
.\Unhook-OneDrive-Desktop.ps1

# Optional: preserve specific files before leftovers are archived
# .\Unhook-OneDrive-Desktop.ps1 -Keepers @('Notes.docx','Work.lnk')

# 2) Confirm Explorer address bar shows ...\Desktop (not ...\OneDrive\Desktop)
# 3) Later, if you want OneDrive gone:
# .\Remove-OneDrive.ps1

# 4) Optional app cleanup:
# .\Light-Debloat.ps1
# .\Light-Debloat.ps1 -WhatIf   # preview
```

## What it deliberately does NOT do

- Disable Windows Defender / real-time protection
- Disable Windows Update
- Mass-delete Store apps / break enterprise SSO
- Touch BitLocker keys
- Force-remove OneDrive while Desktop is still redirected

## Requirements

- Windows 10/11
- PowerShell 5.1+ (Windows PowerShell is fine)
- For `Remove-OneDrive.ps1`: ability to run `OneDriveSetup.exe /uninstall` (often needs elevation)

## Brand / provenance

Published by [TerminalsandCoffee](https://github.com/TerminalsandCoffee) for Secure Cloud Academy–aligned hygiene: reverse bad defaults, keep defenses on.

## License

MIT — see [LICENSE](LICENSE).
