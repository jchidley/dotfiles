#requires -Version 7.0
# Idempotently apply the Windows Terminal preferences that are worth managing.
# Do not manage the live settings.json with chezmoi: Windows Terminal rewrites it.

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$SettingsPath = (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json')
)

$ErrorActionPreference = 'Stop'

$windowsPowerShellGuid = '{61c54bbd-c2c6-5271-96e7-009a87ff44bf}'
$commandPromptGuid = '{0caa0dad-35be-5f56-a8ff-afceeeaa6101}'
$powerShellCoreGuid = '{574e775e-4f2a-5b96-ac1e-a2962a402336}'
$debian4Guid = '{4eeffcc0-18c0-5b29-b6c3-02305b49996d}'
$lfsBuilderGuid = '{019eae77-1a16-5569-b272-c73b29fdf035}'
$herdrGuid = '{ed03c588-ea88-47d4-9e2d-ebfb2913b0ba}'

function New-ObjectFromHashtable([hashtable]$Hash) {
    $obj = [pscustomobject]@{}
    foreach ($key in $Hash.Keys) {
        $obj | Add-Member -NotePropertyName $key -NotePropertyValue $Hash[$key] -Force
    }
    return $obj
}

function Set-JsonProperty($Object, [string]$Name, $Value) {
    $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value -Force
}

function Remove-JsonProperty($Object, [string]$Name) {
    $prop = $Object.PSObject.Properties[$Name]
    if ($prop) {
        $Object.PSObject.Properties.Remove($Name)
    }
}

function Get-ProfileList($Settings) {
    if (-not $Settings.PSObject.Properties['profiles']) {
        Set-JsonProperty $Settings 'profiles' ([pscustomobject]@{})
    }
    if (-not $Settings.profiles.PSObject.Properties['list'] -or $null -eq $Settings.profiles.list) {
        Set-JsonProperty $Settings.profiles 'list' @()
    }

    $list = New-Object System.Collections.ArrayList
    foreach ($profile in @($Settings.profiles.list)) {
        if ($null -ne $profile) { [void]$list.Add($profile) }
    }
    return ,$list
}

function Set-ProfileList($Settings, [System.Collections.ArrayList]$List) {
    Set-JsonProperty $Settings.profiles 'list' @($List.ToArray())
}

function Ensure-Profile($Settings, [hashtable]$Desired) {
    $list = Get-ProfileList $Settings
    $profile = $null

    foreach ($candidate in $list) {
        if ($candidate.guid -eq $Desired.guid) {
            $profile = $candidate
            break
        }
    }
    if (-not $profile) {
        $profile = [pscustomobject]@{}
        [void]$list.Add($profile)
    }

    foreach ($key in $Desired.Keys) {
        if ($null -eq $Desired[$key]) {
            Remove-JsonProperty $profile $key
        } else {
            Set-JsonProperty $profile $key $Desired[$key]
        }
    }

    # Static WSL profiles avoid dynamic-source churn when settings.json is
    # rewritten. Other dynamic profiles retain their source property.
    if ($Desired.ContainsKey('commandline') -and $Desired.commandline -like 'wsl.exe*') {
        Remove-JsonProperty $profile 'source'
    }

    Set-ProfileList $Settings $list
}

function Set-ProfileOrder($Settings, [string[]]$Guids) {
    $list = Get-ProfileList $Settings
    $ordered = New-Object System.Collections.ArrayList

    foreach ($profile in $list) {
        if ($profile.guid -notin $Guids) { [void]$ordered.Add($profile) }
    }
    foreach ($guid in $Guids) {
        foreach ($profile in $list) {
            if ($profile.guid -eq $guid) { [void]$ordered.Add($profile); break }
        }
    }

    Set-ProfileList $Settings $ordered
}

function Ensure-Scheme($Settings, [hashtable]$Desired) {
    if (-not $Settings.PSObject.Properties['schemes'] -or $null -eq $Settings.schemes) {
        Set-JsonProperty $Settings 'schemes' @()
    }

    $schemes = New-Object System.Collections.ArrayList
    foreach ($scheme in @($Settings.schemes)) {
        if ($null -ne $scheme -and $scheme.name -ne $Desired.name) {
            [void]$schemes.Add($scheme)
        }
    }
    [void]$schemes.Add((New-ObjectFromHashtable $Desired))
    Set-JsonProperty $Settings 'schemes' @($schemes.ToArray())
}

function Write-JsonAtomically([string]$Path, [string]$Content) {
    $directory = Split-Path -Parent $Path
    if (-not (Test-Path $directory)) {
        $null = New-Item -ItemType Directory -Path $directory -Force
    }

    $suffix = [guid]::NewGuid().ToString('N')
    $tempPath = Join-Path $directory ((Split-Path -Leaf $Path) + ".${suffix}.tmp")
    $backupPath = Join-Path $directory ((Split-Path -Leaf $Path) + ".${suffix}.bak")
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)

    try {
        [System.IO.File]::WriteAllText($tempPath, $Content, $utf8NoBom)
        $null = Get-Content -LiteralPath $tempPath -Raw | ConvertFrom-Json

        if ([System.IO.File]::Exists($Path)) {
            [System.IO.File]::Replace($tempPath, $Path, $backupPath, $true)
            Remove-Item -LiteralPath $backupPath -Force -ErrorAction SilentlyContinue
        } else {
            [System.IO.File]::Move($tempPath, $Path)
        }
    } finally {
        Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $backupPath -Force -ErrorAction SilentlyContinue
    }
}

