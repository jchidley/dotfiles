#requires -Version 7.0
$ErrorActionPreference = 'Stop'

$testDir = if ($env:DOTFILES_TEST_DIR) { $env:DOTFILES_TEST_DIR } else { $PSScriptRoot }
$repoRoot = if ($env:DOTFILES_REPO_ROOT) {
    $env:DOTFILES_REPO_ROOT
} else {
    (Resolve-Path (Join-Path $testDir '..\..')).Path
}
$scriptPath = Join-Path $repoRoot 'scripts\configure-windows-terminal.ps1'
$inputFixture = Join-Path $testDir 'input-settings.json'
$expectedFixture = Join-Path $testDir 'expected-state.json'
$expected = Get-Content -LiteralPath $expectedFixture -Raw | ConvertFrom-Json
$work = Join-Path $env:TEMP ('windows-terminal-dotfiles-test-' + [guid]::NewGuid().ToString('N'))

function Assert-Equal($Actual, $Expected, [string]$Message) {
    if ($Actual -ne $Expected) {
        throw "$Message (expected '$Expected', got '$Actual')"
    }
}

function Assert-True($Value, [string]$Message) {
    if (-not $Value) { throw $Message }
}

function Get-Profile($Settings, [string]$Guid) {
    return $Settings.profiles.list | Where-Object { $_.guid -eq $Guid } | Select-Object -First 1
}

