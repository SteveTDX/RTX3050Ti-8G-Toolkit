@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem startup_apply.bat - run by the scheduled task at logon
rem
rem Reads config\power_profile.txt and applies it. Never touches firmware.
rem Silent by design: every decision is written to logs\startup.log
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0lib\common.bat"
call "%LIB%" init
set "PLOG=%LOGS%\startup.log"

rem ---- rotate log at 256 KB ----
if exist "%PLOG%" for %%A in ("%PLOG%") do if %%~zA GTR 262144 move /y "%PLOG%" "%PLOG%.old" >nul 2>&1

if not exist "%CONFIG%\power_profile.txt" (
    call "%LIB%" log "%PLOG%" "no power_profile.txt, skip"
    exit /b 0
)

set "TARGET="
set /p TARGET=<"%CONFIG%\power_profile.txt"
set "TARGET=%TARGET: =%"
set "TARGET=%TARGET:W=%"
set "TARGET=%TARGET:w=%"
call "%LIB%" log "%PLOG%" "startup apply, target=!TARGET!"

if "%TARGET%"=="" (
    call "%LIB%" log "%PLOG%" "empty value, skip"
    exit /b 0
)
set "NONNUM="
for /f "delims=0123456789" %%a in ("%TARGET%") do set "NONNUM=%%a"
if defined NONNUM (
    call "%LIB%" log "%PLOG%" "invalid value '!TARGET!', skip"
    exit /b 0
)

rem ---- wait up to 90 s for driver + nvidia-smi ----
set /a TRIES=0
:smi_wait
call "%LIB%" find_smi
call "%LIB%" check_gpu
if "%GPU_FOUND%"=="0" goto :smi_ready
set /a TRIES+=1
if !TRIES! GTR 45 (
    call "%LIB%" log "%PLOG%" "GPU not ready after 90s, skip"
    exit /b 0
)
timeout /t 2 /nobreak >nul 2>&1
if errorlevel 1 ping -n 3 127.0.0.1 >nul 2>&1
goto :smi_wait

:smi_ready
call "%LIB%" power_csv
if not defined PWR_MAX_I (
    call "%LIB%" log "%PLOG%" "cannot read power limits, skip"
    exit /b 0
)
call "%LIB%" log "%PLOG%" "current default=!PWR_DEF! max=!PWR_MAX! min=!PWR_MIN!"

if !TARGET! GTR !PWR_MAX_I! (
    call "%LIB%" log "%PLOG%" "target !TARGET! exceeds max !PWR_MAX_I!, skip"
    exit /b 0
)
if !TARGET! LSS !PWR_MIN_I! (
    call "%LIB%" log "%PLOG%" "target !TARGET! below min !PWR_MIN_I!, skip"
    exit /b 0
)

nvidia-smi.exe -pl !TARGET! >>"%PLOG%" 2>&1
set "RC=!ERRORLEVEL!"

call "%LIB%" power_csv
if "!PWR_DEF_I!"=="!TARGET!" (
    call "%LIB%" log "%PLOG%" "applied !TARGET! W, readback ok"
) else (
    call "%LIB%" log "%PLOG%" "submit !TARGET! W rc=!RC! but readback !PWR_DEF_I! W (EC may reject)"
)
exit /b 0
