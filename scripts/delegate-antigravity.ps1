#Requires -Version 5.1
<#
.SYNOPSIS
  Run an Antigravity CLI (agy) task from a brief — headless, Google account auth.

.PARAMETER BriefPath
  Path to brief file (UTF-8).

.PARAMETER Brief
  Brief string (alternative to BriefPath).

.PARAMETER Model
  Model name from `agy models`. Default: Gemini 3.5 Flash (Low)

.PARAMETER Dir
  Working directory. Default: current location.

.PARAMETER Sandbox
  Enable --sandbox.

.PARAMETER Continue
  Resume latest conversation (--continue / -c).

.PARAMETER PrintTimeout
  --print-timeout value. Default: 25m

.PARAMETER TimeoutMinutes
  Outer process kill. Default: 30 (must exceed print timeout).

.PARAMETER CheckAuth
  Verify agy credentials exist. Default: true

.PARAMETER TrustWorkspace
  Add -Dir to trustedWorkspaces in settings.json if missing. Default: true

.PARAMETER ShowConsole
  Launch agy in a new console (TTY) so -p can render. Default: true

.EXAMPLE
  delegate-antigravity -BriefPath .\brief.txt -Dir F:\repo

.EXAMPLE
  delegate-antigravity -Brief "Add tests. Do not commit." -Model "Gemini 3.1 Pro (High)"
#>
[CmdletBinding()]
param(
  [string]$BriefPath,
  [string]$Brief,
  [string]$Model = "Gemini 3.5 Flash (Low)",
  [string]$Dir = (Get-Location).Path,
  [switch]$Sandbox,
  [switch]$Continue,
  [string]$PrintTimeout = "25m",
  [int]$TimeoutMinutes = 30,
  [switch]$CheckAuth = $true,
  [switch]$TrustWorkspace = $true,
  [switch]$ShowConsole = $true
)

$ErrorActionPreference = "Stop"

function Write-DelegateError {
  param([string]$Message)
  Write-Error $Message
  exit 1
}

function Get-AgyExe {
  $cmd = Get-Command agy -ErrorAction SilentlyContinue
  if ($cmd -and $cmd.Source -match '\.exe$') { return $cmd.Source }
  $fallback = Join-Path $env:LOCALAPPDATA "agy\bin\agy.exe"
  if (Test-Path -LiteralPath $fallback) { return $fallback }
  Write-DelegateError "agy not found. Install: irm https://antigravity.google/cli/install.ps1 | iex"
}

function Test-AntigravityAuth {
  try {
    $credList = & cmdkey /list 2>&1 | Out-String
    if ($credList -match 'gemini:antigravity') { return $true }
  } catch { }

  $tokenPaths = @(
    (Join-Path $env:LOCALAPPDATA "antigravity-cli\antigravity-oauth-token"),
    (Join-Path $env:USERPROFILE ".gemini\antigravity-cli\antigravity-oauth-token")
  )
  foreach ($p in $tokenPaths) {
    if (Test-Path -LiteralPath $p) { return $true }
  }
  return $false
}

function Get-AgySettingsPath {
  return Join-Path $env:USERPROFILE ".gemini\antigravity-cli\settings.json"
}

function Ensure-AgyTrustedWorkspace {
  param([string]$WorkspacePath)

  $normalized = (Resolve-Path -LiteralPath $WorkspacePath).Path
  $settingsPath = Get-AgySettingsPath
  $settingsDir = Split-Path -Parent $settingsPath
  if (-not (Test-Path -LiteralPath $settingsDir)) {
    New-Item -ItemType Directory -Force -Path $settingsDir | Out-Null
  }

  $trusted = @()
  if (Test-Path -LiteralPath $settingsPath) {
    try {
      $parsed = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
      if ($parsed.trustedWorkspaces) { $trusted = @($parsed.trustedWorkspaces) }
    } catch {
      $trusted = @()
    }
  }

  if ($trusted -notcontains $normalized) {
    $trusted += $normalized
    $obj = [pscustomobject]@{ trustedWorkspaces = $trusted }
    ($obj | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $settingsPath -Encoding UTF8
    Write-Host "  trusted workspace: $normalized" -ForegroundColor DarkGray
  }
}

function Build-AgyArgumentString {
  param([string[]]$ArgumentValues)
  ($ArgumentValues | ForEach-Object {
    if ($null -eq $_) { return '""' }
    if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ }
  }) -join ' '
}

