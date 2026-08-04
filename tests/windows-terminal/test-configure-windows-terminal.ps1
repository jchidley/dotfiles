$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$scriptPath = Join-Path $repoRoot 'scripts\configure-windows-terminal.ps1'
$inputFixture = Join-Path $PSScriptRoot 'input-settings.json'
$expectedFixture = Join-Path $PSScriptRoot 'expected-state.json'
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

    $debianRoot = Join-Path $work 'Debian'
    $recoveredRoot = Join-Path $work 'Debian-Recovered'
    $null = New-Item -ItemType Directory -Path $debianRoot
    $null = New-Item -ItemType Directory -Path $recoveredRoot
    [System.IO.File]::WriteAllBytes((Join-Path $debianRoot 'shortcut.ico'), [byte[]](1, 2, 3))
    [System.IO.File]::WriteAllBytes((Join-Path $recoveredRoot 'shortcut.ico'), [byte[]](4, 5, 6))

    $distributions = @(
        [pscustomobject]@{ Name = 'Debian'; BasePath = $debianRoot },
        [pscustomobject]@{ Name = 'Debian-Recovered'; BasePath = $recoveredRoot }
    )

    & $scriptPath -SettingsPath $settingsPath -Distributions $distributions
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
    $debian = Get-Profile $settings '{58ad8b0c-3ef8-5f4d-bc6f-13e4c00f2530}'
    $recovered = Get-Profile $settings '{20517053-d9f3-52e4-b051-e3ddd867b0a3}'
    $arch = Get-Profile $settings '{a06ad568-9eae-4b45-98e1-d7b6a5309eec}'
    $alpine = Get-Profile $settings '{77526b00-08ae-4477-bddc-9587432a0901}'

    Assert-Equal $windowsPowerShell.hidden $expected.profiles.windowsPowerShellHidden 'Windows PowerShell visibility differs'
    Assert-Equal $powerShell7.hidden $expected.profiles.powerShell7Hidden 'PowerShell 7 visibility differs'
    Assert-Equal $debian.hidden $expected.profiles.debianHidden 'Debian visibility differs'
    Assert-Equal $recovered.hidden $expected.profiles.debianRecoveredHidden 'Debian-Recovered visibility differs'
    Assert-Equal $arch.hidden $expected.profiles.archHiddenWhenAbsent 'stale Arch profile was not hidden'
    Assert-Equal (@($settings.profiles.list | Where-Object { $_.guid -eq '{77526b00-08ae-4477-bddc-9587432a0901}' }).Count -eq 0) $expected.profiles.alpineAbsentWhenNotInstalled 'absent Alpine profile was created'
    Assert-True (-not $debian.PSObject.Properties['source']) 'Debian profile remained dynamically sourced'
    Assert-True (-not $recovered.PSObject.Properties['source']) 'Debian-Recovered profile remained dynamically sourced'
    Assert-Equal $debian.commandline 'wsl.exe -d Debian' 'Debian command line differs'
    Assert-Equal $recovered.commandline 'wsl.exe -d Debian-Recovered' 'Debian-Recovered command line differs'
    Assert-True ($debian.icon -like '*shortcut.ico') 'Debian icon was not discovered'
    Assert-True ($recovered.icon -like '*shortcut.ico') 'Debian-Recovered icon was not discovered'

    Assert-Equal $settings.disableAnimations $expected.preserved.disableAnimations 'unmanaged animation setting was not preserved'
    Assert-Equal @($settings.actions).Count $expected.preserved.actionsCount 'unmanaged actions were not preserved'
    Assert-Equal ([bool](Get-Profile $settings '{0caa0dad-35be-5f56-a8ff-afceeeaa6101}')) $expected.preserved.commandPrompt 'Command Prompt profile was not preserved'
    $custom = Get-Profile $settings '{11111111-1111-1111-1111-111111111111}'
    Assert-Equal ([bool]$custom) $expected.preserved.customProfile 'custom profile was not preserved'
    Assert-Equal $custom.'experimental.retroTerminalEffect' $expected.preserved.customRetroEffect 'custom profile property was not preserved'
    Assert-Equal ([bool]($settings.schemes | Where-Object { $_.name -eq 'Keep Me' })) $expected.preserved.keepMeScheme 'unmanaged color scheme was not preserved'
    Assert-Equal ($settings.schemes | Where-Object { $_.name -eq 'Gruvbox Dark (Hard)' }).background $expected.gruvboxBackground 'managed Gruvbox scheme was not replaced'

    $firstHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $settingsPath).Hash
    & $scriptPath -SettingsPath $settingsPath -Distributions $distributions
    $secondHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $settingsPath).Hash
    Assert-Equal $secondHash $firstHash 'second application was not idempotent'

    $whatIfPath = Join-Path $work 'whatif-settings.json'
    Copy-Item -LiteralPath $inputFixture -Destination $whatIfPath
    $beforeWhatIf = (Get-FileHash -Algorithm SHA256 -LiteralPath $whatIfPath).Hash
    & $scriptPath -SettingsPath $whatIfPath -Distributions $distributions -WhatIf
    $afterWhatIf = (Get-FileHash -Algorithm SHA256 -LiteralPath $whatIfPath).Hash
    Assert-Equal $afterWhatIf $beforeWhatIf '-WhatIf modified settings'

    $debianOnlyPath = Join-Path $work 'debian-only-settings.json'
    Copy-Item -LiteralPath $inputFixture -Destination $debianOnlyPath
    & $scriptPath -SettingsPath $debianOnlyPath -Distributions @($distributions[0])
    $debianOnly = Get-Content -LiteralPath $debianOnlyPath -Raw | ConvertFrom-Json
    Assert-Equal $debianOnly.defaultProfile $expected.debianOnlyDefaultProfile 'Debian was not selected when the recovered distro was absent'

    $noWslPath = Join-Path $work 'new\settings.json'
    & $scriptPath -SettingsPath $noWslPath -Distributions @()
    $noWsl = Get-Content -LiteralPath $noWslPath -Raw | ConvertFrom-Json
    Assert-Equal $noWsl.defaultProfile $expected.noWslDefaultProfile 'Windows PowerShell was not selected when WSL was absent'
    Assert-Equal @($noWsl.profiles.list | Where-Object { $_.commandline -like 'wsl.exe -d *' }).Count 0 'WSL profiles were created when no distros were installed'

    $newWhatIfPath = Join-Path $work 'whatif-new\settings.json'
    & $scriptPath -SettingsPath $newWhatIfPath -Distributions @() -WhatIf
    Assert-True (-not (Test-Path -LiteralPath (Split-Path -Parent $newWhatIfPath))) '-WhatIf created a settings directory'

    $leftovers = @(Get-ChildItem -LiteralPath $work -Recurse -File | Where-Object { $_.Name -match '\.(tmp|bak)$' })
    Assert-Equal $leftovers.Count 0 'atomic writer left temporary files behind'

    Write-Host 'PASS: Windows Terminal configuration is selective, conditional, atomic, idempotent, and WhatIf-safe'
} finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
