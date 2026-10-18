# probe.ps1 - hardware / OS probe for RTX3050Ti-8G-Toolkit
# Writes key=value lines (ASCII only) so cmd.exe can consume them safely.
# Works even when the NVIDIA driver is missing: PCI id and VRAM come from the registry.
param(
    [string]$Root = "",
    [string]$OutFile = ""
)

$ErrorActionPreference = "SilentlyContinue"

function Clean([string]$s) {
    if ([string]::IsNullOrEmpty($s)) { return "" }
    $t = $s -replace "[^\x20-\x7E]", ""
    $t = $t -replace "\s+", " "
    return $t.Trim()
}

$L = New-Object System.Collections.Generic.List[string]
function Add-Line([string]$k, [string]$v) {
    $script:L.Add("$k=" + (Clean $v))
}

# ---------------------------------------------------------------- OS
$os = Get-CimInstance Win32_OperatingSystem
$build = 0
[void][int]::TryParse([string]$os.BuildNumber, [ref]$build)
if ($build -ge 22000) { $family = "Windows 11" } else { $family = "Windows 10" }
$nt = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
$disp = [string]$nt.DisplayVersion
if ([string]::IsNullOrEmpty($disp)) { $disp = [string]$nt.ReleaseId }
$ubr = [string]$nt.UBR
Add-Line "OS_FAMILY"  $family
Add-Line "OS_BUILD"   $build
Add-Line "OS_DISPLAY" $disp
Add-Line "OS_VERSION" ([string]$os.Version)
Add-Line "OS_ARCH"    $env:PROCESSOR_ARCHITECTURE
Add-Line "OS_UBR"     $ubr
Add-Line "PS_VERSION" ([string]$PSVersionTable.PSVersion)
Add-Line "PS_EDITION" ([string]$PSVersionTable.PSEdition)

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) { Add-Line "IS_ADMIN" "1" } else { Add-Line "IS_ADMIN" "0" }

# ---------------------------------------------------------------- GPU
$gpuId = ""
$gname = ""
$gstatus = ""
$gerr = ""
$gpuObj = $null
$gpuPresent = 0

try {
    $cands = @(Get-PnpDevice -PresentOnly -ErrorAction Stop |
        Where-Object { $_.InstanceId -like "PCI\VEN_10DE&DEV_*" -and $_.Class -eq "Display" })
    if ($cands.Count -gt 0) { $gpuObj = $cands | Select-Object -First 1 }
} catch { }

if ($gpuObj) {
    $gpuId   = [string]$gpuObj.InstanceId
    $gname   = [string]$gpuObj.FriendlyName
    $gstatus = [string]$gpuObj.Status
    $gerr    = [string]$gpuObj.ProblemCode
    $gpuPresent = 1
} else {
    $vc = Get-CimInstance Win32_VideoController |
        Where-Object { $_.Name -match "NVIDIA" } | Select-Object -First 1
    if ($vc) {
        $gpuId = [string]$vc.PNPDeviceID
        $gname = [string]$vc.Name
        $gstatus = "OK"
        $gerr = "0"
        $gpuPresent = 1
    }
}

# registry fallback: works with no driver installed (device manager code 10/28/31)
if (-not $gpuPresent) {
    $enumRoot = "HKLM:\SYSTEM\CurrentControlSet\Enum\PCI"
    foreach ($k in (Get-ChildItem $enumRoot -ErrorAction SilentlyContinue)) {
        if ($k.PSChildName -notlike "VEN_10DE&DEV_*") { continue }
        foreach ($inst in (Get-ChildItem $k.PSPath -ErrorAction SilentlyContinue)) {
            $p = Get-ItemProperty $inst.PSPath
            $dd = [string]$p.DeviceDesc
            if ($dd -match "NVIDIA" -and $dd -notmatch "Audio") {
                $gpuId = [string]$k.PSChildName
                $gname = ($dd -split ";")[-1]
                $gerr = [string]$p.Problem
                if ($gerr -and $gerr -ne "0") { $gstatus = "Error" } else { $gstatus = "OK" }
                $gpuPresent = 1
                break
            }
        }
        if ($gpuPresent -eq 1) { break }
    }
}

