@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem startup_apply.bat - ( , )
rem : - config\power_profile.txt -
rem : / / / ,
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0lib\common.bat"
call "%LIB%" init
set "PLOG=%LOGS%\startup.log"

if not exist "%CONFIG%\power_profile.txt" (
    call "%LIB%" log "%PLOG%" "no power_profile.txt, skip"
    exit /b 0
)
set "TARGET="
set /p TARGET=<"%CONFIG%\power_profile.txt"
set "TARGET=%TARGET: =%"
call "%LIB%" log "%PLOG%" "startup apply, target=!TARGET!"

rem ---- inline numeric validation ----
set "NONNUM="
for /f "delims=0123456789" %%a in ("%TARGET%") do set "NONNUM=%%a"
if defined NONNUM (
    call "%LIB%" log "%PLOG%" "invalid value, skip"
    exit /b 0
)

set /a TRIES=0
:SMI_WAIT
call "%LIB%" find_smi
call "%LIB%" check_gpu
if "%GPU_FOUND%"=="0" goto :smi_ready
set /a TRIES+=1
if !TRIES! gtr 30 (
    call "%LIB%" log "%PLOG%" "GPU not ready after 30 tries, skip"
    exit /b 0
)
timeout /t 2 /nobreak >nul
goto :SMI_WAIT

:smi_ready
call "%LIB%" power_csv
if not defined PWR_MAX (
    call "%LIB%" log "%PLOG%" "cannot read power limits, skip"
    exit /b 0
)
call "%LIB%" log "%PLOG%" "current default=!PWR_DEF! max=!PWR_MAX!"

if !TARGET! gtr !PWR_MAX! (
    call "%LIB%" log "%PLOG%" "target !TARGET! exceeds max !PWR_MAX!, skip"
    exit /b 0
)
if !TARGET! lss 1 (
    call "%LIB%" log "%PLOG%" "target !TARGET! below 1, skip"
    exit /b 0
)

"%SMI%" -pl !TARGET! >>"%PLOG%" 2>&1
call "%LIB%" log "%PLOG%" "apply done rc=!ERRORLEVEL!"
exit /b 0
