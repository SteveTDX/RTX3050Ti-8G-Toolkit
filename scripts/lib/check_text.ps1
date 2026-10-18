# check_text.ps1 - verify batch file encoding/newlines and repo integrity
# Outputs PASS/FAIL lines and a final RESULT=ok|bad
param(
    [string]$Root = "",
    [string]$OutFile = ""
)

$ErrorActionPreference = "SilentlyContinue"
$L = New-Object System.Collections.Generic.List[string]
$bad = 0

function Add([string]$s) { $script:L.Add($s) }

if ([string]::IsNullOrEmpty($Root)) { $Root = (Get-Location).Path }

$batFiles = @(Get-ChildItem -Path $Root -Recurse -Filter *.bat -File |
    Where-Object { $_.FullName -notmatch "\\\.git\\" -and $_.FullName -notmatch "\\dist\\" -and $_.FullName -notmatch "\\logs\\" })

Add "BAT_COUNT=$($batFiles.Count)"
foreach ($f in $batFiles) {
    $rel = $f.FullName.Substring($Root.Length).TrimStart("\")
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        Add "BAD=BOM $rel"
        $bad++
        continue
    }
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    $lf = [regex]::Matches($text, "(?<!`r)`n").Count
    if ($lf -gt 0) {
        Add "BAD=LF($lf) $rel"
        $bad++
        continue
    }
    $lines = $text -split "`r`n"
    $remCn = $false
    foreach ($ln in $lines) {
        if ($ln -match "^\s*rem\b" -and $ln -match "[^\x00-\x7F]") { $remCn = $true; break }
    }
    if ($remCn) {
        Add "BAD=REM-NON-ASCII $rel"
        $bad++
        continue
    }
    Add "OK=$rel"
}

# non-batch text files should not contain a BOM either
foreach ($ext in @("*.md", "*.txt", "*.ps1")) {
    foreach ($f in (Get-ChildItem -Path $Root -Recurse -Filter $ext -File |
        Where-Object { $_.FullName -notmatch "\\\.git\\" -and $_.FullName -notmatch "\\dist\\" -and $_.FullName -notmatch "\\logs\\" })) {
        $b = [System.IO.File]::ReadAllBytes($f.FullName)
        if ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) {
            $rel = $f.FullName.Substring($Root.Length).TrimStart("\")
            Add "BAD=BOM $rel"
            $bad++
        }
    }
}

if ($bad -eq 0) { Add "RESULT=ok" } else { Add "RESULT=bad" }
Add "BAD_COUNT=$bad"

$enc = New-Object System.Text.UTF8Encoding($false)
if (-not [string]::IsNullOrEmpty($OutFile)) {
    [System.IO.File]::WriteAllLines($OutFile, $L, $enc)
} else {
    $L | ForEach-Object { Write-Output $_ }
}
