# startup_launch.ps1 - hidden launcher used by the scheduled task
# Keeps the console window invisible and waits for the batch to finish.
$ErrorActionPreference = "SilentlyContinue"

$root = Split-Path $PSScriptRoot -Parent
$bat = Join-Path $root "scripts\startup_apply.bat"

if (-not (Test-Path $bat)) { exit 1 }

$p = Start-Process -FilePath $env:ComSpec `
    -ArgumentList "/c", ('"' + $bat + '"') `
    -WorkingDirectory $root `
    -WindowStyle Hidden `
    -PassThru

if ($p) { $p.WaitForExit(300000) | Out-Null }
exit 0
