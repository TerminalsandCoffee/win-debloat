<#
.SYNOPSIS
  Uninstall OneDrive after Desktop is local again.
.NOTES
  Run Unhook-OneDrive-Desktop.ps1 first and confirm Desktop path.
  Does not touch Defender or Windows Update.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param()

$ErrorActionPreference = 'Stop'
$desktop = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders').Desktop
Write-Host "Current Desktop registry path: $desktop"
if ($desktop -match 'OneDrive') {
  throw "Desktop still points at OneDrive. Run Unhook-OneDrive-Desktop.ps1 first."
}

$candidates = @(
  "$env:SystemRoot\System32\OneDriveSetup.exe",
  "$env:SystemRoot\SysWOW64\OneDriveSetup.exe",
  "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDriveSetup.exe"
) | Where-Object { Test-Path $_ }

if (-not $candidates) {
  Write-Host 'OneDriveSetup.exe not found — OneDrive may already be gone.'
  exit 0
}

$setup = $candidates[0]
Write-Host "Uninstalling via $setup /uninstall"
if ($PSCmdlet.ShouldProcess('OneDrive', 'Uninstall')) {
  Start-Process -FilePath $setup -ArgumentList '/uninstall' -Wait
}

# Remove leftover Run key that relaunches OneDrive
$run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
if (Get-ItemProperty -Path $run -Name 'OneDrive' -ErrorAction SilentlyContinue) {
  Remove-ItemProperty -Path $run -Name 'OneDrive' -ErrorAction SilentlyContinue
  Write-Host 'Removed HKCU Run\OneDrive'
}

Write-Host 'OneDrive uninstall requested. Sign out/in if the cloud icon remains.' -ForegroundColor Green
