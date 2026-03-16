# Windows PowerShell 5.1 profile — delegates to the shared PowerShell 7 profile
$ps7Profile = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
if (Test-Path $ps7Profile) {
    . $ps7Profile
} else {
    Write-Warning "Shared profile not found: $ps7Profile"
}
