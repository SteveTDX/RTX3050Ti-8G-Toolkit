@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem install_startup.bat -
rem RTX3050Ti8G-PowerProfile : 30 ,
rem scripts\startup_apply.bat, config\power_profile.txt
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0..\scripts\lib\common.bat"
call "%LIB%" init

set "TASKNAME=RTX3050Ti8G-PowerProfile"
set "TARGET=%ROOT%\scripts\startup_apply.bat"
set "LOG=%LOGS%\install_startup.log"

call "%LIB%" title "安装开机启动项"
call "%LIB%" is_admin
if not "%ADMIN%"=="1" (
    call "%LIB%" err "需要管理员权限创建计划任务"
    echo   请右键本文件选择"以管理员身份运行"
    echo.
    pause
    exit /b 1
)

if not exist "%TARGET%" (
    call "%LIB%" err "找不到 %TARGET%"
    goto :fail
)
if not exist "%CONFIG%\power_profile.txt" (
    call "%LIB%" warn "尚未设置功耗配置, 建议先运行 scripts\set_powerlimit.bat"
)

schtasks /query /tn "%TASKNAME%" >nul 2>&1
if not errorlevel 1 (
    echo   已存在同名任务, 将覆盖...
    schtasks /delete /tn "%TASKNAME%" /f >nul 2>&1
)

echo   正在创建计划任务...
schtasks /create /tn "%TASKNAME%" /tr "\"%TARGET%\"" /sc onlogon /rl highest /delay 0000:30 /f >"%LOG%" 2>&1
if errorlevel 1 (
    echo   带延迟创建失败, 尝试不带延迟...
    schtasks /create /tn "%TASKNAME%" /tr "\"%TARGET%\"" /sc onlogon /rl highest /f >>"%LOG%" 2>&1
    if errorlevel 1 (
        call "%LIB%" err "创建失败, 请查看 logs\install_startup.log"
        goto :fail
    )
)

call "%LIB%" ok "开机启动项安装完成"
echo.
echo   任务名称  : %TASKNAME%
echo   执行脚本  : %TARGET%
echo   配置文件  : config\power_profile.txt
echo   应用日志  : logs\startup.log
echo.
echo   说明: 仅当配置文件存在且数值合法时才会执行设置
echo         驱动未就绪会自动等待重试, 不会修改固件
echo   卸载方式 : 运行 setup\remove_startup.bat
echo.
pause
exit /b 0

:fail
echo.
pause
exit /b 1
