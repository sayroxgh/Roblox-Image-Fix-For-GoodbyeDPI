<#
    Roblox CDN Fix
    --------------
    Some connections cannot resolve tr.rbxcdn.com (no A record returned), so
    Roblox pages load without avatars / thumbnails / icons.

    This script resolves a live CloudFront IP through t0.rbxcdn.com (which
    resolves normally), tests it, and maps tr.rbxcdn.com to it in the hosts file.

    Usage (must run as Administrator):
        RobloxCDNFix.ps1 -Mode Apply     # add or update the entry (default)
        RobloxCDNFix.ps1 -Mode Remove    # remove the entry
#>
param(
    [ValidateSet('Apply', 'Remove')]
    [string]$Mode = 'Apply'
)

$ErrorActionPreference = 'Stop'

$TargetHost = 'tr.rbxcdn.com'
$SourceHost = 't0.rbxcdn.com'
$DnsServer  = '1.1.1.1'
$Marker     = '# RobloxCDNFix'
$HostsPath  = Join-Path $env:WinDir 'System32\drivers\etc\hosts'
$LogPath    = Join-Path $PSScriptRoot 'RobloxCDNFix.log'

function Say([string]$Message, [string]$Color = 'Gray') {
    Write-Host $Message -ForegroundColor $Color
    try {
        if ((Test-Path $LogPath) -and ((Get-Item $LogPath).Length -gt 100KB)) { Remove-Item $LogPath -Force }
        Add-Content -Path $LogPath -Value ("{0} {1}" -f (Get-Date -Format 's'), $Message)
    } catch { }
}

trap {
    Say ("Error: " + $_.Exception.Message) 'Red'
    exit 1
}

# --- Administrator check -----------------------------------------------------
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Say 'Please run as Administrator.' 'Red'
    exit 2
}

# --- Helpers -----------------------------------------------------------------
# A hosts line is "ours" if it carries our marker, or is an active (non-comment)
# line that maps tr.rbxcdn.com. Nothing else in the file is ever touched.
function Test-Ours([string]$Line) {
    if ($Line -match [regex]::Escape($Marker)) { return $true }
    if ($Line -match '^\s*#') { return $false }
    return ($Line -match '(?i)(^|\s)tr\.rbxcdn\.com(\s|$)')
}

function Get-HostsLines {
    return [IO.File]::ReadAllLines($HostsPath)
}

function Write-Hosts([string[]]$Lines) {
    $utf8 = New-Object Text.UTF8Encoding($false)
    for ($i = 1; $i -le 6; $i++) {
        try {
            [IO.File]::WriteAllLines($HostsPath, $Lines, $utf8)
            return
        } catch {
            Start-Sleep -Milliseconds 700
        }
    }
    throw 'Could not write the hosts file (locked by another program or blocked by antivirus?).'
}

function Clear-Dns {
    ipconfig /flushdns | Out-Null
}

# Quick check: can we open a TLS connection to this IP and get an HTTP answer
# (any 1xx-5xx code, a 404 is fine) for tr.rbxcdn.com?
function Test-Ip([string]$Ip) {
    try {
        $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
        if (-not $curl) { return $true }   # cannot test, assume OK
        $code = & $curl.Source -s -o NUL -m 8 -w '%{http_code}' --resolve "${TargetHost}:443:$Ip" "https://$TargetHost/" 2>$null
        return ("$code" -match '^[1-5]\d\d$')
    } catch {
        return $false
    }
}

# --- Remove ------------------------------------------------------------------
if ($Mode -eq 'Remove') {
    $lines = @(Get-HostsLines)
    $kept  = @($lines | Where-Object { -not (Test-Ours $_) })
    if ($kept.Count -ne $lines.Count) {
        Write-Hosts $kept
        Clear-Dns
        Say "Removed the $TargetHost entry from the hosts file." 'Green'
    } else {
        Say 'Nothing to remove.' 'Yellow'
    }
    exit 0
}

# --- Apply -------------------------------------------------------------------
Say "Resolving $SourceHost via $DnsServer ..."
$ips = @()
try {
    $ips = @(Resolve-DnsName -Name $SourceHost -Server $DnsServer -Type A -DnsOnly -ErrorAction Stop |
             Where-Object { $_.Type -eq 'A' } |
             ForEach-Object { $_.IPAddress })
} catch {
    Say ("DNS lookup failed: " + $_.Exception.Message) 'Red'
}

if ($ips.Count -eq 0) {
    Say "Could not get a CDN IP. Check your connection and that $DnsServer is reachable." 'Red'
    exit 1
}

$lines   = @(Get-HostsLines)
$current = @($lines | Where-Object { Test-Ours $_ })

$chosen = $null
foreach ($ip in $ips) {
    if (Test-Ip $ip) { $chosen = $ip; break }
}

if (-not $chosen) {
    if ($current.Count -gt 0) {
        Say 'No IP passed the connection test (is GoodbyeDPI / Zapret running?). Keeping the existing entry.' 'Yellow'
        exit 1
    }
    $chosen = $ips[0]
    Say "No IP passed the connection test. Writing $chosen anyway - make sure your DPI tool is running." 'Yellow'
}

$entry = "$chosen $TargetHost $Marker"

if ($current.Count -eq 1 -and $current[0].Trim() -eq $entry) {
    Say "Already up to date: $TargetHost -> $chosen" 'Green'
    exit 0
}

$kept = @($lines | Where-Object { -not (Test-Ours $_) })
Write-Hosts ($kept + $entry)
Clear-Dns

Say "Done: $TargetHost -> $chosen" 'Green'
Say 'Fully close and reopen your browser (and Roblox) so the change is picked up.' 'Cyan'
exit 0