$hasPath = -not [string]::IsNullOrWhiteSpace($BriefPath)
$hasBrief = -not [string]::IsNullOrWhiteSpace($Brief)
if ($hasPath -and $hasBrief) {
  Write-DelegateError "Use either -BriefPath or -Brief, not both."
}
if (-not $hasPath -and -not $hasBrief) {
  Write-DelegateError "Missing brief. Run: delegate-antigravity -Brief `"task`""
}

if ($TimeoutMinutes -lt 1) {
  Write-DelegateError "TimeoutMinutes must be at least 1."
}

if (-not (Test-Path -LiteralPath $Dir -PathType Container)) {
  Write-DelegateError "Directory not found: $Dir"
}
$workDir = (Resolve-Path -LiteralPath $Dir).Path

if ($hasPath) {
  if (-not (Test-Path -LiteralPath $BriefPath -PathType Leaf)) {
    Write-DelegateError "Brief file not found: $BriefPath"
  }
  $briefText = Get-Content -LiteralPath $BriefPath -Raw -Encoding UTF8
  if ([string]::IsNullOrWhiteSpace($briefText)) {
    Write-DelegateError "Brief file is empty: $BriefPath"
  }
} else {
  $briefText = $Brief.Trim()
}

if ($CheckAuth -and -not (Test-AntigravityAuth)) {
  Write-DelegateError @(
    "Antigravity Google OAuth not found.",
    "Run `agy` interactively and complete Google OAuth sign-in.",
    "See antigravity-delegate: references/authentication.md"
  ) -join " "
}

if ($TrustWorkspace) {
  Ensure-AgyTrustedWorkspace -WorkspacePath $workDir
}

$agyExe = Get-AgyExe
$timeoutMs = $TimeoutMinutes * 60 * 1000
$useStdin = $briefText.Length -gt 7000
$stdinAnchor = "Execute the task provided on stdin. Follow all instructions exactly. Do not commit unless explicitly asked."
$promptText = if ($useStdin) { $stdinAnchor } else { $briefText }

Write-Host "Antigravity delegate: model=$Model dir=$workDir print-timeout=$PrintTimeout outer-timeout=${TimeoutMinutes}m" -ForegroundColor Cyan
if ($Continue) { Write-Host "  continue=latest" -ForegroundColor Cyan }

$argumentList = @()
if ($Continue) { $argumentList += "--continue" }
$argumentList += @(
  "-p", $promptText,
  "--model", $Model,
  "--print-timeout", $PrintTimeout,
  "--dangerously-skip-permissions"
)
if ($Sandbox) { $argumentList += "--sandbox" }

try {
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $agyExe
  $psi.WorkingDirectory = $workDir
  $psi.UseShellExecute = $false
  $psi.RedirectStandardInput = $true
  $psi.RedirectStandardOutput = $false
  $psi.RedirectStandardError = $false
  $psi.CreateNoWindow = -not $ShowConsole
  $psi.Arguments = Build-AgyArgumentString -ArgumentValues $argumentList

  $proc = [System.Diagnostics.Process]::Start($psi)
  if ($useStdin) {
    $proc.StandardInput.Write($briefText)
  }
  $proc.StandardInput.Close()

  if (-not $proc.WaitForExit($timeoutMs)) {
    try { $proc.Kill($true) } catch { }
    Write-Host "Antigravity timed out after $TimeoutMinutes minute(s). Check log: $env:USERPROFILE\.gemini\antigravity-cli\log\" -ForegroundColor Red
    exit 124
  }

  if ($proc.ExitCode -ne 0) {
    Write-Host "Antigravity exited with code $($proc.ExitCode). See log: $env:USERPROFILE\.gemini\antigravity-cli\log\" -ForegroundColor Red
    exit $proc.ExitCode
  }

  Write-Host "Antigravity finished successfully. Review git diff before committing." -ForegroundColor Green
  exit 0
} catch {
  Write-DelegateError "Failed to start Antigravity: $($_.Exception.Message)"
}
