@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem menu.bat - main entry point
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0scripts\lib\common.bat"
call "%LIB%" init

:menu
cls
call "%LIB%" probe
call "%LIB%" find_smi
call "%LIB%" power_csv

call "%LIB%" title M0029

call "%LIB%" msg M0030
if "%IS_ADMIN%"=="1" (
    call "%LIB%" msg M0374
) else (
    call "%LIB%" msg M0375
)
if "%GPU_PRESENT%"=="1" (
    call "%LIB%" msg M0031
    call "%LIB%" msg M0032
    if defined PWR_DEF (
        call "%LIB%" msg M0033
    )
) else (
    call "%LIB%" msg M0034
)
echo.
call "%LIB%" msg M0035
call "%LIB%" msg M0036
call "%LIB%" msg M0037
call "%LIB%" msg M0038
call "%LIB%" msg M0039
call "%LIB%" msg M0040
call "%LIB%" msg M0041
call "%LIB%" msg M0042
call "%LIB%" msg M0043
call "%LIB%" msg M0044
call "%LIB%" msg M0045
call "%LIB%" msg M0046
echo.

set "CH="
call "%LIB%" msgs M0047
set /p CH=!MSGTXT!
if /i "!CH!"=="1" (call "%ROOT%\scripts\env_check.bat" & goto :menu)
if /i "!CH!"=="2" (call "%ROOT%\scripts\status.bat" & goto :menu)
if /i "!CH!"=="3" (call "%ROOT%\scripts\set_powerlimit.bat" & goto :menu)
if /i "!CH!"=="4" (call "%ROOT%\scripts\flash_80w.bat" & goto :menu)
if /i "!CH!"=="5" (call "%ROOT%\scripts\flash_60w.bat" & goto :menu)
if /i "!CH!"=="6" (call "%ROOT%\scripts\backup_vbios.bat" & goto :menu)
if /i "!CH!"=="7" (call "%ROOT%\scripts\restore_backup.bat" & goto :menu)
if /i "!CH!"=="8" (call "%ROOT%\setup\install_startup.bat" & goto :menu)
if /i "!CH!"=="9" (call "%ROOT%\setup\remove_startup.bat" & goto :menu)
if /i "!CH!"=="V" (call "%ROOT%\scripts\verify.bat" & goto :menu)
if /i "!CH!"=="B" (call "%ROOT%\bootstrap.bat" & goto :menu)
if "!CH!"=="0" goto :bye
goto :menu

:bye
echo.
call "%LIB%" msg M0048
exit /b 0
