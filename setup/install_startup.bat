@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem install_startup.bat - create / repair the logon scheduled task
rem
rem The task runs setup\startup_launch.ps1 with a hidden window, which applies
rem config\power_profile.txt after the driver is ready. Re-running the script
rem repairs a task whose path points to an old folder (e.g. after moving the
rem toolkit to another drive or machine).
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0..\scripts\lib\common.bat"
call "%LIB%" init

set "TASKNAME=RTX3050Ti8G-PowerProfile"
set "APPLY=%ROOT%\scripts\startup_apply.bat"

call "%LIB%" title M0346
call "%LIB%" is_admin
if not "%ADMIN%"=="1" (
    call "%LIB%" err M0347
    call "%LIB%" msg M0348
    echo.
    pause
    exit /b 1
)

if not exist "%APPLY%" (
    call "%LIB%" err M0349
    echo.
    pause
    exit /b 1
)
if not exist "%ROOT%\config\power_profile.txt" (
    call "%LIB%" warn M0350
    call "%LIB%" msg M0351
    echo.
)

call "%LIB%" msg M0352
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\setup\task_install.ps1" -Root "%ROOT%" >"%LOGS%\install_startup.txt" 2>&1
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
    call "%LIB%" warn M0353
    schtasks /create /tn "%TASKNAME%" /tr "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%ROOT%\setup\startup_launch.ps1\"" /sc onlogon /rl highest /f >>"%LOGS%\install_startup.txt" 2>&1
    if errorlevel 1 (
        call "%LIB%" err M0354
        call "%LIB%" msg M0355
        echo.
        pause
        exit /b 1
    )
)

call "%LIB%" probe
if not "%TASK_EXISTS%"=="1" (
    call "%LIB%" err M0356
    echo.
    pause
    exit /b 1
)

call "%LIB%" ok M0357
echo.
call "%LIB%" msg M0358
call "%LIB%" msg M0359
call "%LIB%" msg M0360
call "%LIB%" msg M0361
call "%LIB%" msg M0362
echo.
call "%LIB%" msg M0363
call "%LIB%" msg M0364
call "%LIB%" msg M0365
call "%LIB%" msg M0366
echo.
call "%LIB%" msg M0367
echo.
pause
exit /b 0
