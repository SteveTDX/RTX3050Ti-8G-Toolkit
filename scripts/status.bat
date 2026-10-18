@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem status.bat - current GPU state (works without admin, degrades without driver)
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0lib\common.bat"
call "%LIB%" init

call "%LIB%" title M0293
call "%LIB%" probe
call "%LIB%" find_smi
call "%LIB%" power_csv

if not "%PROBE_OK%"=="1" (
    call "%LIB%" warn M0294
    call "%LIB%" check_gpu
    set "GPU_PRESENT=0"
    if "%GPU_FOUND%"=="0" set "GPU_PRESENT=1"
)

if not "%GPU_PRESENT%"=="1" (
    call "%LIB%" err M0295
    echo.
    call "%LIB%" msg M0296
    call "%LIB%" msg M0297
    echo.
    pause
    exit /b 1
)

call "%LIB%" msg M0298
call "%LIB%" msg M0299
call "%LIB%" msg M0300
call "%LIB%" msg M0301
if not "!GPU_ERRCODE!"=="" if not "!GPU_ERRCODE!"=="0" (
    call "%LIB%" msg M0302
)
if "%GPU_VRAM_MB%"=="0" (
    call "%LIB%" msg M0303
) else (
    call "%LIB%" msg M0304
)
echo.

if "%NVIDIA_DRIVER%"=="" (
    call "%LIB%" warn M0305
    call "%LIB%" msg M0306
    call "%LIB%" msg M0307
    call "%LIB%" msg M0308
    echo.
    pause
    exit /b 2
)

call "%LIB%" msg M0309
if defined PWR_DEF (
    call "%LIB%" msg M0310
    call "%LIB%" msg M0311
    call "%LIB%" msg M0312
) else (
    call "%LIB%" msg M0313
)
echo.

for /f "tokens=1-7 delims=," %%a in ('nvidia-smi.exe --query-gpu=memory.total^,clocks.max.sm^,clocks.max.memory^,temperature.gpu^,utilization.gpu^,driver_version^,vbios_version --format=csv^,noheader 2^>nul') do (
    call "%LIB%" trim V1 "%%a"
    call "%LIB%" trim V2 "%%b"
    call "%LIB%" trim V3 "%%c"
    call "%LIB%" trim V4 "%%d"
    call "%LIB%" trim V5 "%%e"
    call "%LIB%" trim V6 "%%f"
    call "%LIB%" trim V7 "%%g"
    call "%LIB%" msg M0314 "!V1!"
    call "%LIB%" msg M0315 "!V2!"
    call "%LIB%" msg M0316 "!V3!"
    call "%LIB%" msg M0317 "!V4!"
    call "%LIB%" msg M0318 "!V5!"
    call "%LIB%" msg M0319 "!V6!"
    call "%LIB%" msg M0320 "!V7!"
)

echo.
call "%LIB%" machine_profile
if "%PROFILE_STATE%"=="changed" (
    call "%LIB%" warn M0321
    call "%LIB%" msg M0322
) else if "%PROFILE_STATE%"=="new" (
    call "%LIB%" info M0323
)

echo.
call "%LIB%" msg M0324
echo.
pause
