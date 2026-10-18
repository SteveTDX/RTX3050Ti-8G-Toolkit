# task_install.ps1 - register / remove the logon power-profile task
# Works on Windows 10 and 11 (ScheduledTasks module, PowerShell 5.1).
param(
    [string]$Root = "",
    [switch]$Remove
)

$ErrorActionPreference = "Stop"
$taskName = "RTX3050Ti8G-PowerProfile"

if ([string]::IsNullOrEmpty($Root)) { $Root = Split-Path $PSScriptRoot -Parent }

if ($Remove) {
    $t = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($t) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Output "REMOVED=1"
    } else {
        Write-Output "REMOVED=0"
    }
    exit 0
}

$launcher = Join-Path $Root "setup\startup_launch.ps1"
$apply = Join-Path $Root "scripts\startup_apply.bat"
if (-not (Test-Path $apply)) {
    Write-Output "ERROR=missing startup_apply.bat"
    exit 1
}

$psExe = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
if (-not (Test-Path $psExe)) { $psExe = "powershell.exe" }

if (Test-Path $launcher) {
    $arg = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $launcher + '"'
} else {
    $arg = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "& ''' + $apply + '''"'
}

$action = New-ScheduledTaskAction -Execute $psExe -Argument $arg -WorkingDirectory $Root
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
try { $trigger.Delay = "PT30S" } catch { }

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 10)

Register-ScheduledTask -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -RunLevel Highest `
    -User $env:USERNAME `
    -Force | Out-Null

$t = Get-ScheduledTask -TaskName $taskName
$cmd = ""
if ($t -and $t.Actions.Count -gt 0) {
    $cmd = ([string]$t.Actions[0].Execute) + " " + ([string]$t.Actions[0].Arguments)
}
Write-Output "CREATED=1"
Write-Output "TASK_CMD=$cmd"
exit 0
