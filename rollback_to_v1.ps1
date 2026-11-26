<#
.SYNOPSIS
    Roll back TreeForge frontend to Checkpoint v1 (Noir Developer-Tool UI).
.EXAMPLE
    .\rollback_to_v1.ps1
#>
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Checkpoint = Join-Path $Root "checkpoints\v1-noir\frontend"
$Target = Join-Path $Root "frontend"

if (-not (Test-Path $Checkpoint)) {
    Write-Error "Checkpoint not found at $Checkpoint"
    exit 1
}

if (Test-Path $Target) {
    Remove-Item -Path $Target -Recurse -Force
}

Copy-Item -Path $Checkpoint -Destination $Target -Recurse -Force
Write-Host "Rolled back TreeForge frontend to v1 (Noir). Refresh http://127.0.0.1:5000 in your browser." -ForegroundColor Green
