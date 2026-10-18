@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem flash_80w.bat - flash the signed OEM 80W vBIOS (HP 210618)
rem
rem Safety: a full backup of the current vBIOS is written to backups\ before
rem any write. If the backup fails the flash is aborted.
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0lib\common.bat"
call "%LIB%" init

set "ROM=%ROMS%\HP.RTX3050TiMobile.4096.210618.rom"
set "CLOG=%LOGS%\flash_80w.log"

call "%LIB%" require_admin "%~f0"
if errorlevel 1 exit /b
call "%LIB%" is_admin
call "%LIB%" probe
call "%LIB%" title M0120

rem ---- adaptive gate: OS / arch / tool / GPU ----
call "%~dp0preflight.bat" --quiet
set "PRC=%ERRORLEVEL%"
if "%PRC%"=="1" (
    echo.
    call "%LIB%" err M0121
    echo.
    pause
    exit /b 1
)
if "%PRC%"=="2" (
    call "%LIB%" warn M0122
)

if not exist "%TOOLS%\nvflashb.exe" (
    call "%LIB%" err M0123
    call "%LIB%" msg M0124
    echo.
    pause
    exit /b 1
)
if not exist "%ROM%" (
    call "%LIB%" err M0125
    call "%LIB%" msg M0126
    echo.
    pause
    exit /b 1
)

if not "%GPU_PRESENT%"=="1" (
    call "%LIB%" err M0127
    echo.
    pause
    exit /b 1
)
if /i not "%GPU_DEV%"=="25A0" (
    call "%LIB%" err M0128
    call "%LIB%" msg M0129
    echo.
    pause
    exit /b 1
)
if /i not "%GPU_STATUS%"=="OK" (
    call "%LIB%" err M0130
    call "%LIB%" msg M0131
    echo.
    pause
    exit /b 1
)
if "%NVIDIA_DRIVER%"=="" (
    call "%LIB%" err M0132
    call "%LIB%" msg M0133
    echo.
    pause
    exit /b 1
)

call "%LIB%" power_csv
call "%LIB%" msg M0134
call "%LIB%" msg M0135
call "%LIB%" msg M0136
call "%LIB%" msg M0137
call "%LIB%" msg M0138
call "%LIB%" msg M0139
echo.

if "%GPU_VRAM_MB%"=="8192" (
    call "%LIB%" msg M0140
    call "%LIB%" msg M0141
    call "%LIB%" msg M0142
    call "%LIB%" msg M0143
    call "%LIB%" msg M0144
    call "%LIB%" msg M0145
    echo   ------------------------------------------
) else if "%GPU_VRAM_MB%"=="4096" (
    call "%LIB%" msg M0146
    call "%LIB%" msg M0147
    call "%LIB%" msg M0148
    call "%LIB%" msg M0149
    echo   ------------------------------------------
) else (
    call "%LIB%" msg M0150
    call "%LIB%" msg M0151
    call "%LIB%" msg M0152
    echo   ------------------------------------------
)
echo.

rem ---- mandatory backup ----
call "%LIB%" msg M0153
call "%LIB%" backup_vbios
if not "%BACKUP_OK%"=="0" (
    call "%LIB%" err M0154
    echo.
    pause
    exit /b 1
)
call "%LIB%" msg M0155

echo.
set "ANS="
call "%LIB%" msgs M0156
set /p ANS=!MSGTXT!
if /i not "!ANS!"=="YES" (
    call "%LIB%" info M0157
    goto :the_end
)

echo.
call "%LIB%" msg M0158
call "%LIB%" msg M0159
call "%LIB%" flash_rom "%ROM%" "%CLOG%"
echo.

if "%FLASH_RC%"=="0" (
    call "%LIB%" ok M0160
    echo.
    call "%LIB%" msg M0161
    call "%LIB%" msg M0162
    call "%LIB%" msg M0163
    call "%LIB%" msg M0164
    call "%LIB%" msg M0165
    echo.
    call "%LIB%" msg M0166
) else (
    call "%LIB%" err M0167
    if not "%FLASH_HINT%"=="" echo   %FLASH_HINT%
    echo.
    call "%LIB%" msg M0168
    call "%LIB%" msg M0169
    call "%LIB%" msg M0170
    call "%LIB%" msg M0171
    echo.
    call "%LIB%" msg M0172
    call "%LIB%" msg M0173
)
call "%LIB%" log "%LOGS%\flash_history.log" "flash_80w rc=%FLASH_RC% state=%FLASH_STATE% backup=!BACKUP_FILE!"

:the_end
echo.
pause
