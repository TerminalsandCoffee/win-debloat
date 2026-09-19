<#
.SYNOPSIS
  Optional light app removal. Does NOT disable Defender or Windows Update.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string[]]$PackageNameLike = @(
    'Microsoft.BingNews',
    'Microsoft.BingWeather',
    'Microsoft.GamingApp',
    'Microsoft.MicrosoftSolitaireCollection',
    'Microsoft.People',
    'Microsoft.WindowsFeedbackHub',
    'Microsoft.Xbox.TCUI',
    'Microsoft.XboxGameOverlay',
    'Microsoft.XboxGamingOverlay',
    'Microsoft.XboxIdentityProvider',
    'Microsoft.XboxSpeechToTextOverlay',
    'Microsoft.YourPhone',
    'Microsoft.ZuneMusic',
    'Microsoft.ZuneVideo',
    'MicrosoftTeams',
    'Microsoft.Copilot'
  )
)

Write-Host 'Light debloat — apps only. Defender / Windows Update untouched.' -ForegroundColor Cyan
foreach ($like in $PackageNameLike) {
  $pkgs = Get-AppxPackage -Name $like -ErrorAction SilentlyContinue
  foreach ($pkg in $pkgs) {
    if ($PSCmdlet.ShouldProcess($pkg.Name, 'Remove-AppxPackage')) {
      try {
        Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
        Write-Host "Removed $($pkg.Name)"
      } catch {
        Write-Warning "Skip $($pkg.Name): $($_.Exception.Message)"
      }
    }
  }
}
Write-Host 'Done.'
