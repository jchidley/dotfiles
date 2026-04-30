# Idempotently apply the Windows Terminal preferences that are worth managing.
# Do not manage the live settings.json with chezmoi: Windows Terminal rewrites it.

$ErrorActionPreference = 'Stop'

$settingsPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
$settingsDir = Split-Path -Parent $settingsPath
if (-not (Test-Path $settingsDir)) {
    $null = New-Item -ItemType Directory -Path $settingsDir -Force
}

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

function Get-LxssIcon([string]$DistroName) {
    $lxssKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss'
    if (-not (Test-Path $lxssKey)) { return $null }

    $distro = Get-ChildItem $lxssKey | ForEach-Object { Get-ItemProperty $_.PSPath } |
        Where-Object { $_.DistributionName -eq $DistroName } |
        Select-Object -First 1

    if (-not $distro -or -not $distro.BasePath) { return $null }
    $icon = Join-Path $distro.BasePath 'shortcut.ico'
    if (Test-Path $icon) {
        return $icon -replace [regex]::Escape($env:LOCALAPPDATA), '%LOCALAPPDATA%'
    }
    return $null
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
        if ($null -ne $Desired[$key]) {
            Set-JsonProperty $profile $key $Desired[$key]
        }
    }

    # WSL profiles are intentionally static. Dynamic `source` profiles are owned
    # by Windows Terminal and get noisy under chezmoi.
    if ($Desired.commandline -like 'wsl.exe*') {
        Remove-JsonProperty $profile 'source'
    }

    Set-ProfileList $Settings $list
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

if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
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
Set-JsonProperty $settings 'defaultProfile' '{61c54bbd-c2c6-5271-96e7-009a87ff44bf}'
Set-JsonProperty $settings 'tabWidthMode' 'equal'
Set-JsonProperty $settings 'useAcrylicInTabRow' $false

if (-not $settings.PSObject.Properties['profiles']) {
    Set-JsonProperty $settings 'profiles' ([pscustomobject]@{})
}
Set-JsonProperty $settings.profiles 'defaults' ([pscustomobject]@{
    colorScheme = 'Gruvbox Dark (Hard)'
    font = [pscustomobject]@{
        face = 'SauceCodePro Nerd Font'
        size = 12
    }
})

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

Ensure-Profile $settings @{
    guid = '{61c54bbd-c2c6-5271-96e7-009a87ff44bf}'
    name = 'Windows PowerShell'
    commandline = '%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe'
    hidden = $false
}

Ensure-Profile $settings @{
    guid = '{58ad8b0c-3ef8-5f4d-bc6f-13e4c00f2530}'
    name = 'Debian'
    commandline = 'wsl.exe -d Debian'
    startingDirectory = '~'
    icon = Get-LxssIcon 'Debian'
    hidden = $false
}

Ensure-Profile $settings @{
    guid = '{77526b00-08ae-4477-bddc-9587432a0901}'
    name = 'Alpine Linux'
    commandline = 'wsl.exe -d Alpine'
    startingDirectory = '~'
    icon = Get-LxssIcon 'Alpine'
    hidden = $false
}

Ensure-Profile $settings @{
    guid = '{a06ad568-9eae-4b45-98e1-d7b6a5309eec}'
    name = 'Arch Linux'
    commandline = 'wsl.exe -d archlinux'
    startingDirectory = '~'
    icon = Get-LxssIcon 'archlinux'
    hidden = $false
}

$newJson = $settings | ConvertTo-Json -Depth 100
$currentJson = if (Test-Path $settingsPath) { Get-Content $settingsPath -Raw } else { '' }
if ($currentJson.Trim() -ne $newJson.Trim()) {
    Set-Content -Path $settingsPath -Value $newJson -Encoding UTF8
    Write-Host "Updated Windows Terminal settings: $settingsPath"
} else {
    Write-Host "Windows Terminal settings already up to date"
}
