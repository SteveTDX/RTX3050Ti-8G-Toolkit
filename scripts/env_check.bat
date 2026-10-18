@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem env_check.bat - full check: preflight + startup task + saved profile
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0lib\common.bat"
call "%LIB%" init

call "%~dp0preflight.bat" --nopause
set "RC=%ERRORLEVEL%"

rem preflight already reported the logon task, including a stale path check,
rem so only the saved profile is added here.
echo.
call "%LIB%" msg M0379
call "%LIB%" probe
if exist "%CONFIG%\power_profile.txt" (
    set "PP="
    set /p PP=<"%CONFIG%\power_profile.txt"
    call "%LIB%" msg M0083
) else (
    call "%LIB%" msg M0084
)

echo.
call "%LIB%" msg M0085
call "%LIB%" msg M0086
call "%LIB%" msg M0087
call "%LIB%" msg M0088
if exist "%BACKUPS%" (
    set "BC=0"
    for %%F in ("%BACKUPS%\*.rom") do set /a BC+=1
    call "%LIB%" msg M0089
) else (
    call "%LIB%" msg M0090
)

echo.
call "%LIB%" msg M0091
if not "%RC%"=="0" call "%LIB%" msg M0092
echo.
pause
exit /b %RC%
