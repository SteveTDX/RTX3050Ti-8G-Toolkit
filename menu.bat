@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem menu.bat - ( , )
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0scripts\lib\common.bat"
call "%LIB%" init

:menu
cls
call "%LIB%" title "RTX 3050 Ti Laptop 8GB 魔改 - 功耗管理工具箱"
call "%LIB%" find_smi
call "%LIB%" check_gpu
if "%GPU_FOUND%"=="0" (
    call "%LIB%" power_csv
    echo   当前显卡 : !GPU_NAME!
    echo   当前功耗 : Default !PWR_DEF! W / Max !PWR_MAX! W
) else (
    echo   当前显卡 : 未检测到 NVIDIA 显卡
)
echo.
echo   [1] 环境自检 - 查看驱动/工具/ROM/启动项状态
echo   [2] 查看当前状态 - 显存/功耗/频率/温度/BIOS 版本
echo   [3] 设置功耗上限 - 自选瓦数并保存配置
echo   [4] 刷入 80W vBIOS - 有风险, 详见脚本内提示
echo   [5] 恢复原厂 60W vBIOS - 安全操作
echo   [6] 安装开机启动项 - 开机自动应用功耗配置
echo   [7] 卸载开机启动项
echo   [0] 退出
echo.
set "CH="
set /p CH=请选择:
if "%CH%"=="1" (call "%ROOT%\scripts\env_check.bat" & goto :menu)
if "%CH%"=="2" (call "%ROOT%\scripts\status.bat" & goto :menu)
if "%CH%"=="3" (call "%ROOT%\scripts\set_powerlimit.bat" & goto :menu)
if "%CH%"=="4" (call "%ROOT%\scripts\flash_80w.bat" & goto :menu)
if "%CH%"=="5" (call "%ROOT%\scripts\flash_60w.bat" & goto :menu)
if "%CH%"=="6" (call "%ROOT%\setup\install_startup.bat" & goto :menu)
if "%CH%"=="7" (call "%ROOT%\setup\remove_startup.bat" & goto :menu)
if "%CH%"=="0" goto :bye
goto :menu

:bye
echo.
echo   已退出。
exit /b 0
