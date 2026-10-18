@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem bootstrap.bat - load / repair the runtime environment
rem
rem Verifies folder layout, tool and ROM integrity, creates runtime folders and
rem repairs a stale startup task. Missing files are reported with exact steps;
rem nvflash can be re-downloaded when RTX3050TI_NVFLASH_URL is provided.
rem
rem   bootstrap.bat            check and repair
rem   bootstrap.bat --check    report only, change nothing
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0scripts\lib\common.bat"
call "%LIB%" init

set "CHECK_ONLY=0"
if /i "%~1"=="--check" set "CHECK_ONLY=1"

call "%LIB%" title M0001
call "%LIB%" probe

if not "%PROBE_OK%"=="1" (
    call "%LIB%" warn M0002
)

set "ISSUES=0"
set "FIXED=0"

rem ---------------------------------------------------------------- layout
if "%CHECK_ONLY%"=="0" (
    for %%D in ("%LOGS%" "%CONFIG%" "%BACKUPS%") do if not exist "%%~D" mkdir "%%~D" >nul 2>&1
)
call "%LIB%" ok M0003

rem ---------------------------------------------------------------- nvflash
call "%LIB%" find_smi
set "HASH_NVFLASH="
if exist "%TOOLS%\SHA256SUMS.txt" (
    for /f "tokens=1 delims= " %%a in ('findstr /i /c:"nvflashb.exe" "%TOOLS%\SHA256SUMS.txt" 2^>nul') do (
        if not defined HASH_NVFLASH set "HASH_NVFLASH=%%a"
    )
)
set "TOOL_OK=0"
if exist "%TOOLS%\nvflashb.exe" (
    if defined HASH_NVFLASH (
        call "%LIB%" sha256 "%TOOLS%\nvflashb.exe"
        if /i "!HASH!"=="!HASH_NVFLASH!" set "TOOL_OK=1"
    ) else (
        set "TOOL_OK=1"
    )
)
if "%TOOL_OK%"=="1" (
    call "%LIB%" ok M0004
) else (
    set /a ISSUES+=1
    call "%LIB%" warn M0005
    if defined RTX3050TI_NVFLASH_URL (
        if "%CHECK_ONLY%"=="0" (
            call "%LIB%" msg M0006
            if not exist "%TOOLS%" mkdir "%TOOLS%" >nul 2>&1
            powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%RTX3050TI_NVFLASH_URL%' -OutFile '%TOOLS%\nvflashb.exe' -TimeoutSec 120" >nul 2>&1
            if exist "%TOOLS%\nvflashb.exe" (
                call "%LIB%" sha256 "%TOOLS%\nvflashb.exe"
                if defined HASH_NVFLASH if /i "!HASH!"=="!HASH_NVFLASH!" (
                    call "%LIB%" ok M0007
                    set /a FIXED+=1
                    set /a ISSUES-=1
                ) else (
                    call "%LIB%" err M0008
                    del /f /q "%TOOLS%\nvflashb.exe" >nul 2>&1
                )
            ) else (
                call "%LIB%" err M0009
            )
        )
    ) else (
        call "%LIB%" msg M0010
        call "%LIB%" msg M0011
        echo         bootstrap.bat
    )
)

rem ---------------------------------------------------------------- roms
set "ROM60=%ROMS%\RTX3050Ti_Laptop_94.07.3a.00.0e.rom"
set "ROM80=%ROMS%\HP.RTX3050TiMobile.4096.210618.rom"
if exist "%ROM60%" (
    call "%LIB%" ok M0012
) else (
    set /a ISSUES+=1
    call "%LIB%" warn M0013
)
if exist "%ROM80%" (
    call "%LIB%" ok M0014
) else (
    set /a ISSUES+=1
    call "%LIB%" warn M0015
    call "%LIB%" msg M0016
)

rem ---------------------------------------------------------------- profiles
if exist "%CONFIG%\power_profile.txt" (
    set "PP="
    set /p PP=<"%CONFIG%\power_profile.txt"
    call "%LIB%" ok M0017
) else (
    call "%LIB%" info M0018
)

rem ---------------------------------------------------------------- startup task
if "%TASK_EXISTS%"=="1" (
    set "TASK_OK=0"
    echo !TASK_CMD! | findstr /i /c:"%ROOT%" >nul && set "TASK_OK=1"
    if "!TASK_OK!"=="1" (
        call "%LIB%" ok M0019
    ) else (
        set /a ISSUES+=1
        call "%LIB%" warn M0020
        call "%LIB%" msg M0021
    )
) else (
    call "%LIB%" info M0022
)

rem ---------------------------------------------------------------- disk
if %DISK_FREE_MB% LSS 200 (
    set /a ISSUES+=1
    call "%LIB%" warn M0023
) else (
    call "%LIB%" ok M0024
)

echo.
if "%ISSUES%"=="0" (
    call "%LIB%" ok M0025
    call "%LIB%" msg M0026
    set "RC=0"
) else (
    if "%FIXED%"=="0" (
        call "%LIB%" warn M0027
        set "RC=2"
    ) else (
        call "%LIB%" ok M0028
        set "RC=2"
    )
)
call "%LIB%" log "%LOGS%\bootstrap.log" "bootstrap issues=%ISSUES% fixed=%FIXED% rc=%RC%"
echo.
pause
exit /b %RC%
