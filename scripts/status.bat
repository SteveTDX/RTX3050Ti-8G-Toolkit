@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem status.bat - ( ; BIOS )
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0lib\common.bat"
call "%LIB%" init

call "%LIB%" title "当前显卡状态"
call "%LIB%" is_admin
call "%LIB%" find_smi
call "%LIB%" check_gpu
call "%LIB%" power_csv

if not "%GPU_FOUND%"=="0" (
    call "%LIB%" err "未检测到 NVIDIA 显卡 (驱动未加载或设备异常)"
    echo.
    echo   若设备管理器显示 Microsoft 基本显示适配器 或 代码 10,
    echo   请运行 scripts\flash_60w.bat 恢复原厂固件。
    echo.
    pause
    exit /b 1
)

echo   显卡          : !GPU_NAME!
echo   功耗 Default  : !PWR_DEF! W
echo   功耗 Max      : !PWR_MAX! W
echo.
for /f "tokens=1-6 delims=," %%a in ('"%SMI%" --query-gpu=memory.total^,clocks.max.sm^,clocks.max.memory^,temperature.gpu^,utilization.gpu^,driver_version --format=csv^,noheader 2^>nul') do (
    echo   显存总量      : %%a
    echo   核心频率上限  : %%b
    echo   显存频率上限  : %%c
    echo   核心温度      : %%d
    echo   GPU 利用率    : %%e
    echo   驱动版本      : %%f
)

echo.
echo   --- BIOS 版本 ---
if "%ADMIN%"=="1" (
    if exist "%TOOLS%\nvflashb.exe" (
        "%TOOLS%\nvflashb.exe" --version 2>&1 | findstr /i /c:"Version" /c:"ID:"
    ) else (
        echo   未安装 nvflashb.exe, 无法读取
    )
) else (
    echo   需要管理员权限, 请以管理员身份运行本脚本
)
echo.
pause
