[CmdletBinding()]
param(
    [ValidateSet('Enable', 'Status', 'Disable')]
    [string]$Action = 'Enable'
)

$ErrorActionPreference = 'Stop'

if (-not $IsWindows -and $env:OS -ne 'Windows_NT') {
    throw 'This helper must be run on Windows.'
}

function Get-JoinStatus {
    $output = & "$env:SystemRoot\System32\dsregcmd.exe" /status 2>&1 | Out-String
    [pscustomobject]@{
        AzureAdJoined = $output -match '(?m)^\s*AzureAdJoined\s*:\s*YES\s*$'
        DomainJoined  = $output -match '(?m)^\s*DomainJoined\s*:\s*YES\s*$'
        Raw           = $output
    }
}

function Get-FidoPolicyState {
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Authentication',
        'HKLM:\SOFTWARE\Microsoft\Policies\PassportForWork\SecurityKey'
    )
    foreach ($path in $paths) {
        if (Test-Path $path) {
            $values = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
            foreach ($name in 'EnableFIDO2SecurityKey', 'UseSecurityKeyForSignin', 'Enabled') {
                if ($null -ne $values.$name) {
                    return [pscustomobject]@{ Found = $true; Name = $name; Value = $values.$name }
                }
            }
        }
    }
    [pscustomobject]@{ Found = $false; Name = ''; Value = $null }
}

function Show-Status {
    param($Join, $Policy)

    Write-Host "Microsoft Entra joined: $($Join.AzureAdJoined)"
    Write-Host "Active Directory domain joined: $($Join.DomainJoined)"
    if ($Policy.Found) {
        Write-Host "Detected security-key policy: $($Policy.Name) = $($Policy.Value)"
    } else {
        Write-Host 'Security-key sign-in policy: not detected locally (your administrator may still manage it remotely)'
    }
    Write-Host ''
    Write-Host 'Windows device sign-in with a FIDO2 security-key PIN is supported for Microsoft Entra joined or hybrid joined devices.'
    Write-Host 'It is not supported for a local Windows account or a personal Microsoft account.'
}

$join = Get-JoinStatus
$policy = Get-FidoPolicyState

if ($Action -eq 'Status') {
    Show-Status -Join $join -Policy $policy
    exit 0
}

if ($Action -eq 'Disable') {
    Write-Host 'Windows controls security-key registrations in protected Microsoft and Settings pages.'
    Write-Host 'Remove each registered key under Security info, and ask your administrator to disable security-key sign-in if required.'
    Start-Process 'https://mysignins.microsoft.com/security-info'
    Start-Process 'ms-settings:signinoptions'
    exit 0
}

Show-Status -Join $join -Policy $policy
if (-not $join.AzureAdJoined) {
    throw 'This computer is not Microsoft Entra joined, so Windows security-key PIN login cannot be enabled safely. No settings were changed.'
}

if (-not $policy.Found -or $policy.Value -notin 1, '1', $true) {
    Write-Warning 'The policy that allows security keys for Windows sign-in was not detected as enabled. Your Entra administrator may need to enable it first.'
}

Write-Host ''
Write-Host 'The protected registration pages will now open.'
Write-Host '1. In Security info, add Security key > USB device.'
Write-Host '2. Insert a YubiKey, set or enter its FIDO2 PIN, touch it, and give it a unique name.'
Write-Host '3. Repeat the registration for each YubiKey.'
Write-Host '4. At the Windows lock screen, choose Sign-in options > Security key.'
Write-Host ''
Write-Host 'Keep your password and Windows Hello recovery methods configured.'

Start-Process 'https://mysignins.microsoft.com/security-info'
Start-Process 'ms-settings:signinoptions'
