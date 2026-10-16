@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem env_check.bat - ( )
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0lib\common.bat"
call "%LIB%" init

call "%LIB%" title "RTX3050Ti-8G-Toolkit 环境自检"
call "%LIB%" is_admin
call "%LIB%" find_smi
call "%LIB%" check_gpu

echo   系统          : Windows 位于 %SystemDrive%
if "%ADMIN%"=="1" (echo   管理员权限    : 是) else (echo   管理员权限    : 否 - 仅查看无需提权)
echo   nvidia-smi    : %SMI%
echo.
if "%GPU_FOUND%"=="0" (
    call "%LIB%" ok "检测到显卡    : !GPU_NAME!"
    call "%LIB%" check_model
    if "!MODEL_OK!"=="0" (
        call "%LIB%" ok "型号匹配      : RTX 3050 Ti Laptop, 适用本工具"
    ) else (
        call "%LIB%" warn "型号不匹配    : !GPU_NAME! - 本工具仅支持 RTX 3050 Ti Laptop"
    )
    call "%LIB%" power_csv
    echo   功耗 Default  : !PWR_DEF! W
    echo   功耗 Max      : !PWR_MAX! W
) else (
    call "%LIB%" err "未检测到 NVIDIA 显卡, 或驱动未加载"
    echo   若设备管理器显示"Microsoft 基本显示适配器"或代码 10,
    echo   请运行 scripts\flash_60w.bat 恢复原厂固件。
)

echo.
echo   --- 文件完整性 ---
call "%LIB%" check_files "%TOOLS%\nvflashb.exe" "" "刷写工具"
if errorlevel 1 (echo   [X] 刷写工具缺失, 刷写功能不可用) else (call "%LIB%" ok "刷写工具      : tools\nvflashb.exe")
call "%LIB%" check_files "%ROMS%\RTX3050Ti_Laptop_94.07.3a.00.0e.rom" "999424" "原厂 ROM"
if errorlevel 1 (echo   [X] 原厂 ROM 缺失, 无法恢复默认配置) else (call "%LIB%" ok "原厂 60W ROM  : 存在且大小正常")
call "%LIB%" check_files "%ROMS%\HP.RTX3050TiMobile.4096.210618.rom" "999424" "80W ROM"
if errorlevel 1 (echo   [!] 80W ROM 缺失, 80W 刷写功能不可用) else (call "%LIB%" ok "80W ROM       : 存在且大小正常")

echo.
echo   --- 开机启动项 ---
schtasks /query /tn "RTX3050Ti8G-PowerProfile" >nul 2>&1
if errorlevel 1 (
    echo   状态          : 未安装 - 运行 setup\install_startup.bat 可安装
) else (
    echo   状态          : 已安装 - 计划任务 RTX3050Ti8G-PowerProfile
)
if exist "%CONFIG%\power_profile.txt" (
    set /p PP=<"%CONFIG%\power_profile.txt"
    echo   功耗配置      : !PP! W
) else (
    echo   功耗配置      : 未设置 - 默认沿用固件值
)

echo.
echo   自检完成。
echo.
pause
