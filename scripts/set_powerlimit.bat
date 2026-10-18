@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem set_powerlimit.bat - set runtime power limit and persist the profile
rem
rem   set_powerlimit.bat        interactive
rem   set_powerlimit.bat 70     non-interactive
rem   set_powerlimit.bat 0      reset to firmware default
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0lib\common.bat"
call "%LIB%" init

call "%LIB%" require_admin "%~f0" %1
if errorlevel 1 exit /b
call "%LIB%" is_admin
call "%LIB%" probe
call "%LIB%" find_smi
call "%LIB%" power_csv

call "%LIB%" title M0267

if not "%GPU_PRESENT%"=="1" (
    call "%LIB%" err M0268
    call "%LIB%" msg M0269
    echo.
    pause
    exit /b 1
)
if not defined PWR_MAX_I (
    call "%LIB%" err M0270
    call "%LIB%" msg M0271
    echo.
    pause
    exit /b 1
)

call "%LIB%" msg M0272
call "%LIB%" msg M0273
call "%LIB%" msg M0274
if "%GPU_VRAM_MB%"=="8192" call "%LIB%" msg M0275
echo.
call "%LIB%" msg M0276
echo.

set "TARGET=%~1"
if not defined TARGET (
    call "%LIB%" msgs M0277
    set /p TARGET=!MSGTXT!
)
if not defined TARGET set "TARGET=%PWR_DEF_I%"

rem ---- inline numeric validation: cross-file for /f is unreliable here ----
set "TARGET=%TARGET:W=%"
set "TARGET=%TARGET:w=%"
set "TARGET=%TARGET: =%"
set "NONNUM="
for /f "delims=0123456789" %%a in ("%TARGET%") do set "NONNUM=%%a"
if "%TARGET%"=="" (
    call "%LIB%" err M0278
    goto :fail
)
if defined NONNUM (
    call "%LIB%" err M0279
    goto :fail
)

if "%TARGET%"=="0" (
    set "TARGET=!PWR_DEF_I!"
    call "%LIB%" info M0280
)

if !TARGET! LSS !PWR_MIN_I! (
    call "%LIB%" err M0281
    goto :fail
)
if !TARGET! GTR !PWR_MAX_I! (
    call "%LIB%" err M0282
    call "%LIB%" msg M0283
    goto :fail
)

echo.
call "%LIB%" msg M0284
nvidia-smi.exe -pl !TARGET! 2>&1
set "APPLY_RC=!ERRORLEVEL!"

call "%LIB%" power_csv
set "OK=0"
if "!PWR_DEF_I!"=="!TARGET!" set "OK=1"

if "!OK!"=="1" (
    call "%LIB%" ok M0285
    > "%CONFIG%\power_profile.txt" echo !TARGET!
    call "%LIB%" log "%LOGS%\set_power.log" "power limit set to !TARGET! W, readback !PWR_DEF!"
) else (
    call "%LIB%" warn M0286
    call "%LIB%" msg M0287
    call "%LIB%" msg M0288
    call "%LIB%" msg M0289
    call "%LIB%" msg M0290
    call "%LIB%" msg M0291
    del /f /q "%CONFIG%\power_profile.txt" >nul 2>&1
)

echo.
call "%LIB%" msg M0292
goto :the_end

:fail
echo.
pause
exit /b 1

:the_end
echo.
pause