$ven = ""
$dev = ""
$sub = ""
if ($gpuId -match "VEN_([0-9A-Fa-f]{4})") { $ven = $matches[1].ToUpper() }
if ($gpuId -match "DEV_([0-9A-Fa-f]{4})") { $dev = $matches[1].ToUpper() }
if ($gpuId -match "SUBSYS_([0-9A-Fa-f]{8})") { $sub = $matches[1].ToUpper() }
$idDisplay = $gpuId -replace "&", " "

Add-Line "GPU_PRESENT" $gpuPresent
Add-Line "GPU_ID"      $idDisplay
Add-Line "GPU_VEN"     $ven
Add-Line "GPU_DEV"     $dev
Add-Line "GPU_SUBSYS"  $sub
Add-Line "GPU_NAME"    $gname
Add-Line "GPU_STATUS"  $gstatus
Add-Line "GPU_ERRCODE" $gerr

# ---------------------------------------------------------------- VRAM (registry, driver independent)
$vramMB = 0
$cls = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
foreach ($k in (Get-ChildItem $cls -ErrorAction SilentlyContinue)) {
    $p = Get-ItemProperty $k.PSPath
    if ([string]$p.DriverDesc -notmatch "NVIDIA") { continue }
    $v = 0
    $q = $p."HardwareInformation.qwMemorySize"
    if ($null -ne $q) {
        try {
            if ($q -is [byte[]]) { $v = [BitConverter]::ToUInt64($q, 0) } else { $v = [uint64]$q }
        } catch { $v = 0 }
    }
    if ($v -eq 0) {
        $m = $p."HardwareInformation.MemorySize"
        if ($m -is [byte[]] -and $m.Length -ge 4) { $v = [uint64]([BitConverter]::ToUInt32($m, 0)) * 1MB }
    }
    $mb = [math]::Round($v / 1MB)
    if ($mb -gt $vramMB) { $vramMB = $mb }
}
Add-Line "GPU_VRAM_MB" $vramMB

# ---------------------------------------------------------------- driver
$vc2 = Get-CimInstance Win32_VideoController |
    Where-Object { $_.Name -match "NVIDIA" } | Select-Object -First 1
if ($vc2) {
    Add-Line "NVIDIA_DRIVER" ([string]$vc2.DriverVersion)
    Add-Line "NVIDIA_DRIVER_DATE" ([string]$vc2.DriverDate)
} else {
    Add-Line "NVIDIA_DRIVER" ""
    Add-Line "NVIDIA_DRIVER_DATE" ""
}

# ---------------------------------------------------------------- nvidia-smi
$smiCandidates = @(
    (Join-Path $env:SystemRoot "System32\nvidia-smi.exe"),
    (Join-Path $env:ProgramFiles "NVIDIA Corporation\NVSMI\nvidia-smi.exe")
)
$smi = ""
foreach ($c in $smiCandidates) {
    if (Test-Path $c) { $smi = $c; break }
}
if ([string]::IsNullOrEmpty($smi)) {
    $cmd = Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue
    if ($cmd) { $smi = [string]$cmd.Source }
}
Add-Line "SMI_PATH" $smi

# ---------------------------------------------------------------- scheduled task
$taskName = "RTX3050Ti8G-PowerProfile"
$taskExists = 0
$taskCmd = ""
try {
    $t = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
    if ($t) {
        $taskExists = 1
        $a = $t.Actions | Select-Object -First 1
        if ($a) { $taskCmd = ([string]$a.Execute) + " " + ([string]$a.Arguments) }
    }
} catch { }
Add-Line "TASK_EXISTS" $taskExists
Add-Line "TASK_CMD" $taskCmd

# ---------------------------------------------------------------- disk
if (-not [string]::IsNullOrEmpty($Root)) {
    $qual = Split-Path -Qualifier $Root
    if ($qual) {
        $driveLetter = $qual.TrimEnd(":")
        $drv = Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue
        if ($drv) {
            Add-Line "DISK_FREE_MB" ([math]::Round($drv.Free / 1MB))
            Add-Line "DISK_TOTAL_MB" ([math]::Round(($drv.Free + $drv.Used) / 1MB))
        }
    }
}

Add-Line "PROBE_OK" "1"

if (-not [string]::IsNullOrEmpty($OutFile)) {
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($OutFile, $L, $enc)
} else {
    $L | ForEach-Object { Write-Output $_ }
}
