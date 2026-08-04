# Idempotently apply the Windows Terminal preferences that are worth managing.
# Do not manage the live settings.json with chezmoi: Windows Terminal rewrites it.

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$SettingsPath = (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
    [object[]]$Distributions
)

$ErrorActionPreference = 'Stop'

$windowsPowerShellGuid = '{61c54bbd-c2c6-5271-96e7-009a87ff44bf}'
$powerShellCoreGuid = '{574e775e-4f2a-5b96-ac1e-a2962a402336}'

# Profile policy is data, while profile mutation remains generic below.
$wslProfileSpecs = @(
    [pscustomobject]@{
        Distro = 'Debian'
        Name = 'Debian'
        Guid = '{58ad8b0c-3ef8-5f4d-bc6f-13e4c00f2530}'
        DefaultPriority = 2
    },
    [pscustomobject]@{
        Distro = 'Debian-Recovered'
        Name = 'Debian-Recovered'
        Guid = '{20517053-d9f3-52e4-b051-e3ddd867b0a3}'
        DefaultPriority = 1
    },
    [pscustomobject]@{
        Distro = 'Alpine'
        Name = 'Alpine Linux'
        Guid = '{77526b00-08ae-4477-bddc-9587432a0901}'
        DefaultPriority = 0
    },
    [pscustomobject]@{
        Distro = 'archlinux'
        Name = 'Arch Linux'
        Guid = '{a06ad568-9eae-4b45-98e1-d7b6a5309eec}'
        DefaultPriority = 0
    }
)

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

function Get-LxssDistributions {
    $lxssKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss'
    if (-not (Test-Path $lxssKey)) { return @() }

    return @(Get-ChildItem $lxssKey | ForEach-Object { Get-ItemProperty $_.PSPath } |
        Where-Object { $_.DistributionName -and $_.BasePath } |
        ForEach-Object {
            [pscustomobject]@{
                Name = [string]$_.DistributionName
                BasePath = [string]$_.BasePath
            }
        })
}

function Find-Distribution([object[]]$Available, [string]$Name) {
    return $Available | Where-Object { $_.Name -eq $Name -and $_.BasePath } | Select-Object -First 1
}

function Get-DistroIcon($Distro) {
    if (-not $Distro -or -not $Distro.BasePath) { return $null }

    $icon = [System.IO.Path]::Combine([string]$Distro.BasePath, 'shortcut.ico')
    if ($icon.StartsWith('\\?\')) {
        $icon = $icon.Substring(4)
    }
    if (-not [System.IO.File]::Exists($icon)) { return $null }

    return $icon -replace [regex]::Escape($env:LOCALAPPDATA), '%LOCALAPPDATA%'
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

function Set-ExistingProfileHidden($Settings, [string]$Guid, [bool]$Hidden) {
    $list = Get-ProfileList $Settings
    foreach ($profile in $list) {
        if ($profile.guid -eq $Guid) {
            Set-JsonProperty $profile 'hidden' $Hidden
            Set-ProfileList $Settings $list
            return
        }
    }
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

if ($PSBoundParameters.ContainsKey('Distributions')) {
    $availableDistributions = @($Distributions)
} else {
    $availableDistributions = @(Get-LxssDistributions)
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

Ensure-Profile $settings @{
    guid = $windowsPowerShellGuid
    name = 'Windows PowerShell'
    commandline = '%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe'
    hidden = $false
}

# Keep the dynamically discovered PowerShell 7 profile out of the Terminal UI.
Ensure-Profile $settings @{
    guid = $powerShellCoreGuid
    name = 'PowerShell'
    source = 'Windows.Terminal.PowershellCore'
    hidden = $true
}

foreach ($spec in $wslProfileSpecs) {
    $distro = Find-Distribution $availableDistributions $spec.Distro
    if ($distro) {
        Ensure-Profile $settings @{
            guid = $spec.Guid
            name = $spec.Name
            commandline = "wsl.exe -d $($spec.Distro)"
            startingDirectory = '~'
            icon = Get-DistroIcon $distro
            hidden = $false
        }
    } else {
        # Hide a stale managed profile, but do not create one for an absent distro.
        Set-ExistingProfileHidden $settings $spec.Guid $true
    }
}

$defaultProfile = $windowsPowerShellGuid
foreach ($spec in $wslProfileSpecs | Where-Object { $_.DefaultPriority -gt 0 } | Sort-Object DefaultPriority) {
    if (Find-Distribution $availableDistributions $spec.Distro) {
        $defaultProfile = $spec.Guid
        break
    }
}
Set-JsonProperty $settings 'defaultProfile' $defaultProfile

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
