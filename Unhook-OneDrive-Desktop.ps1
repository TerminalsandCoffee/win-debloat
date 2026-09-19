<#
.SYNOPSIS
  Point Windows Desktop Known Folder back to %USERPROFILE%\Desktop (leave OneDrive installed).
.DESCRIPTION
  Undoes OneDrive Known Folder Move for Desktop only. Optionally copies named keepers
  from OneDrive\Desktop to the local Desktop, then archives remaining OneDrive Desktop
  items under %USERPROFILE%\_Archive\OneDriveDesktop-unhook.
.NOTES
  Does not disable Defender, Windows Update, BitLocker, or SmartScreen.
  Edit -Keepers (or the default list below) before running if you want specific files preserved.
#>
[CmdletBinding()]
param(
  [switch]$SkipCopyKeepers,
  # Names of files/folders on OneDrive\Desktop to copy to local Desktop before archive.
  [string[]]$Keepers = @()
)

$ErrorActionPreference = 'Stop'
$localDesktop = Join-Path $env:USERPROFILE 'Desktop'
$odDesktop = Join-Path $env:USERPROFILE 'OneDrive\Desktop'
$archive = Join-Path $env:USERPROFILE '_Archive\OneDriveDesktop-unhook'
$shellFolders = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
$shellFolders2 = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders'

function Write-Step([string]$msg) { Write-Host ""; Write-Host "==> $msg" -ForegroundColor Cyan }

Write-Step "Local Desktop: $localDesktop"
Write-Step "OneDrive Desktop: $odDesktop"
New-Item -ItemType Directory -Force -Path $localDesktop | Out-Null
New-Item -ItemType Directory -Force -Path $archive | Out-Null

if (-not $SkipCopyKeepers -and $Keepers.Count -gt 0 -and (Test-Path -LiteralPath $odDesktop)) {
  Write-Step 'Copying keepers from OneDrive Desktop to local Desktop'
  foreach ($name in $Keepers) {
    $src = Join-Path $odDesktop $name
    if (Test-Path -LiteralPath $src) {
      $dst = Join-Path $localDesktop $name
      if (-not (Test-Path -LiteralPath $dst)) {
        Copy-Item -LiteralPath $src -Destination $dst -Force
        Write-Host "  kept: $name"
      } else {
        Write-Host "  already on local: $name"
      }
    }
  }
}

if (Test-Path -LiteralPath $odDesktop) {
  Write-Step 'Moving leftover OneDrive Desktop items to local archive'
  Get-ChildItem -LiteralPath $odDesktop -Force | Where-Object { $_.Name -ne 'desktop.ini' } | ForEach-Object {
    $target = Join-Path $archive $_.Name
    if (Test-Path -LiteralPath $target) {
      $target = Join-Path $archive ($_.Name + '_' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    }
    try {
      Move-Item -LiteralPath $_.FullName -Destination $target -Force
      Write-Host "  archived: $($_.Name)"
    } catch {
      if ($_.PSIsContainer) {
        New-Item -ItemType Directory -Force -Path $target | Out-Null
        & robocopy $_.FullName $target /E /MOVE /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
        if (Test-Path -LiteralPath $_.FullName) {
          Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
        Write-Host "  robocopy archived: $($_.Name)"
      } else {
        Write-Warning "Could not move $($_.Name): $($_.Exception.Message)"
      }
    }
  }
}

Write-Step 'Rewriting Desktop known-folder registry to local Desktop'
Set-ItemProperty -Path $shellFolders -Name 'Desktop' -Value $localDesktop -Type ExpandString
Set-ItemProperty -Path $shellFolders2 -Name 'Desktop' -Value $localDesktop
$guidName = '{754AC886-DF64-4CBA-86B5-F7FBF4FBCEF5}'
if (Get-ItemProperty -Path $shellFolders -Name $guidName -ErrorAction SilentlyContinue) {
  Set-ItemProperty -Path $shellFolders -Name $guidName -Value $localDesktop -Type ExpandString
}

Write-Step 'Clearing OneDrive KFM desktop flags if present'
$odAccounts = 'HKCU:\Software\Microsoft\OneDrive\Accounts'
if (Test-Path $odAccounts) {
  Get-ChildItem $odAccounts -ErrorAction SilentlyContinue | ForEach-Object {
    $p = $_.PSPath
    foreach ($n in @('KfmStateDesktop','KfmFoldersProtected')) {
      if (Get-ItemProperty -Path $p -Name $n -ErrorAction SilentlyContinue) {
        try { Set-ItemProperty -Path $p -Name $n -Value 0 -ErrorAction SilentlyContinue } catch {}
      }
    }
  }
}

Write-Step 'Restarting Explorer'
Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Start-Process explorer.exe

Write-Host ""
Write-Host "Done. Desktop should now be: $localDesktop" -ForegroundColor Green
Write-Host "Archive: $archive"
Write-Host "Optional next: .\Remove-OneDrive.ps1"
