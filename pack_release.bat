@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem pack_release.bat - build dist\RTX3050Ti-8G-Toolkit_v<ver>_win-x64.zip
rem
rem Normalises line endings, strips BOM, writes SHA256SUMS.txt and prints the
rem archive hash. Requires PowerShell 5.1 (built into Windows 10/11).
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0scripts\lib\common.bat"
call "%LIB%" init

set "CI=0"
if /i "%~1"=="--ci" set "CI=1"

call "%LIB%" title M0049

if not exist "%ROOT%\scripts\lib\pack.ps1" (
    call "%LIB%" err M0050
    echo.
    if "%CI%"=="0" pause
    exit /b 1
)

where powershell.exe >nul 2>&1
if errorlevel 1 (
    call "%LIB%" err M0051
    call "%LIB%" msg M0052
    echo.
    if "%CI%"=="0" pause
    exit /b 1
)

call "%LIB%" msg M0053
call "%LIB%" msg M0054
echo.
call "%LIB%" msg M0055
call "%ROOT%\scripts\verify.bat" --pack-mode
if errorlevel 1 (
    call "%LIB%" err M0056
    echo.
    if "%CI%"=="0" pause
    exit /b 1
)

echo.
call "%LIB%" msg M0057
set "PSOUT=%LOGS%\pack_result.txt"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\scripts\lib\pack.ps1" -Root "%ROOT%" -Version "%VER%" >"%PSOUT%" 2>&1
set "PRC=%ERRORLEVEL%"

if not "%PRC%"=="0" (
    call "%LIB%" err M0058
    call "%LIB%" msg M0059
    type "%PSOUT%"
    echo.
    if "%CI%"=="0" pause
    exit /b 1
)

set "ZIP="
set "ZIP_SIZE="
set "ZIP_HASH="
for /f "usebackq tokens=1,* delims==" %%a in ("%PSOUT%") do (
    if /i "%%a"=="ZIP" set "ZIP=%%b"
    if /i "%%a"=="ZIP_SIZE" set "ZIP_SIZE=%%b"
    if /i "%%a"=="ZIP_SHA256" set "ZIP_HASH=%%b"
)

call "%LIB%" ok M0060
call "%LIB%" msg M0061
call "%LIB%" msg M0062
echo   SHA256        : !ZIP_HASH!
echo.
call "%LIB%" msg M0063
call "%LIB%" msg M0064
call "%LIB%" msg M0065
call "%LIB%" msg M0066
echo.
call "%LIB%" log "%LOGS%\pack.log" "packed !ZIP! size=!ZIP_SIZE! sha256=!ZIP_HASH!"
if "%CI%"=="0" pause
exit /b 0