try {
    $null = New-Item -ItemType Directory -Path $work
    $settingsPath = Join-Path $work 'settings.json'
    Copy-Item -LiteralPath $inputFixture -Destination $settingsPath

    & $scriptPath -SettingsPath $settingsPath
    $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json

    Assert-Equal $settings.copyFormatting $expected.copyFormatting 'copyFormatting policy differs'
    Assert-Equal $settings.copyOnSelect $expected.copyOnSelect 'copyOnSelect policy differs'
    Assert-Equal $settings.tabWidthMode $expected.tabWidthMode 'tabWidthMode policy differs'
    Assert-Equal $settings.useAcrylicInTabRow $expected.useAcrylicInTabRow 'tab-row acrylic policy differs'
    Assert-Equal $settings.defaultProfile $expected.defaultProfile 'preferred default profile differs'

    Assert-Equal $settings.profiles.defaults.colorScheme $expected.profileDefaults.colorScheme 'default color scheme differs'
    Assert-Equal $settings.profiles.defaults.font.face $expected.profileDefaults.fontFace 'default font face differs'
    Assert-Equal $settings.profiles.defaults.font.size $expected.profileDefaults.fontSize 'default font size differs'
    Assert-Equal $settings.profiles.defaults.opacity $expected.profileDefaults.preservedOpacity 'unmanaged default opacity was not preserved'
    Assert-Equal $settings.profiles.defaults.font.weight $expected.profileDefaults.preservedFontWeight 'unmanaged font weight was not preserved'

    $windowsPowerShell = Get-Profile $settings '{61c54bbd-c2c6-5271-96e7-009a87ff44bf}'
    $powerShell7 = Get-Profile $settings '{574e775e-4f2a-5b96-ac1e-a2962a402336}'
    $herdr = Get-Profile $settings '{ed03c588-ea88-47d4-9e2d-ebfb2913b0ba}'
    $debian4 = Get-Profile $settings '{4eeffcc0-18c0-5b29-b6c3-02305b49996d}'
    $lfsBuilder = Get-Profile $settings '{019eae77-1a16-5569-b272-c73b29fdf035}'
    $commandPrompt = Get-Profile $settings '{0caa0dad-35be-5f56-a8ff-afceeeaa6101}'

    Assert-Equal $windowsPowerShell.hidden $expected.profiles.windowsPowerShellHidden 'Windows PowerShell visibility differs'
    Assert-Equal $windowsPowerShell.name 'Windows PowerShell (unsupported)' 'Windows PowerShell was not marked unsupported'
    Assert-Equal $powerShell7.hidden $expected.profiles.powerShell7Hidden 'PowerShell 7 visibility differs'
    Assert-Equal $powerShell7.commandline 'pwsh.exe' 'PowerShell 7 does not explicitly launch pwsh.exe'
    Assert-True (-not $powerShell7.PSObject.Properties['source']) 'PowerShell 7 remained dynamically sourced'
    Assert-Equal $herdr.name 'herdr' 'herdr profile name differs'
    Assert-Equal $herdr.commandline '%USERPROFILE%\.herdr\packages\standalone\current\herdr.exe' 'herdr profile command line differs'
    Assert-Equal $herdr.icon '%LOCALAPPDATA%\dotfiles\icons\herdr-logo.png' 'herdr profile icon differs'
    Assert-Equal $herdr.hidden $false 'herdr profile is hidden'
    Assert-Equal $debian4.hidden $false 'Debian4 profile is hidden'
    Assert-Equal $debian4.commandline 'wsl.exe -d Debian4 -u jack --exec bash --login' 'Debian4 must explicitly launch login Bash'
    Assert-Equal $debian4.icon '%LOCALAPPDATA%\dotfiles\icons\debian-official-swirl.png' 'Debian4 custom icon differs'
    Assert-True (-not $debian4.PSObject.Properties['source']) 'Debian4 profile remained dynamically sourced'
    Assert-Equal $lfsBuilder.hidden $true 'LFS-Builder profile was not suppressed'
    Assert-Equal $commandPrompt.hidden $false 'Command Prompt is hidden'
    Assert-Equal $commandPrompt.commandline '%SystemRoot%\System32\cmd.exe' 'Command Prompt command line differs'
    Assert-Equal $commandPrompt.icon '%SystemRoot%\System32\cmd.exe' 'Command Prompt standard icon differs'
    Assert-Equal @($settings.profiles.list)[-1].guid $commandPrompt.guid 'Command Prompt is not last in the managed menu order'

    Assert-Equal $settings.disableAnimations $expected.preserved.disableAnimations 'unmanaged animation setting was not preserved'
    Assert-Equal @($settings.actions).Count $expected.preserved.actionsCount 'unmanaged actions were not preserved'
    $custom = Get-Profile $settings '{11111111-1111-1111-1111-111111111111}'
    Assert-Equal ([bool]$custom) $expected.preserved.customProfile 'custom profile was not preserved'
    Assert-Equal $custom.'experimental.retroTerminalEffect' $expected.preserved.customRetroEffect 'custom profile property was not preserved'
    Assert-Equal ([bool]($settings.schemes | Where-Object { $_.name -eq 'Keep Me' })) $expected.preserved.keepMeScheme 'unmanaged color scheme was not preserved'
    Assert-Equal ($settings.schemes | Where-Object { $_.name -eq 'Gruvbox Dark (Hard)' }).background $expected.gruvboxBackground 'managed Gruvbox scheme was not replaced'

    $firstHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $settingsPath).Hash
    & $scriptPath -SettingsPath $settingsPath
    $secondHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $settingsPath).Hash
    Assert-Equal $secondHash $firstHash 'second application was not idempotent'

    $whatIfPath = Join-Path $work 'whatif-settings.json'
    Copy-Item -LiteralPath $inputFixture -Destination $whatIfPath
    $beforeWhatIf = (Get-FileHash -Algorithm SHA256 -LiteralPath $whatIfPath).Hash
    & $scriptPath -SettingsPath $whatIfPath -WhatIf
    $afterWhatIf = (Get-FileHash -Algorithm SHA256 -LiteralPath $whatIfPath).Hash
    Assert-Equal $afterWhatIf $beforeWhatIf '-WhatIf modified settings'

    $newSettingsPath = Join-Path $work 'new\settings.json'
    & $scriptPath -SettingsPath $newSettingsPath
    $newSettings = Get-Content -LiteralPath $newSettingsPath -Raw | ConvertFrom-Json
    Assert-Equal $newSettings.defaultProfile $expected.defaultProfile 'PowerShell 7 was not selected for new settings'
    Assert-Equal @($newSettings.profiles.list)[-1].guid '{0caa0dad-35be-5f56-a8ff-afceeeaa6101}' 'Command Prompt is not last in new settings'

    $newWhatIfPath = Join-Path $work 'whatif-new\settings.json'
    & $scriptPath -SettingsPath $newWhatIfPath -WhatIf
    Assert-True (-not (Test-Path -LiteralPath (Split-Path -Parent $newWhatIfPath))) '-WhatIf created a settings directory'

    $leftovers = @(Get-ChildItem -LiteralPath $work -Recurse -File | Where-Object { $_.Name -match '\.(tmp|bak)$' })
    Assert-Equal $leftovers.Count 0 'atomic writer left temporary files behind'

    Write-Host 'PASS: Windows Terminal configuration is selective, conditional, atomic, idempotent, and WhatIf-safe'
} finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
