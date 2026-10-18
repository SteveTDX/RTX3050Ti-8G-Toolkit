# pack.ps1 - build a clean, self-contained release archive
# Usage: powershell -File pack.ps1 -Root <repo> -Version <x.y.z>
param(
    [string]$Root = "",
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrEmpty($Root)) { $Root = Split-Path $PSScriptRoot -Parent }
if ([string]::IsNullOrEmpty($Version)) {
    $Version = (Get-Content (Join-Path $Root "VERSION") -Raw).Trim()
}

$distRoot = Join-Path $Root "dist"
$stageRoot = Join-Path $distRoot "stage"
$appName = "RTX3050Ti-8G-Toolkit"
$stage = Join-Path $stageRoot $appName

if (Test-Path $stageRoot) { Remove-Item $stageRoot -Recurse -Force }
New-Item -ItemType Directory -Path $stage -Force | Out-Null

$files = @("README.md", "LICENSE", "VERSION", "menu.bat", "bootstrap.bat", "pack_release.bat")
$dirs = @("scripts", "setup", "roms", "tools", "docs", "config", "lang")

foreach ($f in $files) {
    $src = Join-Path $Root $f
    if (Test-Path $src) { Copy-Item $src -Destination $stage -Force }
}
foreach ($d in $dirs) {
    $src = Join-Path $Root $d
    if (Test-Path $src) {
        Copy-Item $src -Destination $stage -Recurse -Force
    }
}

# strip runtime-only artefacts from the package
$runtime = @(
    "logs\*.log",
    "logs\probe*.txt",
    "config\power_profile.txt",
    "config\machine_profile.txt",
    "backups\*.rom"
)
foreach ($p in $runtime) {
    Get-ChildItem -Path (Join-Path $stage $p) -File -ErrorAction SilentlyContinue |
        Remove-Item -Force
}
# keep empty runtime folders with a placeholder
foreach ($d in @("logs", "backups")) {
    $full = Join-Path $stage $d
    if (-not (Test-Path $full)) { New-Item -ItemType Directory -Path $full -Force | Out-Null }
    $keep = Join-Path $full ".gitkeep"
    if (-not (Test-Path $keep)) { New-Item -ItemType File -Path $keep | Out-Null }
}

# ---------------------------------------------------------------- normalise text
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$crlfExt = @(".bat", ".cmd", ".ps1", ".txt")
$allText = @(Get-ChildItem -Path $stage -Recurse -File |
    Where-Object { $crlfExt -contains $_.Extension.ToLower() })

foreach ($f in $allText) {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    if ($text.Length -gt 0 -and $text[0] -eq [char]0xFEFF) { $text = $text.Substring(1) }
    $text = $text -replace "`r`n", "`n"
    $text = $text -replace "`r", "`n"
    $text = $text -replace "`n", "`r`n"
    [System.IO.File]::WriteAllText($f.FullName, $text, $utf8NoBom)
}

# ---------------------------------------------------------------- manifest
$hashFiles = @(Get-ChildItem -Path $stage -Recurse -File |
    Where-Object { $_.Extension.ToLower() -in @(".exe", ".rom", ".bat", ".ps1") })

$manifest = New-Object System.Collections.Generic.List[string]
foreach ($f in ($hashFiles | Sort-Object FullName)) {
    $rel = $f.FullName.Substring($stage.Length).TrimStart("\") -replace "\\", "/"
    $hash = (Get-FileHash -Path $f.FullName -Algorithm SHA256).Hash.ToLower()
    $manifest.Add("$hash  $rel")
}
$manifestPath = Join-Path $stage "SHA256SUMS.txt"
[System.IO.File]::WriteAllLines($manifestPath, $manifest, $utf8NoBom)

# ---------------------------------------------------------------- archive
$zipName = "${appName}_v${Version}_win-x64.zip"
$zipPath = Join-Path $distRoot $zipName
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

# ZipFile::CreateFromDirectory writes backslash separators on .NET Framework,
# which breaks unzip on Linux/macOS. Build the archive entry by entry so every
# entry name uses a forward slash.
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in (Get-ChildItem -Path $stage -Recurse -File -Force)) {
        $rel = $file.FullName.Substring($stage.Length).TrimStart([char]92, [char]47)
        $entryName = $appName + "/" + ($rel -replace '\\', '/')
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $zip, $file.FullName, $entryName,
            [System.IO.Compression.CompressionLevel]::Optimal)
    }
} finally {
    $zip.Dispose()
}

$zipHash = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash.ToLower()
$zipSize = (Get-Item $zipPath).Length
$sumLine = "$zipHash  $zipName"
[System.IO.File]::WriteAllLines((Join-Path $distRoot "SHA256SUMS.txt"), @($sumLine), $utf8NoBom)

Write-Output "PACK_OK=1"
Write-Output "VERSION=$Version"
Write-Output "ZIP=$zipPath"
Write-Output "ZIP_SIZE=$zipSize"
Write-Output "ZIP_SHA256=$zipHash"
Write-Output "FILES=$($manifest.Count)"