if (Test-Path -LiteralPath $SettingsPath) {
    $settings = Get-Content -LiteralPath $SettingsPath -Raw | ConvertFrom-Json
} else {
    $settings = [pscustomobject]@{
        '$schema' = 'https://aka.ms/terminal-profiles-schema'
        profiles = [pscustomobject]@{ list = @(); defaults = [pscustomobject]@{} }
        schemes = @()
    }
}

# Preferences worth managing. Everything else remains Windows Terminal-owned.
Set-JsonProperty $settings 'copyFormatting' 'none'
Set-JsonProperty $settings 'copyOnSelect' $true
Set-JsonProperty $settings 'tabWidthMode' 'equal'
Set-JsonProperty $settings 'useAcrylicInTabRow' $false

if (-not $settings.PSObject.Properties['profiles']) {
    Set-JsonProperty $settings 'profiles' ([pscustomobject]@{})
}
if (-not $settings.profiles.PSObject.Properties['defaults'] -or $null -eq $settings.profiles.defaults) {
    Set-JsonProperty $settings.profiles 'defaults' ([pscustomobject]@{})
}
Set-JsonProperty $settings.profiles.defaults 'colorScheme' 'Gruvbox Dark (Hard)'
if (-not $settings.profiles.defaults.PSObject.Properties['font'] -or $null -eq $settings.profiles.defaults.font) {
    Set-JsonProperty $settings.profiles.defaults 'font' ([pscustomobject]@{})
}
Set-JsonProperty $settings.profiles.defaults.font 'face' 'SauceCodePro Nerd Font'
Set-JsonProperty $settings.profiles.defaults.font 'size' 12

Ensure-Scheme $settings @{
    name = 'Gruvbox Dark (Hard)'
    background = '#1D2021'
    foreground = '#FBF1C7'
    black = '#1D2021'
    red = '#CC241D'
    green = '#98971A'
    yellow = '#D79921'
    blue = '#458588'
    purple = '#B16286'
    cyan = '#689D6A'
    white = '#A89984'
    brightBlack = '#928374'
    brightRed = '#FB4934'
    brightGreen = '#B8BB26'
    brightYellow = '#FABD2F'
    brightBlue = '#83A598'
    brightPurple = '#D3869B'
    brightCyan = '#8EC07C'
    brightWhite = '#EBDBB2'
    cursorColor = '#FBF1C7'
    selectionBackground = '#7C6F64'
}

# The menu is intentionally small: three primary profiles, Command Prompt last,
# and only generated profiles that cannot be removed are hidden.
Ensure-Profile $settings @{
    guid = $windowsPowerShellGuid
    name = 'Windows PowerShell (unsupported)'
    commandline = '%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe'
    hidden = $true
}
Ensure-Profile $settings @{
    guid = $lfsBuilderGuid
    name = 'LFS-Builder'
    hidden = $true
}

Ensure-Profile $settings @{
    guid = $powerShellCoreGuid
    name = 'PowerShell 7'
    commandline = 'pwsh.exe'
    source = $null
    hidden = $false
}
Ensure-Profile $settings @{
    guid = $herdrGuid
    name = 'herdr'
    commandline = '%USERPROFILE%\.herdr\packages\standalone\current\herdr.exe'
    icon = '%LOCALAPPDATA%\dotfiles\icons\herdr-logo.png'
    hidden = $false
}
Ensure-Profile $settings @{
    guid = $debian4Guid
    name = 'Debian4'
    commandline = 'wsl.exe -d Debian4 -u jack --exec bash --login'
    startingDirectory = '~'
    icon = '%LOCALAPPDATA%\dotfiles\icons\debian-official-swirl.png'
    hidden = $false
}
Ensure-Profile $settings @{
    guid = $commandPromptGuid
    name = 'Command Prompt'
    commandline = '%SystemRoot%\System32\cmd.exe'
    icon = '%SystemRoot%\System32\cmd.exe'
    hidden = $false
}

# Windows Terminal renders profiles in list order. Keep Command Prompt available
# for compatibility while placing it after the primary profiles.
Set-ProfileOrder $settings @($powerShellCoreGuid, $herdrGuid, $debian4Guid, $commandPromptGuid)
Set-JsonProperty $settings 'defaultProfile' $powerShellCoreGuid

$newJson = $settings | ConvertTo-Json -Depth 100
$null = $newJson | ConvertFrom-Json
$currentJson = if (Test-Path -LiteralPath $SettingsPath) {
    Get-Content -LiteralPath $SettingsPath -Raw
} else {
    ''
}

if ($currentJson.Trim() -eq $newJson.Trim()) {
    Write-Host 'Windows Terminal settings already up to date'
} elseif ($PSCmdlet.ShouldProcess($SettingsPath, 'Update Windows Terminal settings')) {
    Write-JsonAtomically $SettingsPath $newJson
    Write-Host "Updated Windows Terminal settings: $SettingsPath"
}
