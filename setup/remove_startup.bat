@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem remove_startup.bat - remove the logon scheduled task
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0..\scripts\lib\common.bat"
call "%LIB%" init

call "%LIB%" title M0368
call "%LIB%" is_admin
if not "%ADMIN%"=="1" (
    call "%LIB%" err M0369
    call "%LIB%" msg M0370
    echo.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\setup\task_install.ps1" -Root "%ROOT%" -Remove >"%LOGS%\remove_startup.txt" 2>&1
set "RC=%ERRORLEVEL%"

call "%LIB%" probe
if "%TASK_EXISTS%"=="0" (
    call "%LIB%" ok M0371
    goto :the_end
)
schtasks /delete /tn "RTX3050Ti8G-PowerProfile" /f >>"%LOGS%\remove_startup.txt" 2>&1
if errorlevel 1 (
    call "%LIB%" err M0372
) else (
    call "%LIB%" ok M0373
)

:the_end
echo.
pause
