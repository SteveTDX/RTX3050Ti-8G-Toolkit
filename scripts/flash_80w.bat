@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem flash_80w.bat - 80W vBIOS (HP 210618 )
rem : 4GB SKU 8GB
rem " / ( 10)" flash_60w.bat
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0lib\common.bat"
call "%LIB%" init

set "ROM=%ROMS%\HP.RTX3050TiMobile.4096.210618.rom"
set "LOG=%LOGS%\flash_80w.log"

call "%LIB%" require_admin "%~f0" %*
if errorlevel 1 exit /b
call "%LIB%" is_admin
call "%LIB%" find_smi
call "%LIB%" check_gpu

call "%LIB%" title "刷入 80W vBIOS"
call "%LIB%" check_files "%TOOLS%\nvflashb.exe" "" "刷写工具"
if errorlevel 1 (pause & exit /b 1)
call "%LIB%" check_files "%ROM%" "999424" "80W ROM"
if errorlevel 1 (pause & exit /b 1)

if not "%GPU_FOUND%"=="0" (
    call "%LIB%" err "未检测到 NVIDIA 显卡, 无法刷写"
    echo   若设备处于代码 10 状态, 请先在设备管理器中禁用或卸载该显示设备。
    echo.
    pause
    exit /b 1
)
call "%LIB%" check_model
if not "%MODEL_OK%"=="0" (
    call "%LIB%" err "显卡型号不匹配: !GPU_NAME! - 仅支持 RTX 3050 Ti Laptop, 已中止"
    echo.
    pause
    exit /b 1
)

call "%LIB%" power_csv
echo   当前显卡      : !GPU_NAME!
echo   当前功耗      : Default !PWR_DEF! W / Max !PWR_MAX! W
echo   目标固件      : HP.RTX3050TiMobile.4096.210618 - 94.07.3B.40.6D
echo   目标功耗      : Default 80 W / Max 95 W
echo.
echo   ---------------- 风险提示 ----------------
echo   1. 本 ROM 来自 4GB SKU 官方机型, 功耗参数 80W/95W
echo   2. 对 8GB 魔改显卡, 可能出现刷入后冷启动无法初始化独显
echo      表现为设备管理器代码 10, 只能用 flash_60w.bat 恢复
echo   3. 笔记本散热按原厂 60W 设计, 80W 长时间满载可能高温降频
echo   4. 刷写过程中请勿断电关机或运行占用显卡的程序
echo   ------------------------------------------
echo.
set "ANS="
set /p ANS=确认继续刷写请输入 YES 回车, 其他任意键取消:
if /i not "%ANS%"=="YES" (
    call "%LIB%" info "已取消, 未做任何修改"
    goto :the_end
)

echo.
echo   [1/2] 解除 EEPROM 写保护...
"%TOOLS%\nvflashb.exe" --protectoff >>"%LOG%" 2>&1
echo   [2/2] 写入固件, 请勿中断...
"%TOOLS%\nvflashb.exe" --log="%LOG%" -6 "%ROM%"
set "RC=%ERRORLEVEL%"
echo.
if "%RC%"=="0" (
    call "%LIB%" ok "刷写成功"
    echo.
    echo   重要: 必须重启后才生效, 且必须做一次冷启动验证
    echo   重启后请运行 scripts\status.bat 确认独显正常工作
    echo   若独显异常或设备代码 10, 请再次运行 scripts\flash_60w.bat 恢复
) else (
    call "%LIB%" err "刷写失败, 退出码 %RC%, 固件未被修改"
    echo   详细日志: %LOG%
)
call "%LIB%" log "%LOG%" "flash_80w exit=%RC%"

:the_end
echo.
pause
