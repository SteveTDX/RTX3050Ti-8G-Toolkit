@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem remove_startup.bat -
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0..\scripts\lib\common.bat"
call "%LIB%" init

set "TASKNAME=RTX3050Ti8G-PowerProfile"

call "%LIB%" title "卸载开机启动项"
call "%LIB%" is_admin
if not "%ADMIN%"=="1" (
    call "%LIB%" err "需要管理员权限"
    echo   请右键本文件选择"以管理员身份运行"
    echo.
    pause
    exit /b 1
)

schtasks /query /tn "%TASKNAME%" >nul 2>&1
if errorlevel 1 (
    call "%LIB%" warn "未找到任务 %TASKNAME%, 无需卸载"
) else (
    schtasks /delete /tn "%TASKNAME%" /f
    if errorlevel 1 (
        call "%LIB%" err "卸载失败"
    ) else (
        call "%LIB%" ok "已卸载任务 %TASKNAME%"
    )
)
echo.
pause
