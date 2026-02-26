# ak - API Key Manager for PowerShell
# Uses Windows Credential Manager (no external dependencies)

$AK_DIR = "$env:USERPROFILE\tools\api-keys"
$SERVICES_DIR = "$AK_DIR\services"
$CRED_PREFIX = "ak:"  # Prefix for credential targets

# Use .NET to access Credential Manager (skip if already loaded)
if (-not ([System.Management.Automation.PSTypeName]'CredManager').Type) {
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class CredManager {
    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern bool CredRead(string target, int type, int flags, out IntPtr credential);

    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern bool CredWrite(ref CREDENTIAL credential, int flags);

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool CredDelete(string target, int type, int flags);

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern void CredFree(IntPtr credential);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct CREDENTIAL {
        public int Flags;
        public int Type;
        public string TargetName;
        public string Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public int CredentialBlobSize;
        public IntPtr CredentialBlob;
        public int Persist;
        public int AttributeCount;
        public IntPtr Attributes;
        public string TargetAlias;
        public string UserName;
    }

    public const int CRED_TYPE_GENERIC = 1;
    public const int CRED_PERSIST_LOCAL_MACHINE = 2;

    public static string Read(string target) {
        IntPtr credPtr;
        if (!CredRead(target, CRED_TYPE_GENERIC, 0, out credPtr)) {
            return null;
        }
        try {
            CREDENTIAL cred = (CREDENTIAL)Marshal.PtrToStructure(credPtr, typeof(CREDENTIAL));
            if (cred.CredentialBlobSize > 0) {
                return Marshal.PtrToStringUni(cred.CredentialBlob, cred.CredentialBlobSize / 2);
            }
            return "";
        } finally {
            CredFree(credPtr);
        }
    }

    public static bool Write(string target, string secret, string username) {
        byte[] byteArray = Encoding.Unicode.GetBytes(secret);
        CREDENTIAL cred = new CREDENTIAL();
        cred.Type = CRED_TYPE_GENERIC;
        cred.TargetName = target;
        cred.CredentialBlobSize = byteArray.Length;
        cred.CredentialBlob = Marshal.AllocHGlobal(byteArray.Length);
        Marshal.Copy(byteArray, 0, cred.CredentialBlob, byteArray.Length);
        cred.Persist = CRED_PERSIST_LOCAL_MACHINE;
        cred.UserName = username;
        try {
            return CredWrite(ref cred, 0);
        } finally {
            Marshal.FreeHGlobal(cred.CredentialBlob);
        }
    }

    public static bool Delete(string target) {
        return CredDelete(target, CRED_TYPE_GENERIC, 0);
    }
}
"@
}

function Get-AkSecret {
    param([string]$Service)
    
    $target = "$CRED_PREFIX$Service"
    $secret = [CredManager]::Read($target)
    
    if ($null -eq $secret) {
        Write-Error "No secret for: $Service"
        return
    }
    
    return $secret
}

function Set-AkSecret {
    param(
        [string]$Service,
        [string]$Value
    )
    
    if (-not $Value) {
        $secure = Read-Host "Enter secret for '$Service'" -AsSecureString
        $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        $Value = [Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
    
    $target = "$CRED_PREFIX$Service"
    $result = [CredManager]::Write($target, $Value, $Service)
    
    if ($result) {
        Write-Host "[OK] Stored: $Service" -ForegroundColor Green
    } else {
        Write-Error "Failed to store secret for: $Service"
    }
}

function Remove-AkSecret {
    param([string]$Service)
    
    $target = "$CRED_PREFIX$Service"
    $result = [CredManager]::Delete($target)
    
    if ($result) {
        Write-Host "[OK] Removed: $Service" -ForegroundColor Green
    } else {
        Write-Error "Failed to remove secret for: $Service (may not exist)"
    }
}

function Get-AkList {
    Write-Host "Configured services:"
    
    if (-not (Test-Path $SERVICES_DIR)) {
        Write-Host "  (no services directory)"
        return
    }
    
    Get-ChildItem "$SERVICES_DIR\*.yaml" -ErrorAction SilentlyContinue | ForEach-Object {
        $name = $_.BaseName
        $target = "$CRED_PREFIX$name"
        $hasSecret = $null -ne [CredManager]::Read($target)
        $mark = if ($hasSecret) { "[x]" } else { "[ ]" }
        Write-Host "  $mark $name"
    }
}

function Load-ApiKeys {
    if (-not (Test-Path $SERVICES_DIR)) {
        Write-Host "No services directory found" -ForegroundColor Yellow
        return
    }
    
    Get-ChildItem "$SERVICES_DIR\*.yaml" -ErrorAction SilentlyContinue | ForEach-Object {
        $name = $_.BaseName
        $target = "$CRED_PREFIX$name"
        $value = [CredManager]::Read($target)
        
        if ($null -ne $value) {
            $envVar = ($name -replace '-','_').ToUpper() + "_API_KEY"
            Set-Item -Path "env:$envVar" -Value $value
            Write-Host "[OK] Loaded $envVar" -ForegroundColor Green
        }
    }
}

# Aliases
Set-Alias -Name ak-get -Value Get-AkSecret
Set-Alias -Name ak-set -Value Set-AkSecret
Set-Alias -Name ak-rm -Value Remove-AkSecret
Set-Alias -Name ak-list -Value Get-AkList
Set-Alias -Name load-api-keys -Value Load-ApiKeys

Write-Host "ak (Windows Credential Manager) loaded. Commands: ak-get, ak-set, ak-rm, ak-list, load-api-keys" -ForegroundColor Cyan
