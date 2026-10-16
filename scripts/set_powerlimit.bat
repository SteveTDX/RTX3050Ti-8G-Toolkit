@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem set_powerlimit.bat - (Default Power Limit)
rem :
rem set_powerlimit.bat
rem set_powerlimit.bat 70
rem config\power_profile.txt,
rem setup\install_startup.bat
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0lib\common.bat"
call "%LIB%" init

call "%LIB%" require_admin "%~f0" %*
if errorlevel 1 exit /b
call "%LIB%" is_admin
call "%LIB%" find_smi
call "%LIB%" check_gpu
call "%LIB%" power_csv

call "%LIB%" title "设置功耗上限"
if not "%GPU_FOUND%"=="0" (
    call "%LIB%" err "未检测到 NVIDIA 显卡"
    echo.
    pause
    exit /b 1
)
if not defined PWR_MAX (
    call "%LIB%" err "无法读取当前功耗范围, 请确认驱动正常"
    echo.
    pause
    exit /b 1
)

echo   显卡          : !GPU_NAME!
echo   当前 Default  : !PWR_DEF! W
echo   固件允许上限  : !PWR_MAX! W
echo.
set "TARGET=%~1"
if not defined TARGET (
    set /p TARGET=请输入目标功耗 1-!PWR_MAX! W 直接回车保持当前值 :
)
if not defined TARGET set "TARGET=%PWR_DEF!"

rem ---- inline numeric validation (cross-file call is unreliable, so validate here) ----
set "TARGET=%TARGET:W%"
set "TARGET=%TARGET: =%"
set "NONNUM="
for /f "delims=0123456789" %%a in ("%TARGET%") do set "NONNUM=%%a"
if "%TARGET%"=="" (
    call "%LIB%" err "未输入功耗值, 已取消"
    goto :fail
)
if defined NONNUM (
    call "%LIB%" err "输入无效: %TARGET% - 需要 1 到 !PWR_MAX! 之间的整数"
    goto :fail
)

if !TARGET! lss 1 (
    call "%LIB%" err "目标功耗必须不低于 1 W"
    goto :fail
)
if !TARGET! gtr !PWR_MAX! (
    call "%LIB%" err "目标功耗 !TARGET! W 超过固件允许上限 !PWR_MAX! W"
    echo   当前固件把功耗墙锁定在 !PWR_MAX! W, 若需更高只能更换 vBIOS。
    goto :fail
)

echo.
echo   正在应用: !TARGET! W ...
"%SMI%" -pl !TARGET! 2>&1
if errorlevel 1 (
    echo.
    call "%LIB%" err "设置失败。若提示 Insufficient Permissions 请以管理员身份运行"
    goto :fail
)

if not exist "%CONFIG%" mkdir "%CONFIG%" >nul 2>&1
> "%CONFIG%\power_profile.txt" echo !TARGET!
call "%LIB%" log "%LOGS%\set_power.log" "power limit set to !TARGET! W"

call "%LIB%" power_csv
if "!PWR_DEF!"=="!TARGET!" (
    call "%LIB%" ok "功耗上限已设置为 !TARGET! W"
) else (
    call "%LIB%" warn "已提交 !TARGET! W, 但回读值为 !PWR_DEF! W"
    echo   常见原因: 笔记本 EC 不允许调整, 或需要管理员权限, 或该机型不支持运行时调功耗
    echo   此时可改用 flash_80w.bat / flash_60w.bat 通过固件调整功耗
)
echo   当前 Default  : !PWR_DEF! W
echo   配置已保存  : config\power_profile.txt
echo   可运行 setup\install_startup.bat 使其在每次开机时自动应用。
goto :the_end

:fail
echo.
pause
exit /b 1

:the_end
echo.
pause
