@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem flash_60w.bat - 60W vBIOS ( , )
rem : 80W ,
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0lib\common.bat"
call "%LIB%" init

set "ROM=%ROMS%\RTX3050Ti_Laptop_94.07.3a.00.0e.rom"
set "LOG=%LOGS%\flash_60w.log"

call "%LIB%" require_admin "%~f0" %*
if errorlevel 1 exit /b
call "%LIB%" is_admin
call "%LIB%" find_smi
call "%LIB%" check_gpu

call "%LIB%" title "恢复原厂 60W vBIOS"
call "%LIB%" check_files "%TOOLS%\nvflashb.exe" "" "刷写工具"
if errorlevel 1 (pause & exit /b 1)
call "%LIB%" check_files "%ROM%" "999424" "原厂 ROM"
if errorlevel 1 (pause & exit /b 1)

echo   目标固件      : RTX3050Ti_Laptop_94.07.3a.00.0e - 本机原厂备份
echo   目标功耗      : Default 60 W
echo   说明          : 官方签名固件, 不涉及签名风险, 任何状态下均可执行
echo.
set "ANS="
set /p ANS=确认执行请直接回车, 输入其他内容取消:
if not "%ANS%"=="" (
    call "%LIB%" info "已取消"
    goto :the_end
)

echo.
echo   [1/2] 解除 EEPROM 写保护...
"%TOOLS%\nvflashb.exe" --protectoff >>"%LOG%" 2>&1
echo   [2/2] 写入原厂固件, 请勿中断...
"%TOOLS%\nvflashb.exe" --log="%LOG%" -6 "%ROM%"
set "RC=%ERRORLEVEL%"
echo.
if "%RC%"=="0" (
    call "%LIB%" ok "恢复成功"
    echo   请重启, 然后运行 scripts\status.bat 确认
    echo   若独显仍异常, 说明并非固件问题, 请检查设备管理器错误代码
) else (
    call "%LIB%" err "写入失败, 退出码 %RC%"
    echo   若设备处于代码 10 状态 nvflash 可能找不到设备, 处理方法:
    echo     1. 设备管理器 - 显示适配器 - 右键 Microsoft 基本显示适配器
    echo     2. 选择 卸载设备, 不要勾选 删除驱动程序软件
    echo     3. 重新运行本脚本
    echo   详细日志: %LOG%
)
call "%LIB%" log "%LOG%" "flash_60w exit=%RC%"

:the_end
echo.
pause
